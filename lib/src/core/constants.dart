import 'package:flutter/material.dart';

import 'ming_cute_font.dart';

final class Constants {
  static const baseUrl = 'https://ivar-ads.com';
  static const apiV1 = '$baseUrl/api/v1';

  static const textColor = Color.fromARGB(255, 66, 66, 78);
}

enum IvarDevice { android, iPhone }

enum BannerAdSize {
  standard,
  large,
  mediumRectangle;

  int get width {
    switch (this) {
      case BannerAdSize.mediumRectangle:
        return 300;
      case BannerAdSize.large:
        return 320;
      case BannerAdSize.standard:
        return 320;
    }
  }

  int get height {
    switch (this) {
      case BannerAdSize.mediumRectangle:
        return 250;
      case BannerAdSize.large:
        return 100;
      case BannerAdSize.standard:
        return 50;
    }
  }
}

enum AdType { image, textual }

enum AdPlatform {
  none,
  web,
  instagram,
  telegram,
  youTube,
  android,
  iPhone;

  IconData? get icon {
    switch (this) {
      case AdPlatform.web:
        return MingCute.web_fill;
      case AdPlatform.instagram:
        return MingCute.camera_fill;
      case AdPlatform.telegram:
        return MingCute.telegram_fill;
      case AdPlatform.youTube:
        return MingCute.youtube_fill;
      case AdPlatform.android:
        return MingCute.Android_2_fill;
      case AdPlatform.iPhone:
        return MingCute.apple_fill;
      default:
        return null;
    }
  }

  Color? get color {
    switch (this) {
      case AdPlatform.web:
        return Colors.black54;
      case AdPlatform.instagram:
        return Colors.pink;
      case AdPlatform.telegram:
        return Colors.blue;
      case AdPlatform.youTube:
        return Colors.red;
      case AdPlatform.android:
        return Colors.teal;
      case AdPlatform.iPhone:
        return Colors.black54;
      default:
        return null;
    }
  }
}
