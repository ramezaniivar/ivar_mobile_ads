import 'entity.dart';

enum InterstitialAdType {
  image,
  none,
}

InterstitialAdType _parseType(String? type) {
  if (type == null) return InterstitialAdType.none;

  try {
    return InterstitialAdType.values.byName(type);
  } catch (err) {
    return InterstitialAdType.none;
  }
}

sealed class InterstitialEntity extends Entity {
  const InterstitialEntity({
    required super.id,
    required this.link,
    required this.displayTime,
  });

  final String link;
  final int displayTime;

  factory InterstitialEntity.fromJson(Map<String, dynamic> json) {
    final type = _parseType(json['type']);

    return switch (type) {
      InterstitialAdType.image => ImageInterstitialEntity.fromJson(json),
      InterstitialAdType.none => UnsupportedInterstitialEntity.fromJson(json),
    };
  }
}

final class ImageInterstitialEntity extends InterstitialEntity {
  ImageInterstitialEntity({
    required super.id,
    required super.link,
    required super.displayTime,
    required this.media,
    this.ctaText,
  });

  String media;
  final String? ctaText;

  factory ImageInterstitialEntity.fromJson(Map<String, dynamic> json) =>
      ImageInterstitialEntity(
          id: json['_id'],
          link: json['link'],
          displayTime: json['displayTime'],
          media: json['mediaUrl'],
          ctaText: json['ctaText']);
}

final class UnsupportedInterstitialEntity extends InterstitialEntity {
  UnsupportedInterstitialEntity(
      {required super.id,
      required super.link,
      required super.displayTime,
      this.type});

  final String? type;

  factory UnsupportedInterstitialEntity.fromJson(Map<String, dynamic> json) =>
      UnsupportedInterstitialEntity(
        id: json['_id'],
        link: json['link'],
        displayTime: json['displayTime'],
        type: json['type'],
      );
}
