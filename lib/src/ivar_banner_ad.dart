import 'package:ivar_mobile_ads/ivar_mobile_ads.dart';

import 'entity/banner_entity.dart';

class IvarBannerAd {
  const IvarBannerAd({
    required this.size,
    required this.ad,
    required this.listener,
  });

  final BannerAdSize size;
  final BannerEntity ad;
  final IvarBannerAdListener listener;
}
