import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:ivar_mobile_ads/ivar_mobile_ads.dart';
import 'package:ivar_mobile_ads/src/core/check_internet.dart';
import 'package:ivar_mobile_ads/src/entity/interstitial_entity.dart';
import 'package:ivar_mobile_ads/src/ivar_interstitial_image_ad_widget.dart';

import 'ivar_interstitial_video_ad_widget.dart';
import 'repository.dart';

class IvarMobileAds {
  IvarMobileAds._();
  static final IvarMobileAds _instance = IvarMobileAds._();
  static IvarMobileAds get instance => _instance;
  final _repo = Repository.instance;

  Future<bool> init(String appID) => _repo.auth(appID);

  bool get isInit => _repo.isAuth;

  Future<IvarBannerAd?> loadBannerAd(BannerAdSize size,
          {required IvarBannerAdListener listener}) =>
      _repo.loadBannerAd(size, listener);

  Future<bool> loadInterstitialAd(
          {IvarInterstitialLoadCallback? adLoadCallback}) =>
      _repo.loadInterstitialAd(adLoadCallback: adLoadCallback);

  Future<bool> showInterstitialAd(BuildContext context,
      {IvarFullScreenContentCallback? fullScreenContentCallback}) async {
    if (!context.mounted) {
      log('Ivar Mobile Ads: "context" is not available');
      fullScreenContentCallback
          ?.onAdFailedToShowFullScreenContent('The context is not available');
      return false;
    }

    final ad = _repo.showInterstitialAd(
        onError: fullScreenContentCallback?.onAdFailedToShowFullScreenContent);
    if (ad == null) return false;

    switch (ad) {
      case ImageInterstitialEntity():
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IvarInterstitialImageAdWidget(
              ad,
              fullScreenContentCallback: fullScreenContentCallback,
            ),
          ),
        );
        break;
      case VideoInterstitialEntity():

        //check internet
        if (!await checkInternet()) {
          fullScreenContentCallback
              ?.onAdFailedToShowFullScreenContent('check internet connection');
          return false;
        }

        if (!context.mounted) {
          fullScreenContentCallback
              ?.onAdFailedToShowFullScreenContent('context not found');
          return false;
        }

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IvarInterstitialVideoAdWidget(
                ad,
                fullScreenContentCallback: fullScreenContentCallback,
              ),
            ));
        break;
      case UnsupportedInterstitialEntity():
        fullScreenContentCallback?.onAdFailedToShowFullScreenContent(
            '"${ad.contentType} type" advertising is not supported in this version of the library');
        return false;
    }

    return true;
  }
}
