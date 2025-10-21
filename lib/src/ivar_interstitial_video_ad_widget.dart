import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivar_mobile_ads/src/core/ad_badge.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/core/custom_animated_button.dart';
import 'package:ivar_mobile_ads/src/entity/interstitial_entity.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../ivar_mobile_ads.dart';
import 'core/custom_close_button.dart';

class IvarInterstitialVideoAdWidget extends StatefulWidget {
  const IvarInterstitialVideoAdWidget(this.ad,
      {super.key, this.fullScreenContentCallback});
  final VideoInterstitialEntity ad;
  final IvarFullScreenContentCallback? fullScreenContentCallback;

  @override
  State<IvarInterstitialVideoAdWidget> createState() =>
      _IvarInterstitialVideoAdWidgetState();
}

class _IvarInterstitialVideoAdWidgetState
    extends State<IvarInterstitialVideoAdWidget> with WidgetsBindingObserver {
  late int showCloseTime;
  Timer? timer;
  // Create a [Player] to control playback.
  Player? player;
  // Create a [VideoController] to handle video output from [Player].
  VideoController? controller;
  bool isVideoStarted = false; // وضعیت شروع ویدیو
  StreamSubscription? _widthSubscription;
  StreamSubscription? _completedSubscription;

  @override
  void initState() {
    showCloseTime = widget.ad.displayTime;

    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // روشن نگه داشتن صفحه
    WakelockPlus.enable();

    player = Player();
    player!.open(Media('${Constants.baseUrl}/${widget.ad.media}'));
    controller = VideoController(player!);

    // وقتی وارد صفحه می‌شویم، فقط حالت عمودی فعال شود
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.fullScreenContentCallback?.onAdShowedFullScreenContent();

      if (showCloseTime == 0) {
        widget.fullScreenContentCallback?.onAdCompleted();
        _startTimer(); // حتی اگر صفر باشه برای consistency
      }

      // گوش دادن به width برای اطمینان از آماده شدن کامل ویدیو
      _widthSubscription = player!.stream.width.listen((width) {
        if (width != null && width > 0 && !isVideoStarted) {
          setState(() {
            isVideoStarted = true;
          });
          // شروع تایمر بعد از آماده شدن ویدیو
          _startTimer();
        }
      });

      _completedSubscription = player!.stream.completed.listen(
        (event) {
          if (!mounted || !event) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => _PosterScreen(
                      widget.ad,
                      fullScreenContentCallback:
                          widget.fullScreenContentCallback,
                    )),
          );
        },
      );
    });
  }

  void _startTimer() {
    if (showCloseTime == 0) return;

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
    _widthSubscription?.cancel();
    _completedSubscription?.cancel();
    timer?.cancel();
    timer = null;
    player
      ?..stop()
      ..dispose();
    player = null;
    controller = null;

    // وقتی از صفحه خارج شدیم، جهت را به حالت عادی (مثلاً همه جهت‌ها) برگردانیم
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // وقتی صفحه بسته شد، اجازه خاموش شدن مجدد صفحه
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // وقتی اپ به background میره (مثل تماس)
      player?.pause();
      timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // اپ برگشت به foreground
      player?.play(); // اگر خواستی ادامه بده
      if (isVideoStarted) {
        _startTimer();
      }
    }
  }

  void onTap() {
    widget.fullScreenContentCallback?.onAdClicked();

    final link = widget.ad.link;
    final adID = widget.ad.id;

    Constants.interstitialCallAction(
      context,
      adId: adID,
      link: link,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtlCtaText = Constants.isRTL(widget.ad.ctaText);

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
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Video(
                      controller: controller!,
                      controls: null,
                    ),
                  ),
                ),

                // لودینگ اندیکیتور
                if (!isVideoStarted)
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        height: 70,
                        width: 70,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  ),

                //close button
                Positioned(
                  left: 20,
                  top: 20,
                  child: CustomCloseButton(
                    maxTime: widget.ad.displayTime,
                    currentTime: showCloseTime,
                    isRtl: isRtlCtaText,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                //cta button
                Positioned(
                  right: 0,
                  bottom: 40,
                  child: Container(
                    height: 60,
                    padding: EdgeInsets.only(
                      right: 14,
                      left: 6,
                      bottom: 5,
                      top: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffe2e2e2).withAlpha(60),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        SizedBox(
                          height: double.infinity,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 8,
                              ),
                              minimumSize:
                                  Size.zero, // حذف محدودیت حداقل ارتفاع پیش‌فرض
                              // tapTargetSize: MaterialTapTargetSize
                              //     .shrinkWrap, // حذف فاصله اضافی
                              backgroundColor: widget.ad.ctaBGColor ??
                                  const Color(0xffeaeaea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Directionality(
                              textDirection: isRtlCtaText
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: Text(
                                widget.ad.ctaText,
                                style: TextStyle(
                                  color: widget.ad.ctaTextColor ?? Colors.black,
                                  fontSize: 15,
                                  fontFamily: isRtlCtaText ? 'Vazir' : null,
                                  package: 'ivar_mobile_ads',
                                ),
                              ),
                            ),
                          ),
                        ),
                        widget.ad.icon != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(
                                  File(widget.ad.icon!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),

                //ad badge
                Positioned(bottom: 0, right: 0, child: AdBadge()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterScreen extends StatefulWidget {
  const _PosterScreen(this.ad, {this.fullScreenContentCallback});
  final VideoInterstitialEntity ad;
  final IvarFullScreenContentCallback? fullScreenContentCallback;

  @override
  State<_PosterScreen> createState() => __PosterScreenState();
}

class __PosterScreenState extends State<_PosterScreen> {
  @override
  void initState() {
    super.initState();

    // روشن نگه داشتن صفحه
    WakelockPlus.enable();

    // وقتی وارد صفحه می‌شویم، فقط حالت عمودی فعال شود
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // وقتی از صفحه خارج شدیم، جهت را به حالت عادی (مثلاً همه جهت‌ها) برگردانیم
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // وقتی صفحه بسته شد، اجازه خاموش شدن مجدد صفحه
    WakelockPlus.disable();

    super.dispose();
  }

  void onTap(BuildContext context) async {
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
    final isRtlCtaText = Constants.isRTL(widget.ad.ctaText);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        widget.fullScreenContentCallback?.onAdDismissedFullScreenContent();
      },
      child: Scaffold(
        backgroundColor: widget.ad.bgColor,
        body: SafeArea(
            child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Center(
                child: Image.file(
                  File(widget.ad.poster),
                  fit: widget.ad.imgBoxFit,
                ),
              ),
            ),

            //cta text
            Positioned(
              bottom: 50,
              // width: 100,
              right: 55,
              left: 55,
              child: CustomAnimatedButton(
                widget.ad.ctaText,
                onTap: () => onTap(context),
                bgColor: widget.ad.ctaBGColor,
                textColor: widget.ad.ctaTextColor,
              ),
            ),

            //close button
            Positioned(
              left: 20,
              top: 20,
              child: CustomCloseButton(
                maxTime: widget.ad.displayTime,
                currentTime: 0,
                isRtl: isRtlCtaText,
                onTap: () {
                  widget.fullScreenContentCallback
                      ?.onAdDismissedFullScreenContent();
                  Navigator.pop(context);
                },
              ),
            ),

            //ad badge
            Positioned(bottom: 0, right: 0, child: AdBadge()),
          ],
        )),
      ),
    );
  }
}
