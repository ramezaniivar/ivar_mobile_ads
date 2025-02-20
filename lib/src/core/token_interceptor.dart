import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'check_internet.dart';
import 'constants.dart';
import '../secure_storage_service.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({required this.dio, required this.storage});

  final Dio dio;
  final SecureStorageService storage;
  Future<void>? _refreshTokenFuture;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final isConnected = await checkInternet();
      if (!isConnected) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'internet connection',
            type: DioExceptionType.unknown,
            message: 'check internet',
          ),
        );
      }

      final accessToken = await storage.getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      return handler.next(options);
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        // Use a single refresh token request for multiple 401 errors
        _refreshTokenFuture ??= _refreshToken();

        // Wait for the refresh token request to complete
        await _refreshTokenFuture;

        // Clear the future so the next 401 error will trigger a new refresh
        _refreshTokenFuture = null;

        // Get the new token
        final newAccessToken = await storage.getAccessToken();
        if (newAccessToken == null) {
          return handler.reject(err);
        }

        // Retry the original request with the new token
        final response =
            await _retryRequest(err.requestOptions, newAccessToken);
        return handler.resolve(response);
      } catch (e) {
        // Clear the future in case of error
        _refreshTokenFuture = null;
        log('Token refresh failed: $e');
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }

  Future<void> _refreshToken() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'No refresh token available',
      );
    }

    final response = await dio.post(
      '${Constants.apiV1}/auth/refresh',
      data: {
        'token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      await storage.saveAccessToken(newAccessToken);
      await storage.saveRefreshToken(newRefreshToken);

      log('Token refreshed successfully');
    } else {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Failed to refresh token',
      );
    }
  }

  Future<Response<dynamic>> _retryRequest(
      RequestOptions requestOptions, String newToken) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newToken',
      },
    );

    return await dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
