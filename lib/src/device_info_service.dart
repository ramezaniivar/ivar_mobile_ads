import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:path_provider/path_provider.dart';

class DeviceInfoService {
  DeviceInfoService._();

  static final DeviceInfoService _instance = DeviceInfoService._();

  static DeviceInfoService get instance => _instance;

  final _deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo? _androidInfo;
  IosDeviceInfo? _iosInfo;

  Future<String> get id async {
    if (Platform.isAndroid) {
      _androidInfo ??= await _deviceInfo.androidInfo;
      return _androidInfo!.id;
    } else if (Platform.isIOS) {
      _iosInfo ??= await _deviceInfo.iosInfo;
      return _iosInfo!.identifierForVendor ??
          DateTime.now().microsecondsSinceEpoch.toString();
    } else {
      throw Exception('only support android and iPhone');
    }
  }

  Future<String> get model async {
    if (Platform.isAndroid) {
      _androidInfo ??= await _deviceInfo.androidInfo;
      return _androidInfo!.model;
    } else if (Platform.isIOS) {
      _iosInfo ??= await _deviceInfo.iosInfo;
      return _iosInfo!.model;
    } else {
      throw Exception('only support android and iPhone');
    }
  }

  Future<String> get apiLevel async {
    if (Platform.isAndroid) {
      _androidInfo ??= await _deviceInfo.androidInfo;
      return _androidInfo!.version.release;
    } else if (Platform.isIOS) {
      _iosInfo ??= await _deviceInfo.iosInfo;
      return _iosInfo!.systemVersion;
    } else {
      throw Exception('only support android and iPhone');
    }
  }

  ///get device time zone for example "Asia/Tehran"
  Future<String> get timeZone => FlutterTimezone.getLocalTimezone();

  String get languageCode => Platform.localeName.split('_').first;
  IvarDevice get platform => Platform.isAndroid
      ? IvarDevice.android
      : Platform.isIOS
          ? IvarDevice.iPhone
          : throw Exception('device not supported');

  Future<Directory> get appDocumentsDir => getApplicationDocumentsDirectory();
}
