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

  IconData? get icon => switch (this) {
        AdPlatform.web => MingCute.web_fill,
        AdPlatform.instagram => MingCute.camera_fill,
        AdPlatform.telegram => MingCute.telegram_fill,
        AdPlatform.youTube => MingCute.youtube_fill,
        AdPlatform.android => MingCute.Android_2_fill,
        AdPlatform.iPhone => MingCute.apple_fill,
        AdPlatform.none => null,
      };

  Color? get color => switch (this) {
        AdPlatform.web => Colors.black54,
        AdPlatform.instagram => Colors.pink,
        AdPlatform.telegram => Colors.blue,
        AdPlatform.youTube => Colors.red,
        AdPlatform.android => Colors.teal,
        AdPlatform.iPhone => Colors.black54,
        AdPlatform.none => null,
      };
}
