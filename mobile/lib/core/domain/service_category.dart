import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData;

import '../constants/category_icons.dart';

/// Snapshot of a service category as returned by `GET /api/categories`.
@immutable
class ServiceCategory {
  final String slug;
  final String nameEn;
  final String nameAr;
  final String iconKey;
  final String? iconUrl;
  final bool requiresSkillTest;

  const ServiceCategory({
    required this.slug,
    required this.nameEn,
    required this.nameAr,
    required this.iconKey,
    required this.iconUrl,
    required this.requiresSkillTest,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      slug: json['slug'] as String,
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'category',
      iconUrl: json['iconUrl'] as String?,
      requiresSkillTest: json['requiresSkillTest'] as bool? ?? true,
    );
  }

  String localizedName(Locale locale) =>
      locale.languageCode == 'ar' ? nameAr : nameEn;

  IconData get iconData => iconDataForKey(iconKey);
}
