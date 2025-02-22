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

  double get width => switch (this) {
        BannerAdSize.standard => 320,
        BannerAdSize.large => 320,
        BannerAdSize.mediumRectangle => 300,
      };

  double get height => switch (this) {
        BannerAdSize.standard => 50,
        BannerAdSize.large => 100,
        BannerAdSize.mediumRectangle => 250,
      };
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
