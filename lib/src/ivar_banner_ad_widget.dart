import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/entity/banner_entity.dart';
import 'package:ivar_mobile_ads/src/repository.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ivar_banner_ad.dart';

class IvarBannerAdWidget extends StatefulWidget {
  IvarBannerAdWidget(this.bannerAd, {super.key});
  IvarBannerAd bannerAd;

  @override
  State<IvarBannerAdWidget> createState() => _IvarBannerAdWidgetState();
}

class _IvarBannerAdWidgetState extends State<IvarBannerAdWidget>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _visibilityCheckTimer;
  bool _isVisible = true;
  bool _isInForeground = true;
  bool showAd = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ثبت بازدید اولیه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVisibilityCheck();
      _logBannerView();
      _startTimer();
      widget.bannerAd.listener.onAdImpression?.call();
    });
  }

  void _startVisibilityCheck() {
    _visibilityCheckTimer =
        Timer.periodic(Duration(milliseconds: 500), (timer) {
      final route = ModalRoute.of(context);
      final isCurrentlyVisible = route?.isCurrent ?? false;

      if (_isVisible != isCurrentlyVisible) {
        _isVisible = isCurrentlyVisible;

        if (_isVisible && _isInForeground) {
          _startTimer();
          _logBannerView();
        } else {
          _timer?.cancel();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        _startTimer();
        break;
      case AppLifecycleState.paused:
        _isInForeground = false;
        _timer?.cancel();
        break;
      default:
        break;
    }
  }

  void _logBannerView() {
    if (_isVisible && _isInForeground) {
      final ad = widget.bannerAd.ad;
      // اینجا متد ثبت بازدید را صدا بزنید
      Repository.instance.viewBanner(ad.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _visibilityCheckTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      Duration(seconds: 1),
      (timer) async {
        if (isLoading) return;
        if (!_isVisible) return;

        isLoading = true;
        final result = await Repository.instance
            .refreshBanner(widget.bannerAd.ad.id, widget.bannerAd.size);

        if (!mounted) return;
        isLoading = false;

        // اگه تبلیغ جدید دریافت شد
        if (result.$2 != null) {
          if (mounted) {
            setState(() {
              widget.bannerAd = result.$2!;
            });
          }

          timer.cancel();
          if (mounted) _startTimer();
        }

        // اگه تبلیغات تموم شده بود
        if (result.$1 == 0 && result.$2 == null) {
          timer.cancel();
          if (mounted) {
            setState(() {
              showAd = false;
            });
          }
        }
      },
    );
  }

  void _bannerOnTap() async {
    final adID = widget.bannerAd.ad.id;
    var link = widget.bannerAd.ad.link;

    // log click
    Repository.instance.clickBanner(adID);
    widget.bannerAd.listener.onAdClicked?.call();

    /// check is cafe bazaar link
    if (link.contains('https://cafebazaar.ir/app/') && Platform.isAndroid) {
      try {
        final packageName = link.split('/').last;

        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'bazaar://details/modal?id=$packageName',
          package: 'com.farsitel.bazaar',
        );

        await intent.launch();

        return;
      } catch (err) {
        log('error $err');
      }
    }

    ///check is myket link for auto download intent
    // https://myket.ir/app/com.example.app/auto-dl
    if (link.contains('https://myket.ir/app/') &&
        link.split('/').last == 'auto-dl') {
      ///remove "/audo-dl" from link
      link = link.replaceFirst('/auto-dl', '');

      if (Platform.isAndroid) {
        try {
          //get package name from link
          final packageName = link.split('/').last;

          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'myket://download/$packageName',
            package: 'ir.mservices.market',
          );

          await intent.launch();

          return;
        } catch (err) {
          log('error $err');
        }
      }
    }

    try {
      if (!await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication)) {
        log("There was a problem opening the link");
      }
    } catch (err) {
      log('The link is invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.bannerAd.ad;

    if (!showAd) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height =
            width * (widget.bannerAd.size.height / widget.bannerAd.size.width);

        return SizedBox(
          width: width,
          height: height,
          child: switch (banner) {
            TextualBannerEntity() => _TextualBanner(
                banner,
                widget.bannerAd.size,
                height,
                onTap: _bannerOnTap,
              ),
            ImageBannerEntity() => _ImageBanner(
                banner,
                onTap: _bannerOnTap,
              ),
          },
        );
      },
    );
  }
}

class _TextualBanner extends StatelessWidget {
  const _TextualBanner(this.banner, this.size, this.bannerHeight,
      {required this.onTap});
  final TextualBannerEntity banner;
  final BannerAdSize size;
  final double bannerHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (size) {
      BannerAdSize.standard => _StandardTextualBanner(
          banner,
          bannerHeight,
          onTap: onTap,
        ),
      BannerAdSize.large => _LargeTextualBanner(
          banner,
          bannerHeight,
          onTap: onTap,
        ),
      BannerAdSize.mediumRectangle => _MediumRectangleBanner(
          banner,
          bannerHeight,
          onTap: onTap,
        ),
    };
  }
}

const List<String> _rtlLanguages = [
  'ar', // Arabic
  'fa', // Persian (Farsi)
  'he', // Hebrew
  'ur', // Urdu
  'sd', // Sindhi
  'ug', // Uyghur
  'dv', // Dhivehi (Maldivian)
  'ps', // Pashto
];

class _StandardTextualBanner extends StatelessWidget {
  const _StandardTextualBanner(this.banner, this.bannerHeight,
      {required this.onTap});
  final TextualBannerEntity banner;
  final double bannerHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasButton =
        banner.callToAction != null && banner.callToAction!.isNotEmpty;
    final isRtl = _rtlLanguages.contains(banner.language ?? 'fa');
    final font = isRtl ? 'Vazir' : null;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: hasButton ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Color(0xffe2e2e2),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (banner.icon != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(
                    File(banner.icon!),
                    width: bannerHeight * 0.75,
                    height: bannerHeight * 0.75,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        _adBadge(),
                        Expanded(
                          child: Text(
                            banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: bannerHeight * 0.22,
                                color: Constants.textColor,
                                fontFamily: font,
                                package: 'ivar_mobile_ads',
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      banner.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: bannerHeight * 0.19,
                        color: Constants.textColor.withAlpha(180),
                        fontFamily: font,
                        package: 'ivar_mobile_ads',
                      ),
                    )
                  ],
                ),
              ),
              if (hasButton)
                ElevatedButton(
                  onPressed: onTap,
                  style: _elevatedButtonStyle,
                  child: Text(
                    banner.callToAction ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: font,
                      package: 'ivar_mobile_ads',
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeTextualBanner extends StatelessWidget {
  const _LargeTextualBanner(this.banner, this.bannerHeight,
      {required this.onTap});
  final TextualBannerEntity banner;
  final double bannerHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasButton =
        banner.callToAction != null && banner.callToAction!.isNotEmpty;
    final isRtl = _rtlLanguages.contains(banner.language ?? 'fa');
    final font = isRtl ? 'Vazir' : null;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: hasButton ? null : onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Color(0xffe2e2e2),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //image icon
                    if (banner.icon != null)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(bannerHeight * 0.08),
                        child: Image.file(
                          File(banner.icon!),
                          width: bannerHeight * 0.65,
                          height: bannerHeight * 0.65,
                        ),
                      ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 3,
                        children: [
                          Text(
                            banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: bannerHeight * 0.12,
                              color: Constants.textColor,
                              fontFamily: font,
                              package: 'ivar_mobile_ads',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              Expanded(
                                child: Text(
                                  banner.description ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: bannerHeight * 0.11,
                                    color: Constants.textColor.withAlpha(190),
                                    fontFamily: font,
                                    package: 'ivar_mobile_ads',
                                  ),
                                ),
                              ),
                              if (hasButton)
                                ElevatedButton(
                                  onPressed: onTap,
                                  style: _elevatedButtonStyle,
                                  child: Text(
                                    banner.callToAction ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: font,
                                      package: 'ivar_mobile_ads',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 5,
              child: _adBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediumRectangleBanner extends StatelessWidget {
  const _MediumRectangleBanner(this.banner, this.bannerHeight,
      {required this.onTap});
  final TextualBannerEntity banner;
  final double bannerHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasButton =
        banner.callToAction != null && banner.callToAction!.isNotEmpty;
    final isRtl = _rtlLanguages.contains(banner.language ?? 'fa');
    final font = isRtl ? 'Vazir' : null;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: hasButton ? null : onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Color(0xffe2e2e2),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.icon != null)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(bannerHeight * 0.03),
                        child: Image.file(
                          File(banner.icon!),
                          width: bannerHeight * 0.25,
                          height: bannerHeight * 0.25,
                        ),
                      ),
                    SizedBox(height: 7),
                    Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: bannerHeight * 0.05,
                        color: Constants.textColor,
                        fontFamily: font,
                        package: 'ivar_mobile_ads',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      banner.description ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: bannerHeight * 0.04,
                        color: Constants.textColor.withAlpha(180),
                        fontFamily: font,
                        package: 'ivar_mobile_ads',
                      ),
                    ),
                    SizedBox(height: 10),
                    if (hasButton)
                      ElevatedButton(
                        onPressed: onTap,
                        style: _elevatedButtonStyle,
                        child: Text(
                          banner.callToAction ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: font,
                            package: 'ivar_mobile_ads',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 5,
              child: _adBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBanner extends StatelessWidget {
  const _ImageBanner(this.banner, {required this.onTap});
  final ImageBannerEntity banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xffe2e2e2), width: 1.5),
          image: DecorationImage(
            image: FileImage(File(banner.image)),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

Widget _adBadge() {
  return Container(
    padding: EdgeInsets.symmetric(
      // vertical: 1,
      horizontal: 2,
    ),
    decoration: BoxDecoration(
      color: Colors.amber.shade700.withAlpha(30),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Text(
      'AD',
      style: TextStyle(
        color: Colors.amber.shade700,
        fontWeight: FontWeight.w500,
        fontSize: 10,
      ),
    ),
  );
}

ButtonStyle get _elevatedButtonStyle {
  return ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 0,
    ),
    backgroundColor: Colors.teal,
    shadowColor: Colors.white10,
    overlayColor: Colors.white10,
    disabledBackgroundColor: Colors.teal.withAlpha(180),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
    ),
  );
}
