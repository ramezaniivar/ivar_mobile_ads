import '../core/constants.dart';
import 'entity.dart';

List<BannerEntity> bannerEntityFromJson(dynamic data) =>
    List<BannerEntity>.from(data.map((x) => BannerEntity.fromJson(x)));

sealed class BannerEntity extends Entity {
  const BannerEntity({
    required super.id,
    required this.link,
    required this.priority,
    required this.type,
    required this.platform,
    this.language,
  });

  final String link;
  final int priority;
  final AdType type;
  final AdPlatform platform;
  final String? language;

  factory BannerEntity.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'textual':
        return TextualBannerEntity.fromJson(json);
      case 'image':
        return ImageBannerEntity.fromJson(json);
      default:
        throw ArgumentError('Invalid content type: ${json['type']}');
    }
  }
}

final class TextualBannerEntity extends BannerEntity {
  const TextualBannerEntity({
    required super.id,
    required super.link,
    required super.priority,
    required super.type,
    required super.platform,
    required this.title,
    super.language,
    this.icon,
    this.description,
    this.callToAction,
  });

  final String title;
  final String? icon;
  final String? description;
  final String? callToAction;

  factory TextualBannerEntity.fromJson(Map<String, dynamic> json) =>
      TextualBannerEntity(
        id: json['id'],
        link: json['link'],
        priority: json['priority'],
        type: AdType.values.byName(json['type']),
        platform: AdPlatform.values.byName(json['platform'] ?? 'none'),
        title: json['title'],
        language: json['language'],
        icon: json['icon'],
        description: json['description'],
        callToAction: json['callToAction'],
      );
}

final class ImageBannerEntity extends BannerEntity {
  const ImageBannerEntity({
    required super.id,
    required super.link,
    required super.priority,
    required super.type,
    required super.platform,
    required this.image,
    super.language,
  });

  final String image;

  factory ImageBannerEntity.fromJson(Map<String, dynamic> json) =>
      ImageBannerEntity(
        id: json['id'],
        link: json['link'],
        priority: json['priority'],
        type: AdType.values.byName(json['type']),
        platform: AdPlatform.values.byName(json['platform'] ?? 'none'),
        image: json['image'],
        language: json['language'],
      );
}
