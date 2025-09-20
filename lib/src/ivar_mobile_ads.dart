import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:ivar_mobile_ads/ivar_mobile_ads.dart';
import 'package:ivar_mobile_ads/src/ivar_interstitial_ad_widget.dart';

import 'repository.dart';

class IvarMobileAds {
  IvarMobileAds._();
  static final IvarMobileAds _instance = IvarMobileAds._();
  static IvarMobileAds get instance => _instance;
  final _repo = Repository.instance;

  Future<bool> init(String appID) => _repo.auth(appID);

  bool get isInit => _repo.isAuth;

  Future<IvarBannerAd?> loadBannerAds(BannerAdSize size) =>
      _repo.getBannerAds(size);

  Future<bool> loadInterstitialAd(
          {IvarInterstitialLoadCallback? adLoadCallback}) =>
      _repo.loadInterstitialAd(adLoadCallback: adLoadCallback);

  bool showInterstitialAd(BuildContext context,
      IvarFullScreenContentCallback? fullScreenContentCallback) {
    if (!context.mounted) {
      log('Ivar Mobile Ads: "context" is not available');
      fullScreenContentCallback
          ?.onAdFailedToShowFullScreenContent('The context is not available');
      return false;
    }

    final ad = _repo.showInterstitialAd(
        onError: fullScreenContentCallback?.onAdFailedToShowFullScreenContent);
    if (ad == null) return false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IvarInterstitialAdWidget(
          ad,
          fullScreenContentCallback: fullScreenContentCallback,
        ),
      ),
    );
    return true;
  }
}
