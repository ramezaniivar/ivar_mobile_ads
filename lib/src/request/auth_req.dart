import 'package:ivar_mobile_ads/src/core/constants.dart';
import 'package:ivar_mobile_ads/src/request/request.dart';

final class AuthReq extends Request {
  const AuthReq({
    required this.appId,
    required this.deviceId,
    required this.language,
    required this.timeZone,
    this.platform,
    this.deviceModel,
    this.deviceApiLevel,
  });

  final String appId;
  final String deviceId;
  final String language;
  final String timeZone;
  final IvarDevice? platform;
  final String? deviceModel;
  final String? deviceApiLevel;

  @override
  Map<String, dynamic> toMap() => {
        'appId': appId,
        'deviceId': deviceId,
        'language': language,
        'timeZone': timeZone,
        if (platform != null) 'platform': platform!.name,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (deviceApiLevel != null) 'deviceApiLevel': deviceApiLevel,
      };
}
