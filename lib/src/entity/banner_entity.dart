import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'entity.dart';

List<BannerEntity> bannerEntityFromJson(dynamic data) =>
    List<BannerEntity>.from(data.map((x) => BannerEntity.fromJson(x)));

sealed class BannerEntity extends Entity {
  const BannerEntity({
    required super.id,
    required this.link,
    required this.type,
    required this.refreshRate,
    this.language,
  });

  final String link;
  final AdType type;
  final int refreshRate;
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
  TextualBannerEntity({
    required super.id,
    required super.link,
    required super.type,
    required super.refreshRate,
    required this.title,
    required this.bgColor,
    required this.txtColor,
    super.language,
    this.icon,
    this.description,
    this.callToAction,
  });

  final String title;
  final List<Color> bgColor;
  final Color txtColor;
  String? icon;
  final String? description;
  final String? callToAction;

  factory TextualBannerEntity.fromJson(Map<String, dynamic> json) =>
      TextualBannerEntity(
        id: json['_id'],
        link: json['link'],
        type: AdType.values.byName(json['type']),
        refreshRate: json['refreshRate'],
        title: json['title'],
        language: json['language'],
        icon: json['icon'],
        description: json['description'],
        callToAction: json['callToAction'],
        bgColor: json['bgColor'] == null
            ? [const Color(0xffffffff), const Color(0xffefefef)]
            : (json['bgColor'] as List)
                .map((c) => Color((c as num).toInt()))
                .toList(),
        txtColor: json['txtColor'] == null
            ? Color(0xff333333)
            : Color(json['txtColor']),
      );
}

final class ImageBannerEntity extends BannerEntity {
  ImageBannerEntity({
    required super.id,
    required super.link,
    required super.type,
    required super.refreshRate,
    required this.image,
    super.language,
  });

  String image;

  factory ImageBannerEntity.fromJson(Map<String, dynamic> json) =>
      ImageBannerEntity(
        id: json['_id'],
        link: json['link'],
        type: AdType.values.byName(json['type']),
        refreshRate: json['refreshRate'],
        image: json['image'],
        language: json['language'],
      );
}
