import 'package:ivar_mobile_ads/ivar_mobile_ads.dart';

import 'entity/banner_entity.dart';

class IvarBannerAd {
  const IvarBannerAd({
    required this.size,
    required this.ads,
  });

  final BannerAdSize size;
  final List<BannerEntity> ads;
}
