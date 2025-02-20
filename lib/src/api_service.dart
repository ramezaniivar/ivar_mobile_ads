import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/request/auth_req.dart';
import 'package:ivar_mobile_ads/src/secure_storage_service.dart';
import 'package:ivar_mobile_ads/src/core/token_interceptor.dart';

// final class ApiService {
//   ApiService() : _dio = Dio() {
//     _dio.interceptors.add(
//       TokenInterceptor(
//         dio: _dio,
//         storage: SecureStorageService(),
//       ),
//     );
//   }

//    final Dio _dio;

//   Future<Response> auth(AuthReq req) async {
//     return _dio.post('${Constants.apiV1}/auth', data: req.toMap());
//   }

//   Future<Response> getBannerAds(BannerAdSize size) async {
//     return _dio.get(
//       '${Constants.apiV1}/banner_ad',
//       queryParameters: {'size': size.name},
//     );
//   }

//   Future<Response> view(String id) {
//     return _dio.patch('${Constants.apiV1}/banner_ad/view/$id');
//   }

//   Future<Response> click(String id) {
//     return _dio.patch('${Constants.apiV1}/banner_ad/click/$id');
//   }
// }

final class ApiService {
  // ApiService() : _dio = Dio() {
  //   _dio.interceptors.add(
  //     TokenInterceptor(
  //       dio: _dio,
  //       storage: SecureStorageService(),
  //     ),
  //   );
  // }
  ApiService._();
  static final ApiService _instance = ApiService._();

  static ApiService get instance => _instance;

  Dio? _dio;

  void _init() {
    if (_dio != null) return;
    _dio = Dio();
    _dio!.interceptors.add(
      TokenInterceptor(
        dio: _dio!,
        storage: SecureStorageService.instance,
      ),
    );
  }

  Future<Response> auth(AuthReq req) async {
    if (_dio == null) _init();

    return _dio!.post('${Constants.apiV1}/auth', data: req.toMap());
  }

  Future<Response> getBannerAds(BannerAdSize size) async {
    if (_dio == null) _init();

    return _dio!.get(
      '${Constants.apiV1}/banner_ad',
      queryParameters: {'size': size.name},
    );
  }

  Future<Response> view(String id) {
    if (_dio == null) _init();

    return _dio!.patch('${Constants.apiV1}/banner_ad/view/$id');
  }

  Future<Response> click(String id) {
    if (_dio == null) _init();

    return _dio!.patch('${Constants.apiV1}/banner_ad/click/$id');
  }
}
