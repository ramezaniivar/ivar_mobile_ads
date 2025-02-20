import 'dart:developer';

import 'package:ivar_mobile_ads/src/core/constants.dart';

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

  bool _isAuth = false;
  IvarBannerAd? _standardBanners;
  IvarBannerAd? _largeBanners;
  IvarBannerAd? _mediumRectangleBanners;

  bool get isAuth => _isAuth;

  Future<bool> auth(String appID) async {
    if (_isAuth) throw Exception('You have already authenticated');

    try {
      final req = AuthReq(
        appId: appID,
        deviceId: await _deviceInfo.id,
        language: _deviceInfo.languageCode,
        timeZone: _deviceInfo.timeZone,
      );

      final response = await _api.auth(req);

      //save tokens
      await _saveTokens(
        response.data['accessToken'],
        response.data['refreshToken'],
      );
      _isAuth = true;
      return true;
    } catch (err) {
      log(err.toString());
      _isAuth = false;
      return false;
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.saveAccessToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
  }

  Future<IvarBannerAd?> getBannerAds(BannerAdSize size) async {
    if (!_isAuth) throw Exception('You need to initilize first');

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

      //GET request
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
    if (!_isAuth) throw Exception('You need to initilize first');

    try {
      await _api.view(id);
    } catch (err) {
      log(err.toString());
    }
  }

  Future<void> clickBanner(String id) async {
    if (!_isAuth) throw Exception('You need to initilize first');

    try {
      await _api.click(id);
    } catch (err) {
      log(err.toString());
    }
  }
}
