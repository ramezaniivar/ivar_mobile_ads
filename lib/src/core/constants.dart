import 'package:flutter/material.dart';

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
