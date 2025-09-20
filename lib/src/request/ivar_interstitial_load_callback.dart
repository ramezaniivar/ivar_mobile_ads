import 'package:flutter/material.dart';

final class IvarInterstitialLoadCallback {
  const IvarInterstitialLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });

  final VoidCallback onAdLoaded;
  final void Function(String errorMsg) onAdFailedToLoad;
}
