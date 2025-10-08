import 'dart:developer';
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/entity/interstitial_entity.dart';
import 'package:ivar_mobile_ads/src/shared_prefs_source.dart';
import 'package:media_kit/media_kit.dart';

import 'api_service.dart';
import 'device_info_service.dart';
import 'entity/banner_entity.dart';
import 'request/ivar_banner_ad_listener.dart';
import 'ivar_banner_ad.dart';
import 'request/auth_req.dart';
import 'request/ivar_interstitial_load_callback.dart';
import 'secure_storage_service.dart';

class Repository {
  Repository._();
  static final Repository _instance = Repository._();
  static Repository get instance => _instance;

  final _api = ApiService.instance;
  final _secureStorage = SecureStorageService.instance;
  final _deviceInfo = DeviceInfoService.instance;
  final _prefs = SharedPrefsSource.instance;

  bool _isAuth = false;
  Completer<void>? _authCompleter;

  InterstitialEntity? _interstitialAd;
  // IvarBannerAd? _standardBannerAd;
  // IvarBannerAd? _largeBannerAd;
  // IvarBannerAd? _mediumRectangleBannerAd;
  // int _standardBannerRefreshInterval = 0;
  // int _largeBannerRefreshInterval = 0;
  // int _mediumRectangleBannerRefreshInterval = 0;
  // int? _availableAdsCount;

  // final List<IvarBannerAd> _availableStandardBanners = [];
  // final List<IvarBannerAd> _availableLargeBanners = [];
  // final List<IvarBannerAd> _availableMediumRectangleBanners = [];

  // //state
  final List<String> _viewedBanners = [];
  final List<String> _clickedBanners = [];

  //standard Banner
  int? _availableStandardBannersCount;
  int _standardBannerRefreshInterval = 0;
  final List<IvarBannerAd> _standardBanners = [];
  int _currentStandardBannerIndex = 0;

  //large Banner
  int? _availableLargeBannersCount;
  int _largeBannerRefreshInterval = 0;
  final List<IvarBannerAd> _largeBanners = [];
  int _currentLargeBannerIndex = 0;

  //medium rectangle Banner
  int? _availableMediumRectangleBannersCount;
  int _mediumRectangleBannerRefreshInterval = 0;
  final List<IvarBannerAd> _mediumRectangleBanners = [];
  int _currentMediumRectangleBannerIndex = 0;

  bool get isAuth => _isAuth;

  Future<bool> auth(String appID) async {
    if (_isAuth) return true;

    // مقداردهی اولیه media_kit
    MediaKit.ensureInitialized();

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

  Future<IvarBannerAd?> loadBannerAd(
      BannerAdSize size, IvarBannerAdListener bannerAdListener) async {
    // Wait for authentication if it's in progress
    if (_authCompleter != null) await _authCompleter!.future;

    // If not authenticated, start authentication process
    if (!_isAuth) {
      bannerAdListener.onAdFailedToLoad?.call('You need to initilize first');
      return null;
    }

    try {
      if (_getAvailableCount(size) == 0) {
        bannerAdListener.onAdFailedToLoad?.call('banner ad not found');
        return null;
      }

      // load from cache
      final cachedBanner = _getBannerFromCache(size);
      if (cachedBanner != null) {
        bannerAdListener.onAdLoaded?.call(cachedBanner);
        return cachedBanner;
      }

      // get from server
      final response = await _api.getBannerAd(size);

      if (response.data['data'] == null) {
        bannerAdListener.onAdFailedToLoad?.call(response.data['message']);
        return null;
      }

      final BannerEntity ad =
          BannerEntity.fromJson(response.data['data']['ad']);

      // download files
      await _downloadBannerFiles(ad);

      final bannerAd =
          IvarBannerAd(size: size, ad: ad, listener: bannerAdListener);

      // add to cache and set interval
      _addBannerToCache(
          size, bannerAd, response.data['data']['availableAdsCount']);

      bannerAdListener.onAdLoaded?.call(bannerAd);
      return bannerAd;
    } catch (err) {
      bannerAdListener.onAdFailedToLoad?.call(err.toString());
      return null;
    }
  }

  IvarBannerAd? _getBannerFromCache(BannerAdSize size) {
    final banners = _getBannersList(size);
    final currentIndex = _getCurrentIndex(size);

    if (currentIndex >= banners.length) return null;

    return banners[currentIndex];
  }

  Future<(int time, IvarBannerAd? ad)> refreshBanner(
      String adId, BannerAdSize size) async {
    // کاهش تایمر
    _decrementRefreshInterval(size);
    final currentInterval = _getRefreshInterval(size);

    if (currentInterval == 0) {
      // تایمر تموم شد - برو ad بعدی
      _incrementIndex(size);

      // اول از cache بگیر
      final cachedBanner = _getBannerFromCache(size);
      if (cachedBanner != null) {
        _setRefreshInterval(size, cachedBanner.ad.refreshRate);
        return (0, cachedBanner);
      }

      // از سرور بگیر
      return (0, await loadBannerAd(size, IvarBannerAdListener()));
    } else {
      // تایمر هنوز تموم نشده - همون ad فعلی
      final currentAd = _getCurrentAd(size);
      return (currentInterval, adId == currentAd?.ad.id ? null : currentAd);
    }
  }

// Helper methods
  List<IvarBannerAd> _getBannersList(BannerAdSize size) {
    return switch (size) {
      BannerAdSize.standard => _standardBanners,
      BannerAdSize.large => _largeBanners,
      BannerAdSize.mediumRectangle => _mediumRectangleBanners,
    };
  }

  int _getCurrentIndex(BannerAdSize size) {
    return switch (size) {
      BannerAdSize.standard => _currentStandardBannerIndex,
      BannerAdSize.large => _currentLargeBannerIndex,
      BannerAdSize.mediumRectangle => _currentMediumRectangleBannerIndex,
    };
  }

  int _getRefreshInterval(BannerAdSize size) {
    return switch (size) {
      BannerAdSize.standard => _standardBannerRefreshInterval,
      BannerAdSize.large => _largeBannerRefreshInterval,
      BannerAdSize.mediumRectangle => _mediumRectangleBannerRefreshInterval,
    };
  }

  int? _getAvailableCount(BannerAdSize size) {
    return switch (size) {
      BannerAdSize.standard => _availableStandardBannersCount,
      BannerAdSize.large => _availableLargeBannersCount,
      BannerAdSize.mediumRectangle => _availableMediumRectangleBannersCount,
    };
  }

  IvarBannerAd? _getCurrentAd(BannerAdSize size) {
    final banners = _getBannersList(size);
    final index = _getCurrentIndex(size);
    return index < banners.length ? banners[index] : null;
  }

  void _incrementIndex(BannerAdSize size) {
    switch (size) {
      case BannerAdSize.standard:
        _currentStandardBannerIndex++;
        if (_currentStandardBannerIndex >=
            (_availableStandardBannersCount ?? 1)) {
          _currentStandardBannerIndex = 0;
        }
        break;
      case BannerAdSize.large:
        _currentLargeBannerIndex++;
        if (_currentLargeBannerIndex >= (_availableLargeBannersCount ?? 1)) {
          _currentLargeBannerIndex = 0;
        }
        break;
      case BannerAdSize.mediumRectangle:
        _currentMediumRectangleBannerIndex++;
        if (_currentMediumRectangleBannerIndex >=
            (_availableMediumRectangleBannersCount ?? 1)) {
          _currentMediumRectangleBannerIndex = 0;
        }
        break;
    }
  }

  void _decrementRefreshInterval(BannerAdSize size) {
    switch (size) {
      case BannerAdSize.standard:
        _standardBannerRefreshInterval--;
      case BannerAdSize.large:
        _largeBannerRefreshInterval--;
      case BannerAdSize.mediumRectangle:
        _mediumRectangleBannerRefreshInterval--;
    }
  }

  void _setRefreshInterval(BannerAdSize size, int interval) {
    switch (size) {
      case BannerAdSize.standard:
        _standardBannerRefreshInterval = interval;
      case BannerAdSize.large:
        _largeBannerRefreshInterval = interval;
      case BannerAdSize.mediumRectangle:
        _mediumRectangleBannerRefreshInterval = interval;
    }
  }

  void _addBannerToCache(
      BannerAdSize size, IvarBannerAd bannerAd, int availableCount) {
    switch (size) {
      case BannerAdSize.standard:
        _standardBannerRefreshInterval = bannerAd.ad.refreshRate;
        _availableStandardBannersCount = availableCount;
        _standardBanners.add(bannerAd);
        break;
      case BannerAdSize.large:
        _largeBannerRefreshInterval = bannerAd.ad.refreshRate;
        _availableLargeBannersCount = availableCount;
        _largeBanners.add(bannerAd);
        break;
      case BannerAdSize.mediumRectangle:
        _mediumRectangleBannerRefreshInterval = bannerAd.ad.refreshRate;
        _availableMediumRectangleBannersCount = availableCount;
        _mediumRectangleBanners.add(bannerAd);
        break;
    }
  }

  Future<void> _downloadBannerFiles(BannerEntity ad) async {
    final documentDir = await _deviceInfo.appDocumentsDir;
    final bannerFilesPath = '${documentDir.path}/ivar_mobile_ads/banner';

    switch (ad) {
      case TextualBannerEntity():
        if (ad.icon == null) break;
        final savePath = '$bannerFilesPath/${ad.icon!.split('/').last}';
        final bool isExistsFile = await File(savePath).exists();
        if (!isExistsFile) await _api.downloadFile(ad.icon!, savePath);
        ad.icon = savePath;
        break;
      case ImageBannerEntity():
        final savePath = '$bannerFilesPath/${ad.image.split('/').last}';
        final bool isExistsFile = await File(savePath).exists();
        if (!isExistsFile) await _api.downloadFile(ad.image, savePath);
        ad.image = savePath;
        break;
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

  Future<bool> loadInterstitialAd(
      {IvarInterstitialLoadCallback? adLoadCallback}) async {
    if (_authCompleter != null) await _authCompleter!.future;
    if (!_isAuth) {
      log('Ivar Mobile Ads: You need to initilize first');
      return false;
    }

    try {
      if (isLoadedInterstitialAd) {
        adLoadCallback?.onAdFailedToLoad(
            'The interstitial ad is preloaded and ready to show');
        log('Ivar Mobile Ads: The interstitial ad is preloaded and ready to show');
        return true;
      }

      //GET request
      final res = await _api.getInterstitialAd();
      if (res.data['data'] == null) {
        log('Ivar Mobile Ads Error: ${res.data['message']}');
        adLoadCallback?.onAdFailedToLoad(res.data['message']);
        return false;
      }

      final InterstitialEntity ad =
          InterstitialEntity.fromJson(res.data['data']);

      switch (ad) {
        case ImageInterstitialEntity():
          //download image file
          final documentDir = await _deviceInfo.appDocumentsDir;
          final interstitialImageFilesPath =
              '${documentDir.path}/ivar_mobile_ads/interstitial/image';
          final savePath =
              '$interstitialImageFilesPath/${ad.media.split('/').last}';
          final bool isExistsFile = await File(savePath).exists();
          if (!isExistsFile) await _api.downloadFile(ad.media, savePath);
          ad.media = savePath;
          break;
        case VideoInterstitialEntity():
          // - - - - download image files
          final documentDir = await _deviceInfo.appDocumentsDir;
          final interstitialVideoFilesPath =
              '${documentDir.path}/ivar_mobile_ads/interstitial/video';
          //poster
          final posterSavePath =
              '$interstitialVideoFilesPath/${_convertVideoFilesPath(ad.poster)}';
          final bool isExistsPosterFile = await File(posterSavePath).exists();
          if (!isExistsPosterFile) {
            await _api.downloadFile(ad.poster, posterSavePath);
          }
          ad.poster = posterSavePath;
          //icon
          if (ad.icon != null) {
            final iconSavePath =
                '$interstitialVideoFilesPath/${_convertVideoFilesPath(ad.icon!)}';
            final bool isExistsIconFile = await File(iconSavePath).exists();
            if (!isExistsIconFile) {
              await _api.downloadFile(ad.icon!, iconSavePath);
            }
            ad.icon = iconSavePath;
          }
          break;
        case UnsupportedInterstitialEntity():
          log('Ivar Mobile Ads Error: Your package version does not support this type of ad (${ad.contentType} ad type)');
          adLoadCallback?.onAdFailedToLoad(
              'Your package version does not support this type of ad (${ad.contentType} ad type)');
          return false;
      }

      _interstitialAd = ad;
      log('Ivar Mobile Ads: Loaded Interstitial ad Successfully');
      adLoadCallback?.onAdLoaded();
      return true;
    } catch (err) {
      log('Ivar Mobile Ads Error: ${err.toString()}');
      adLoadCallback?.onAdFailedToLoad(err.toString());
      return false;
    }
  }

  String _convertVideoFilesPath(String path) {
    // همه / یا \ رو به / تبدیل کن تا در ویندوز هم درست کار کنه
    path = path.replaceAll('\\', '/');

    // جدا کردن بخش‌های مسیر
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.length < 2) return path; // اگر مسیر کوتاه بود

    final folder = parts[parts.length - 2]; // پوشه قبل از فایل
    final filename = parts.last; // نام فایل

    return '$folder-$filename';
  }

  bool get isLoadedInterstitialAd => _interstitialAd != null;

  InterstitialEntity? showInterstitialAd(
      {void Function(String errorMsg)? onError}) {
    if (!isLoadedInterstitialAd) {
      log('Ivar Mobile Ads Error: You must load the ad first');
      if (onError != null) onError('You must load the ad first');
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
    final bannerFilesPath = '${documentDir.path}/ivar_mobile_ads/banner';

    //remove interstitial files
    final interstitialAdsDir = Directory(interstitialFilesPath);
    if (await interstitialAdsDir.exists()) {
      await interstitialAdsDir.delete(recursive: true);
    }

    //remove banner files
    final bannerAdsDir = Directory(bannerFilesPath);
    if (await bannerAdsDir.exists()) {
      await bannerAdsDir.delete(recursive: true);
    }
  }
}
