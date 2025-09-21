import 'package:ivar_mobile_ads/ivar_mobile_ads.dart';

import 'entity/banner_entity.dart';

class IvarBannerAd {
  const IvarBannerAd({
    required this.size,
    required this.ad,
  });

  final BannerAdSize size;
  final BannerEntity ad;
}
