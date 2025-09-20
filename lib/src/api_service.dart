import 'package:dio/dio.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/package_info_service.dart';
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
  final packageInfo = PackageInfoService.instance;

  Future<void> _init() async {
    if (_dio != null) return;
    _dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: 12),
      receiveTimeout: Duration(seconds: 12),
    ));
    _dio!.interceptors.add(
      TokenInterceptor(
        dio: _dio!,
        storage: SecureStorageService.instance,
      ),
    );

    //با هر درخواست نسخه پکیج رو میفرستیم تا سرور برای نسخه های مختلف پکیج در صورت نیاز عملیات متفاوت انجام بده
    _dio!.options.headers['x-app-version'] = await packageInfo.version;
  }

  Future<Response> auth(AuthReq req) async {
    if (_dio == null) await _init();

    return _dio!.post('${Constants.apiV1}/auth', data: req.toMap());
  }

  Future<Response> getBannerAds(BannerAdSize size) async {
    if (_dio == null) await _init();

    return _dio!.get(
      '${Constants.apiV1}/banner_ad',
      queryParameters: {'size': size.name},
    );
  }

  Future<Response> viewBanner(String id) async {
    if (_dio == null) await _init();

    return _dio!.patch('${Constants.apiV1}/banner_ad/view/$id');
  }

  Future<Response> clickBanner(String id) async {
    if (_dio == null) await _init();

    return _dio!.patch('${Constants.apiV1}/banner_ad/click/$id');
  }

  /// - - - - - - - - - - - INTERSTITIAL - - - - - - - - - - - - - -

  Future<Response> getInterstitialAd() async {
    if (_dio == null) await _init();

    return _dio!.get('${Constants.apiV1}/interstitial_ad');
  }

  Future<Response> viewInterstitial(String id) async {
    if (_dio == null) await _init();
    return _dio!.patch('${Constants.apiV1}/interstitial_ad/$id/view');
  }

  Future<Response> clickInterstitial(String id) async {
    if (_dio == null) await _init();
    return _dio!.patch('${Constants.apiV1}/interstitial_ad/$id/click');
  }

  Future<Response> downloadFile(String url, String savePath,
      {void Function(double value)? progress}) async {
    if (_dio == null) await _init();
    return _dio!.download('${Constants.baseUrl}/$url', savePath,
        onReceiveProgress: (count, total) {
      if (progress == null) return;
      progress(count / total);
    });
  }
}
