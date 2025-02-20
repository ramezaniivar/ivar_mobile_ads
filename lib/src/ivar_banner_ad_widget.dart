import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/entity/banner_entity.dart';
import 'package:ivar_mobile_ads/src/repository.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ivar_banner_ad.dart';

class IvarBannerAdWidget extends StatefulWidget {
  const IvarBannerAdWidget(this.bannerAd,
      {this.refresh = const Duration(seconds: 8), super.key});
  final IvarBannerAd bannerAd;
  final Duration refresh;

  @override
  State<IvarBannerAdWidget> createState() => _IvarBannerAdWidgetState();
}

class _IvarBannerAdWidgetState extends State<IvarBannerAdWidget> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    _pageController = PageController();

    if (widget.bannerAd.ads.length > 1) {
      _timer = Timer.periodic(
        widget.refresh,
        (timer) {
          if (_pageController.page?.toInt() == widget.bannerAd.ads.length - 1) {
            _pageController.jumpToPage(0);
          } else {
            _pageController.nextPage(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeIn,
            );
          }
        },
      );
    }

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height =
            width * (widget.bannerAd.size.height / widget.bannerAd.size.width);

        return SizedBox(
          width: width,
          height: height,
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              widget.bannerAd.ads.length,
              (index) {
                final banner = widget.bannerAd.ads[index];

                return switch (banner) {
                  TextualBannerEntity() =>
                    _TextualBanner(banner, widget.bannerAd.size, height),
                  ImageBannerEntity() => _ImageBanner(banner),
                };
              },
            ),
          ),
        );
      },
    );
  }
}

class _TextualBanner extends StatelessWidget {
  const _TextualBanner(this.banner, this.size, this.bannerHeight);
  final TextualBannerEntity banner;
  final BannerAdSize size;
  final double bannerHeight;

  @override
  Widget build(BuildContext context) {
    return switch (size) {
      BannerAdSize.standard => _StandardTextualBanner(banner, bannerHeight),
      BannerAdSize.large => _LargeTextualBanner(banner, bannerHeight),
      BannerAdSize.mediumRectangle => _MediumRectangleBanner(banner),
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
  const _StandardTextualBanner(this.banner, this.bannerHeight);
  final TextualBannerEntity banner;
  final double bannerHeight;

  @override
  Widget build(BuildContext context) {
    final hasButton =
        banner.callToAction != null && banner.callToAction!.isNotEmpty;
    final isRtl = _rtlLanguages.contains(banner.language ?? 'fa');
    final font = isRtl ? 'Vazir' : null;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: hasButton ? null : () => _bannerOnTap(banner.id, banner.link),
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
          child: Row(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (banner.icon != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: '${Constants.baseUrl}/${banner.icon}',
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
                                fontSize: bannerHeight * 0.23,
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
                        fontSize: bannerHeight * 0.2,
                        color: Constants.textColor.withAlpha(180),
                        fontFamily: font,
                        package: 'ivar_mobile_ads',
                      ),
                    )
                  ],
                ),
              ),
              if (hasButton)
                ElevatedButton.icon(
                  onPressed: () => _bannerOnTap(banner.id, banner.link),
                  style: _elevatedButtonStyle,
                  label: Text(
                    banner.callToAction ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: font,
                      package: 'ivar_mobile_ads',
                    ),
                  ),
                  icon: banner.platform == AdPlatform.none
                      ? null
                      : Icon(
                          banner.platform.icon,
                          size: 14,
                          color: Colors.white,
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
  const _LargeTextualBanner(this.banner, this.bannerHeight);
  final TextualBannerEntity banner;
  final double bannerHeight;

  @override
  Widget build(BuildContext context) {
    final hasButton =
        banner.callToAction != null && banner.callToAction!.isNotEmpty;
    final isRtl = _rtlLanguages.contains(banner.language ?? 'fa');
    final font = isRtl ? 'Vazir' : null;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: hasButton ? null : () => _bannerOnTap(banner.id, banner.link),
        child: Stack(
          children: [
            Container(
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
                      borderRadius: BorderRadius.circular(bannerHeight * 0.08),
                      child: CachedNetworkImage(
                        imageUrl: '${Constants.baseUrl}/${banner.icon}',
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
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _bannerOnTap(banner.id, banner.link),
                                style: _elevatedButtonStyle,
                                label: Text(
                                  banner.callToAction ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: font,
                                    package: 'ivar_mobile_ads',
                                  ),
                                ),
                                icon: banner.platform == AdPlatform.none
                                    ? null
                                    : Icon(
                                        banner.platform.icon,
                                        size: 14,
                                        color: Colors.white,
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
  const _MediumRectangleBanner(this.banner);
  final TextualBannerEntity banner;

  @override
  Widget build(BuildContext context) {
    final hasButton =
        banner.callToAction != null && banner.callToAction!.isNotEmpty;
    final isRtl = _rtlLanguages.contains(banner.language ?? 'fa');
    final font = isRtl ? 'Vazir' : null;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: hasButton ? null : () => _bannerOnTap(banner.id, banner.link),
        child: Stack(
          children: [
            Container(
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
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: '${Constants.baseUrl}/${banner.icon}',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  SizedBox(height: 7),
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Constants.textColor,
                      fontFamily: font,
                      package: 'ivar_mobile_ads',
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    banner.description ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: Constants.textColor.withAlpha(180),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (hasButton)
                    ElevatedButton.icon(
                      onPressed: () => _bannerOnTap(banner.id, banner.link),
                      style: _elevatedButtonStyle,
                      label: Text(
                        banner.callToAction ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: font,
                          package: 'ivar_mobile_ads',
                        ),
                      ),
                      icon: banner.platform == AdPlatform.none
                          ? null
                          : Icon(
                              banner.platform.icon,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                ],
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
  const _ImageBanner(this.banner);
  final ImageBannerEntity banner;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _bannerOnTap(banner.id, banner.link),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xffe2e2e2), width: 1.5),
          image: DecorationImage(
            image: CachedNetworkImageProvider(
                '${Constants.baseUrl}/${banner.image}'),
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
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

ButtonStyle get _elevatedButtonStyle {
  return ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(
      horizontal: 5,
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

void _bannerOnTap(String adID, String link) async {
  try {
    Repository.instance.clickBanner(adID);
    if (!await launchUrl(Uri.parse(link),
        mode: LaunchMode.externalApplication)) {
      log("There was a problem opening the link");
      // if (context.mounted) {
      // }
    }
  } catch (err) {
    log('The link is invalid');
    // if (context.mounted) {
    // }
  }
}
