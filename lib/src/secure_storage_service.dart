import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService _instance = SecureStorageService._();

  static SecureStorageService get instance => _instance;

  final _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final _accessTokenKey = 'accessToken';
  final _refreshTokenKey = 'refreshToken';

  ///get
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  ///set
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  ///delete
  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);
  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshTokenKey);
}
