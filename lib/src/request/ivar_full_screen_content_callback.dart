import 'package:flutter/material.dart';

final class IvarFullScreenContentCallback {
  const IvarFullScreenContentCallback({
    required this.onAdShowedFullScreenContent,
    required this.onAdDismissedFullScreenContent,
    required this.onAdClicked,
    required this.onAdCompleted,
    required this.onAdFailedToShowFullScreenContent,
  });

  ///زمانی که صفحه تبلیغ نمایش داده میشه
  final VoidCallback onAdShowedFullScreenContent;

  ///زمانی که صفحه تبلیغ بسته میشه
  final VoidCallback onAdDismissedFullScreenContent;

  ///کلیک روی تبلیغ
  final VoidCallback onAdClicked;

  ///زمانی که تایمر تبلیغ تمام میشه
  final VoidCallback onAdCompleted;

  final void Function(String errorMsg) onAdFailedToShowFullScreenContent;
}
