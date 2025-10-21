import 'package:flutter/material.dart';

import 'entity.dart';

enum InterstitialAdType {
  image,
  video,
  none,
}

InterstitialAdType _parseType(String? type) {
  if (type == null) return InterstitialAdType.none;

  try {
    return InterstitialAdType.values.byName(type);
  } catch (err, _) {
    return InterstitialAdType.none;
  }
}

BoxFit _parseBoxFit(String? data) {
  if (data == null) return BoxFit.contain;
  try {
    return BoxFit.values.byName(data);
  } catch (err, _) {
    return BoxFit.contain;
  }
}

sealed class InterstitialEntity extends Entity {
  const InterstitialEntity({
    required super.id,
    required this.link,
    required this.displayTime,
    required this.contentType,
    this.bgColor = Colors.white,
    this.imgBoxFit = BoxFit.contain,
    this.ctaBGColor,
    this.ctaTextColor,
  });

  final String link;
  final int displayTime;
  final InterstitialAdType contentType;
  final Color? ctaBGColor;
  final Color? ctaTextColor;

  ///image screen background color
  final Color bgColor;
  final BoxFit imgBoxFit;

  factory InterstitialEntity.fromJson(Map<String, dynamic> json) {
    final type = _parseType(json['type']);

    return switch (type) {
      InterstitialAdType.image => ImageInterstitialEntity.fromJson(json),
      InterstitialAdType.video => VideoInterstitialEntity.fromJson(json),
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
    required super.contentType,
    this.ctaText,
    super.ctaBGColor,
    super.ctaTextColor,
    super.bgColor,
    super.imgBoxFit,
  });

  String media;
  final String? ctaText;

  factory ImageInterstitialEntity.fromJson(Map<String, dynamic> json) =>
      ImageInterstitialEntity(
        id: json['_id'],
        link: json['link'],
        displayTime: json['displayTime'],
        media: json['mediaUrl'],
        ctaText: json['ctaText'],
        contentType: _parseType(json['type']),
        ctaBGColor:
            json['ctaBGColor'] == null ? null : Color(json['ctaBGColor']),
        ctaTextColor:
            json['ctaTextColor'] == null ? null : Color(json['ctaTextColor']),
        bgColor:
            json['bgColor'] == null ? Colors.white : Color(json['bgColor']),
        imgBoxFit: _parseBoxFit(json['imgBoxFit']),
      );
}

final class VideoInterstitialEntity extends InterstitialEntity {
  VideoInterstitialEntity({
    required super.id,
    required super.link,
    required super.displayTime,
    required super.contentType,
    required this.media,
    required this.poster,
    required this.ctaText,
    this.icon,
    super.ctaBGColor,
    super.ctaTextColor,
    super.bgColor,
    super.imgBoxFit,
  });

  final String media;
  String poster;
  final String ctaText;
  String? icon;

  factory VideoInterstitialEntity.fromJson(Map<String, dynamic> json) =>
      VideoInterstitialEntity(
        id: json['_id'],
        link: json['link'],
        displayTime: json['displayTime'],
        contentType: _parseType(json['type']),
        media: json['mediaUrl'],
        poster: json['posterUrl'],
        ctaText: json['ctaText'],
        icon: json['iconUrl'],
        ctaBGColor:
            json['ctaBGColor'] == null ? null : Color(json['ctaBGColor']),
        ctaTextColor:
            json['ctaTextColor'] == null ? null : Color(json['ctaTextColor']),
        bgColor:
            json['bgColor'] == null ? Colors.white : Color(json['bgColor']),
        imgBoxFit: _parseBoxFit(json['imgBoxFit']),
      );
}

final class UnsupportedInterstitialEntity extends InterstitialEntity {
  UnsupportedInterstitialEntity({
    required super.id,
    required super.link,
    required super.displayTime,
    required super.contentType,
  });

  factory UnsupportedInterstitialEntity.fromJson(Map<String, dynamic> json) =>
      UnsupportedInterstitialEntity(
        id: json['_id'],
        link: json['link'],
        displayTime: json['displayTime'],
        contentType: _parseType(json['type']),
      );
}
