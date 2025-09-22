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

      // اول از cache چک کن
      final cachedBanner = _getBannerFromCache(size);
      if (cachedBanner != null) {
        log('loaded from cache');
        bannerAdListener.onAdLoaded?.call(cachedBanner);
        return cachedBanner;
      }

      // از سرور بگیر
      await Future.delayed(Duration(milliseconds: 3600));
      final response = await _api.getBannerAd(size);

      if (response.data['data'] == null) {
        bannerAdListener.onAdFailedToLoad?.call(response.data['message']);
        return null;
      }

      final BannerEntity ad =
          BannerEntity.fromJson(response.data['data']['ad']);

      // دانلود فایل‌ها
      await _downloadBannerFiles(ad);

      final bannerAd =
          IvarBannerAd(size: size, ad: ad, listener: bannerAdListener);

      // اضافه کردن به cache و ست کردن تنظیمات
      _addBannerToCache(
          size, bannerAd, response.data['data']['availableAdsCount']);

      log('loaded from server');
      bannerAdListener.onAdLoaded?.call(bannerAd);
      return bannerAd;
    } catch (err) {
      log(err.toString());
      return null;
    }
  }

  IvarBannerAd? _getBannerFromCache(BannerAdSize size) {
    final banners = _getBannersList(size);
    final currentIndex = _getCurrentIndex(size);

    log('current index: $currentIndex, cache length: ${banners.length}');

    if (currentIndex >= banners.length) return null;

    log('loaded from cache');
    return banners[currentIndex];
  }

  Future<(int time, IvarBannerAd? ad)> refreshBanner(
      String adId, BannerAdSize size) async {
    // کاهش تایمر
    _decrementRefreshInterval(size);
    final currentInterval = _getRefreshInterval(size);

    log('refresh time: $currentInterval');

    if (currentInterval == 0) {
      // تایمر تموم شد - برو ad بعدی
      _incrementIndex(size);
      log('incremented index to: ${_getCurrentIndex(size)}');

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
  // Future<IvarBannerAd?> loadBannerAd(
  //     BannerAdSize size, IvarBannerAdListener bannerAdListener) async {
  //   // Wait for authentication if it's in progress
  //   if (_authCompleter != null) await _authCompleter!.future;

  //   // If not authenticated, start authentication process
  //   if (!_isAuth) {
  //     bannerAdListener.onAdFailedToLoad?.call('You need to initilize first');
  //     return null;
  //   }

  //   try {
  //     switch (size) {
  //       case BannerAdSize.standard:
  //         if (_availableStandardBannersCount == 0) {
  //           bannerAdListener.onAdFailedToLoad?.call('banner ad not found');
  //           return null;
  //         }
  //         if (_standardBannerRefreshInterval > 0) {
  //           final cacheAd = _getBannerFromCache(size, setInterval: false);
  //           if (cacheAd != null) return cacheAd;
  //         }
  //         break;
  //       case BannerAdSize.large:
  //         if (_availableLargeBannersCount == 0) {
  //           bannerAdListener.onAdFailedToLoad?.call('banner ad not found');
  //           return null;
  //         }
  //         if (_largeBannerRefreshInterval > 0) {
  //           final cacheAd = _getBannerFromCache(size, setInterval: false);
  //           if (cacheAd != null) return cacheAd;
  //         }
  //         break;
  //       case BannerAdSize.mediumRectangle:
  //         if (_availableMediumRectangleBannersCount == 0) {
  //           bannerAdListener.onAdFailedToLoad?.call('banner ad not found');
  //           return null;
  //         }
  //         if (_mediumRectangleBannerRefreshInterval > 0) {
  //           final cacheAd = _getBannerFromCache(size, setInterval: false);
  //           if (cacheAd != null) return cacheAd;
  //         }
  //         break;
  //     }

  //     final cachedBanner = _getBannerFromCache(size);
  //     if (cachedBanner != null) {
  //       bannerAdListener.onAdLoaded?.call(cachedBanner);
  //       return cachedBanner;
  //     }

  //     await Future.delayed(Duration(milliseconds: 3600));
  //     final response = await _api.getBannerAd(size);

  //     if (response.data['data'] == null) {
  //       bannerAdListener.onAdFailedToLoad?.call(response.data['message']);
  //       return null;
  //     }

  //     final BannerEntity ad =
  //         BannerEntity.fromJson(response.data['data']['ad']);

  //     final documentDir = await _deviceInfo.appDocumentsDir;
  //     final bannerFilesPath = '${documentDir.path}/ivar_mobile_ads/banner';

  //     switch (ad) {
  //       case TextualBannerEntity():
  //         if (ad.icon == null) break;
  //         //download icon image file
  //         final savePath = '$bannerFilesPath/${ad.icon!.split('/').last}';
  //         final bool isExistsFile = await File(savePath).exists();
  //         if (!isExistsFile) await _api.downloadFile(ad.icon!, savePath);
  //         ad.icon = savePath;
  //         break;
  //       case ImageBannerEntity():
  //         //download image file
  //         final savePath = '$bannerFilesPath/${ad.image.split('/').last}';
  //         final bool isExistsFile = await File(savePath).exists();
  //         if (!isExistsFile) await _api.downloadFile(ad.image, savePath);
  //         ad.image = savePath;
  //         break;
  //     }

  //     final bannerAd = IvarBannerAd(
  //       size: size,
  //       ad: ad,
  //       listener: bannerAdListener,
  //     );

  //     switch (size) {
  //       case BannerAdSize.standard:
  //         _standardBannerRefreshInterval = ad.refreshRate;
  //         _availableStandardBannersCount =
  //             response.data['data']['availableAdsCount'];
  //         _standardBanners.add(bannerAd);
  //         break;
  //       case BannerAdSize.large:
  //         _largeBannerRefreshInterval = ad.refreshRate;
  //         _availableLargeBannersCount =
  //             response.data['data']['availableAdsCount'];
  //         _largeBanners.add(bannerAd);
  //         break;
  //       case BannerAdSize.mediumRectangle:
  //         _mediumRectangleBannerRefreshInterval = ad.refreshRate;
  //         _availableMediumRectangleBannersCount =
  //             response.data['data']['availableAdsCount'];
  //         _mediumRectangleBanners.add(bannerAd);
  //         break;
  //     }

  //     log('loaded from server');
  //     bannerAdListener.onAdLoaded?.call(bannerAd);
  //     return bannerAd;
  //   } catch (err) {
  //     log(err.toString());
  //     return null;
  //   }
  // }

  // IvarBannerAd? _getBannerFromCache(BannerAdSize size,
  //     {bool setInterval = true}) {
  //   switch (size) {
  //     case BannerAdSize.standard:
  //       log('current index: $_currentStandardBannerIndex');
  //       log('standard banners length: ${_standardBanners.length}');
  //       if (_currentStandardBannerIndex > (_standardBanners.length - 1)) break;
  //       log('loaded from cache');
  //       final ad = _standardBanners[_currentStandardBannerIndex];
  //       if (setInterval) _standardBannerRefreshInterval = ad.ad.refreshRate;
  //       return ad;
  //     case BannerAdSize.large:
  //       if (_currentLargeBannerIndex > (_largeBanners.length - 1)) break;
  //       final ad = _largeBanners[_currentLargeBannerIndex];
  //       if (setInterval) _largeBannerRefreshInterval = ad.ad.refreshRate;
  //       return ad;
  //     case BannerAdSize.mediumRectangle:
  //       if (_currentMediumRectangleBannerIndex >
  //           (_mediumRectangleBanners.length - 1)) {
  //         break;
  //       }
  //       final ad = _mediumRectangleBanners[_currentMediumRectangleBannerIndex];
  //       if (setInterval) {
  //         _mediumRectangleBannerRefreshInterval = ad.ad.refreshRate;
  //       }
  //       return ad;
  //   }
  //   return null;
  // }

  // void _incrementStandardBannerIndex() {
  //   if (_currentStandardBannerIndex < (_availableStandardBannersCount ?? 0)) {
  //     _currentStandardBannerIndex++;
  //   } else {
  //     _currentStandardBannerIndex = 0;
  //   }
  // }

  // void _incrementLargeBannerIndex() {
  //   if (_currentLargeBannerIndex < (_availableLargeBannersCount ?? 0)) {
  //     _currentLargeBannerIndex++;
  //   } else {
  //     _currentLargeBannerIndex = 0;
  //   }
  // }

  // void _incrementMRectangleBannerIndex() {
  //   if (_currentMediumRectangleBannerIndex <
  //       (_availableMediumRectangleBannersCount ?? 0)) {
  //     _currentMediumRectangleBannerIndex++;
  //   } else {
  //     _currentMediumRectangleBannerIndex = 0;
  //   }
  // }

  // Future<(int time, IvarBannerAd? ad)> refreshBanner(
  //     String adId, BannerAdSize size) async {
  //   switch (size) {
  //     case BannerAdSize.standard:
  //       _standardBannerRefreshInterval--;
  //       log('refresh time: $_standardBannerRefreshInterval');
  //       if (_standardBannerRefreshInterval == 0) {
  //         _incrementStandardBannerIndex();
  //         return (0, await loadBannerAd(size, IvarBannerAdListener()));
  //       } else if (_standardBannerRefreshInterval > 0) {
  //         return (
  //           _standardBannerRefreshInterval,
  //           adId == _standardBanners[_currentStandardBannerIndex].ad.id
  //               ? null
  //               : _standardBanners[_currentStandardBannerIndex]
  //         );
  //       }
  //     case BannerAdSize.large:
  //       _largeBannerRefreshInterval--;
  //       if (_largeBannerRefreshInterval == 0) {
  //         _incrementLargeBannerIndex();
  //         return (0, await loadBannerAd(size, IvarBannerAdListener()));
  //       } else if (_largeBannerRefreshInterval > 0) {
  //         return (
  //           _largeBannerRefreshInterval,
  //           adId == _largeBanners[_currentStandardBannerIndex].ad.id
  //               ? null
  //               : _largeBanners[_currentStandardBannerIndex]
  //         );
  //       }
  //     case BannerAdSize.mediumRectangle:
  //       _mediumRectangleBannerRefreshInterval--;
  //       if (_mediumRectangleBannerRefreshInterval == 0) {
  //         _incrementMRectangleBannerIndex();
  //         return (0, await loadBannerAd(size, IvarBannerAdListener()));
  //       } else if (_mediumRectangleBannerRefreshInterval > 0) {
  //         return (
  //           _mediumRectangleBannerRefreshInterval,
  //           adId == _mediumRectangleBanners[_currentStandardBannerIndex].ad.id
  //               ? null
  //               : _mediumRectangleBanners[_currentStandardBannerIndex]
  //         );
  //       }
  //   }

  //   return (-1, null);
  // }

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
          final interstitialFilesPath =
              '${documentDir.path}/ivar_mobile_ads/interstitial';
          final savePath = '$interstitialFilesPath/${ad.media.split('/').last}';
          final bool isExistsFile = await File(savePath).exists();
          if (!isExistsFile) await _api.downloadFile(ad.media, savePath);
          ad.media = savePath;
          break;
        case UnsupportedInterstitialEntity():
          log('Ivar Mobile Ads Error: Your package version does not support this type of ad (${ad.type} ad type)');
          adLoadCallback?.onAdFailedToLoad(
              'Your package version does not support this type of ad (${ad.type} ad type)');
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
