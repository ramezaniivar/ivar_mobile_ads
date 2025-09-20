import 'package:package_info_plus/package_info_plus.dart';

final class PackageInfoService {
  PackageInfoService._();
  static final PackageInfoService _instance = PackageInfoService._();
  static PackageInfoService get instance => _instance;

  PackageInfo? _packageInfo;

  Future<void> _init() async => _packageInfo = await PackageInfo.fromPlatform();

  Future<String> get version async {
    if (_packageInfo == null) await _init();
    return _packageInfo!.version;
  }
}
