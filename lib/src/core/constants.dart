import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:ivar_mobile_ads/src/repository.dart';
import 'package:url_launcher/url_launcher.dart';

final class Constants {
  static const baseUrl = 'https://ivar-ads.com';
  static const apiV1 = '$baseUrl/api/v1';
  static const apiV2 = '$baseUrl/api/v2';

  static const textColor = Color.fromARGB(255, 66, 66, 78);

  static bool isRTL(String text) {
    if (text.trim().isEmpty) return false;

    // گرفتن اولین کاراکتر واقعی (غیر فاصله)
    final firstChar = text.trim().characters.first;

    // گرفتن کد یونیکد
    final code = firstChar.codeUnitAt(0);

    // بررسی محدوده‌های زبان‌های RTL (عربی، فارسی، عبری)
    // عربی و فارسی: U+0600 تا U+06FF
    // عبری: U+0590 تا U+05FF
    return (code >= 0x0590 && code <= 0x08FF);
  }

  static void interstitialCallAction(BuildContext context,
      {required String adId, required String link}) async {
    //log click
    Repository.instance.clickInterstitial(adId);

    /// check is cafe bazaar link
    if (link.contains('https://cafebazaar.ir/app/') && Platform.isAndroid) {
      try {
        final packageName = link.split('/').last;

        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'bazaar://details/modal?id=$packageName',
          package: 'com.farsitel.bazaar',
        );

        await intent.launch();

        //close ad
        if (context.mounted) Navigator.pop(context);
        return;
      } catch (err, _) {
        log('error $err');
      }
    }

    ///check is myket link for auto download intent
    // https://myket.ir/app/com.example.app/auto-dl
    if (link.contains('https://myket.ir/app/') &&
        link.split('/').last == 'auto-dl') {
      ///remove "/audo-dl" from link
      link = link.replaceFirst('/auto-dl', '');

      if (Platform.isAndroid) {
        try {
          //get package name from link
          final packageName = link.split('/').last;

          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'myket://download/$packageName',
            package: 'ir.mservices.market',
          );

          await intent.launch();

          //close ad
          if (context.mounted) Navigator.pop(context);
          return;
        } catch (err, _) {
          log('error $err');
        }
      }
    }

    try {
      if (!await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication)) {
        log("There was a problem opening the link");
      }
    } catch (err, _) {
      log('The link is invalid');
    }

    //close ad
    if (context.mounted) Navigator.pop(context);
  }

  static String convertToPersianNumbers(String input) {
    const englishToPersian = {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };

    return input.split('').map((char) {
      return englishToPersian[char] ?? char;
    }).join('');
  }
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
