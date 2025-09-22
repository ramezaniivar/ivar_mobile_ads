import 'package:flutter/material.dart';

import '../../ivar_mobile_ads.dart';

final class IvarBannerAdListener {
  const IvarBannerAdListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
  });

  final void Function(IvarBannerAd ad)? onAdLoaded;
  final void Function(String errorMsg)? onAdFailedToLoad;
  final VoidCallback? onAdImpression;
  final VoidCallback? onAdClicked;
}
