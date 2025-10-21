import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/core/custom_close_button.dart';
import 'package:ivar_mobile_ads/src/entity/interstitial_entity.dart';

import '../ivar_mobile_ads.dart';
import 'core/ad_badge.dart';
import 'core/custom_animated_button.dart';

class IvarInterstitialImageAdWidget extends StatefulWidget {
  const IvarInterstitialImageAdWidget(this.ad,
      {super.key, this.fullScreenContentCallback});
  final ImageInterstitialEntity ad;
  final IvarFullScreenContentCallback? fullScreenContentCallback;

  @override
  State<IvarInterstitialImageAdWidget> createState() =>
      _IvarInterstitialImageAdWidgetState();
}

class _IvarInterstitialImageAdWidgetState
    extends State<IvarInterstitialImageAdWidget> {
  late int showCloseTime;
  Timer? timer;

  @override
  void initState() {
    showCloseTime = widget.ad.displayTime;

    super.initState();

    // وقتی وارد صفحه می‌شویم، فقط حالت عمودی فعال شود
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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

    timer?.cancel();
    timer = Timer.periodic(
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

  @override
  void dispose() {
    timer?.cancel();
    timer = null;

    // وقتی از صفحه خارج شدیم، جهت را به حالت عادی (مثلاً همه جهت‌ها) برگردانیم
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  void onTap() async {
    widget.fullScreenContentCallback?.onAdClicked();

    var link = widget.ad.link;
    final adID = widget.ad.id;

    Constants.interstitialCallAction(
      context,
      adId: adID,
      link: link,
    );
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
          backgroundColor: widget.ad.bgColor,
          body: SafeArea(
              child: Stack(
            children: [
              Positioned.fill(
                child: _ImageAd(
                  widget.ad,
                  onTap: onTap,
                ),
              ),

              //close button
              Positioned(
                left: 20,
                top: 20,
                child: CustomCloseButton(
                  maxTime: widget.ad.displayTime,
                  currentTime: showCloseTime,
                  onTap: () => Navigator.pop(context),
                  isRtl: widget.ad.ctaText == null
                      ? null
                      : Constants.isRTL(widget.ad.ctaText!),
                ),
              ),

              //ad badge
              Positioned(bottom: 0, right: 0, child: AdBadge()),
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
                  fit: ad.imgBoxFit,
                )),
          ),
        ),

        //cta button
        if (ad.ctaText != null)
          Positioned(
            bottom: 50,
            // width: 100,
            right: 55,
            left: 55,
            child: CustomAnimatedButton(
              ad.ctaText!,
              onTap: onTap,
              bgColor: ad.ctaBGColor,
              textColor: ad.ctaTextColor,
            ),
          ),
      ],
    );
  }
}
