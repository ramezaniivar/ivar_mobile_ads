import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:animate_do/animate_do.dart' show Pulse;
import 'package:flutter/material.dart';
import 'package:ivar_mobile_ads/src/entity/interstitial_entity.dart';
import 'package:ivar_mobile_ads/src/repository.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ivar_mobile_ads.dart';

bool _isRTL(String text) {
  if (text.trim().isEmpty) return false;

  // گرفتن اولین کاراکتر واقعی (غیر فاصله)
  final firstChar = text.trim().characters.first;

  // گرفتن کد یونیکد
  final code = firstChar.codeUnitAt(0);

  // بررسی محدوده‌های زبان‌های RTL (عربی، فارسی، عبری)
  // عربی و فارسی: U+0600 تا U+06FF
  // عبری: U+0590 تا U+05FF
  return (code >= 0x0590 && code <= 0x08FF);
}

class IvarInterstitialAdWidget extends StatefulWidget {
  const IvarInterstitialAdWidget(this.ad,
      {super.key, this.fullScreenContentCallback});
  final InterstitialEntity ad;
  final IvarFullScreenContentCallback? fullScreenContentCallback;

  @override
  State<IvarInterstitialAdWidget> createState() =>
      _IvarInterstitialAdWidgetState();
}

class _IvarInterstitialAdWidgetState extends State<IvarInterstitialAdWidget> {
  late int showCloseTime;

  @override
  void initState() {
    showCloseTime = widget.ad.displayTime;

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.fullScreenContentCallback?.onAdShowedFullScreenContent();
      _init();
    });
  }

  void _init() {
    if (showCloseTime == 0) {
      widget.fullScreenContentCallback?.onAdCompleted();
      return;
    }

    Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        setState(() {
          showCloseTime -= 1;
        });
        if (showCloseTime == 0) {
          widget.fullScreenContentCallback?.onAdCompleted();
          timer.cancel();
        }
      },
    );
  }

  void onTap() async {
    widget.fullScreenContentCallback?.onAdClicked();

    var link = widget.ad.link;
    final adID = widget.ad.id;

    // log click
    Repository.instance.clickInterstitial(adID);

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

        //close ad
        if (context.mounted) Navigator.pop(context);
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

          //close ad
          if (context.mounted) Navigator.pop(context);
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

    //close ad
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: showCloseTime == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.fullScreenContentCallback?.onAdDismissedFullScreenContent();
        }
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: SafeArea(
              child: Stack(
            children: [
              Positioned.fill(
                child: switch (widget.ad) {
                  ImageInterstitialEntity() => _ImageAd(
                      widget.ad as ImageInterstitialEntity,
                      onTap: onTap),
                  UnsupportedInterstitialEntity() => SizedBox(),
                },
              ),
              Positioned(
                left: 20,
                top: 20,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
                  child: InkWell(
                    onTap: showCloseTime == 0
                        ? () => Navigator.pop(context)
                        : null,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 30,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.5),
                        color: Colors.white60,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        child: showCloseTime == 0
                            ? Row(
                                spacing: 2,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Close',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 29, 29, 36),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Color.fromARGB(255, 29, 29, 36),
                                  ),
                                ],
                              )
                            : Text(
                                showCloseTime.toString(),
                                style: TextStyle(
                                  color: Color.fromARGB(255, 29, 29, 36),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
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
                  )),
            ],
          )),
        ),
      ),
    );
  }
}

class _ImageAd extends StatelessWidget {
  const _ImageAd(this.ad, {required this.onTap});
  final ImageInterstitialEntity ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: ad.ctaText == null ? onTap : null,
                child: Image.file(
                  File(ad.media),
                  fit: BoxFit.cover,
                )),
          ),
        ),

        //cta button
        if (ad.ctaText != null)
          Positioned(
            bottom: 65,
            right: 55,
            left: 55,
            child: _AnimatedButton(ad.ctaText!, onTap: onTap),
          ),
      ],
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton(this.text, {this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  State<_AnimatedButton> createState() => __AnimatedButtonState();
}

class __AnimatedButtonState extends State<_AnimatedButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pulse(
        infinite: true,
        duration: const Duration(milliseconds: 1000),
        child: Directionality(
          textDirection:
              _isRTL(widget.text) ? TextDirection.rtl : TextDirection.ltr,
          child: ElevatedButton(
            onPressed: widget.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                package: 'ivar_mobile_ads',
                fontFamily: _isRTL(widget.text) ? 'Vazir' : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ButtonStyle get _elevatedButtonStyle {
//   return ElevatedButton.styleFrom(
//     padding: EdgeInsets.symmetric(
//       horizontal: 10,
//       vertical: 10,
//     ),
//     backgroundColor: Colors.teal,
//     shadowColor: Colors.white10,
//     overlayColor: Colors.white10,
//     disabledBackgroundColor: Colors.teal.withAlpha(180),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(7),
//     ),
//   );
// }
