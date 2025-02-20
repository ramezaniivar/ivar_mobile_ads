import 'package:ivar_mobile_ads/ivar_mobile_ads.dart';

import 'ivar_banner_ad.dart';
import 'repository.dart';

class IvarMobileAds {
  IvarMobileAds._();
  static final IvarMobileAds _instance = IvarMobileAds._();
  static IvarMobileAds get instance => _instance;
  final _repo = Repository.instance;

  Future<bool> init(String appID) => _repo.auth(appID);

  bool get isInit => _repo.isAuth;

  Future<IvarBannerAd?> loadBannerAds(BannerAdSize size) =>
      _repo.getBannerAds(size);
}
