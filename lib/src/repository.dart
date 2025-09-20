import 'dart:developer';
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/entity/interstitial_entity.dart';
import 'package:ivar_mobile_ads/src/shared_prefs_source.dart';

import 'api_service.dart';
import 'device_info_service.dart';
import 'entity/banner_entity.dart';
import 'ivar_banner_ad.dart';
import 'request/auth_req.dart';
import 'secure_storage_service.dart';

class Repository {
  Repository._();
  static final Repository _instance = Repository._();
  static Repository get instance => _instance;

  final _api = ApiService.instance;
  final _secureStorage = SecureStorageService.instance;
  final _deviceInfo = DeviceInfoService.instance;
  final _prefs = SharedPrefsSource.instance;
  final List<String> _viewedBanners = [];
  final List<String> _clickedBanners = [];

  bool _isAuth = false;
  Completer<void>? _authCompleter;
  IvarBannerAd? _standardBanners;
  IvarBannerAd? _largeBanners;
  IvarBannerAd? _mediumRectangleBanners;

  InterstitialEntity? _interstitialAd;

  bool get isAuth => _isAuth;

  Future<bool> auth(String appID) async {
    if (_isAuth) return true;

    // If authentication is already in progress, wait for it
    if (_authCompleter != null) {
      await _authCompleter!.future;
      return _isAuth;
    }

    _authCompleter = Completer<void>();

    try {
      //clear cache
      final isClearCacheDate = await _isClearCacheDate();
      if (isClearCacheDate) await _clearCache();

      final req = AuthReq(
        appId: appID,
        deviceId: await _deviceInfo.id,
        language: _deviceInfo.languageCode,
        timeZone: await _deviceInfo.timeZone,
      );

      final response = await _api.auth(req);

      await _saveTokens(
        response.data['accessToken'],
        response.data['refreshToken'],
      );
      _isAuth = true;
      _authCompleter!.complete();
      return true;
    } catch (err) {
      if (err is DioException) {
        log('ivar_mobile_ads: $err');
      } else {
        log('ivar_mobile_ads: $err');
      }
      _isAuth = false;
      _authCompleter!.completeError(err);
      return false;
    } finally {
      _authCompleter = null;
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.saveAccessToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
  }

  Future<IvarBannerAd?> getBannerAds(BannerAdSize size) async {
    // Wait for authentication if it's in progress
    if (_authCompleter != null) await _authCompleter!.future;

    // If not authenticated, start authentication process
    if (!_isAuth) {
      log('ivar_mobile_ads: You need to initilize first');
      return null;
    }

    try {
      switch (size) {
        case BannerAdSize.standard:
          if (_standardBanners != null) return _standardBanners;
          break;
        case BannerAdSize.large:
          if (_largeBanners != null) return _largeBanners;
          break;
        case BannerAdSize.mediumRectangle:
          if (_mediumRectangleBanners != null) return _mediumRectangleBanners;
          break;
      }

      final response = await _api.getBannerAds(size);
      final banners = bannerEntityFromJson(response.data['data']);
      if (banners.isEmpty) return null;

      switch (size) {
        case BannerAdSize.standard:
          _standardBanners = IvarBannerAd(size: size, ads: banners);
          return _standardBanners;
        case BannerAdSize.large:
          _largeBanners = IvarBannerAd(size: size, ads: banners);
          return _largeBanners;
        case BannerAdSize.mediumRectangle:
          _mediumRectangleBanners = IvarBannerAd(size: size, ads: banners);
          return _mediumRectangleBanners;
      }
    } catch (err) {
      log(err.toString());
      return null;
    }
  }

  Future<void> viewBanner(String id) async {
    if (_authCompleter != null) await _authCompleter!.future;
    if (!_isAuth) {
      log('ivar_mobile_ads: You need to initilize first');
      return;
    }

    if (_viewedBanners.contains(id)) return;
    _viewedBanners.add(id);

    try {
      await _api.viewBanner(id);
    } catch (err) {
      log(err.toString());
    }
  }

  Future<void> clickBanner(String id) async {
    if (_authCompleter != null) await _authCompleter!.future;
    if (!_isAuth) {
      log('ivar_mobile_ads: You need to initilize first');
      return;
    }

    if (_clickedBanners.contains(id)) return;
    _clickedBanners.add(id);

    try {
      await _api.clickBanner(id);
    } catch (err) {
      log(err.toString());
    }
  }

  /// - - - - - - - - -  - - - - - INTERSTITIAL - - - - - - - - - - - - - - - -

  Future<bool> loadInterstitialAd() async {
    if (_authCompleter != null) await _authCompleter!.future;
    if (!_isAuth) {
      log('Ivar Mobile Ads: You need to initilize first');
      return false;
    }

    try {
      if (isLoadedInterstitialAd) {
        log('Ivar Mobile Ads: The interstitial ad is preloaded and ready to show');
        return true;
      }

      //GET request
      final res = await _api.getInterstitialAd();
      if (res.data['data'] == null) {
        log('Ivar Mobile Ads Error: ${res.data['message']}');
        return false;
      }

      final InterstitialEntity ad =
          InterstitialEntity.fromJson(res.data['data']);

      switch (ad) {
        case ImageInterstitialEntity():
          //download image file
          final documentDir = await _deviceInfo.appDocumentsDir;
          final interstitialFilesPath =
              '${documentDir.path}/ivar_mobile_ads/interstitial';
          final savePath = '$interstitialFilesPath/${ad.media.split('/').last}';
          final bool isExistsFile = await File(savePath).exists();
          if (!isExistsFile) await _api.downloadFile(ad.media, savePath);
          ad.media = savePath;
          break;
        case UnsupportedInterstitialEntity():
          log('Ivar Mobile Ads Error: Your package version does not support this type of ad (${ad.type} ad type)');
          return false;
      }

      _interstitialAd = ad;
      log('Ivar Mobile Ads: Loaded Interstitial ad Successfully');
      return true;
    } catch (err) {
      log('Ivar Mobile Ads Error: ${err.toString()}');
      return false;
    }
  }

  bool get isLoadedInterstitialAd => _interstitialAd != null;

  InterstitialEntity? showInterstitialAd() {
    if (!isLoadedInterstitialAd) {
      log('Ivar Mobile Ads Error: You must load the ad first.');
      return null;
    }

    final ad = _interstitialAd;
    _interstitialAd = null;

    //viewed
    viewInterstitial(ad!.id);

    return ad;
  }

  Future<void> viewInterstitial(String id) async {
    if (_authCompleter != null) await _authCompleter!.future;
    if (!_isAuth) {
      log('ivar_mobile_ads: You need to initilize first');
      return;
    }

    try {
      await _api.viewInterstitial(id);
    } catch (err) {
      log('Ivar Mobile Ads: ${err.toString()}');
    }
  }

  Future<void> clickInterstitial(String id) async {
    if (_authCompleter != null) await _authCompleter!.future;
    if (!_isAuth) {
      log('ivar_mobile_ads: You need to initilize first');
      return;
    }

    try {
      await _api.clickInterstitial(id);
    } catch (err) {
      log('Ivar Mobile Ads: ${err.toString()}');
    }
  }

  Future<bool> _isClearCacheDate() async {
    //چک کردن زمانی که آخرین بار که فایل های کش پاک شده
    final clearedCacheDate = await _prefs.clearedCacheDate;
    if (clearedCacheDate == null) {
      _prefs.setClearedCacheDate(DateTime.now());
      return false;
    }

    //اگر از آخرین دفعه که کش پاک شده 30 روز گذشته بود
    final now = DateTime.now();
    final duration = now.difference(clearedCacheDate);
    if (duration.inDays >= 30) {
      //بروزرسانی تاریخ آخرین دفعه که کش پاک شده
      _prefs.setClearedCacheDate(now);
      return true;
    }

    return false;
  }

  Future<void> _clearCache() async {
    final documentDir = await _deviceInfo.appDocumentsDir;
    final interstitialFilesPath =
        '${documentDir.path}/ivar_mobile_ads/interstitial';

    final interstitialAdsDir = Directory(interstitialFilesPath);
    if (await interstitialAdsDir.exists()) {
      await interstitialAdsDir.delete(recursive: true);
    }
  }
}
