import 'package:flutter/material.dart';

/// Curated Material-icon keys exposed in the admin Category dropdown.
///
/// IMPORTANT — keep this map in lockstep with
///   web-admin/src/constants/categoryIcons.ts
/// Adding a new key on the admin side without adding it here renders the
/// fallback [Icons.category] glyph.
const Map<String, IconData> kCategoryIconMap = {
  'plumbing': Icons.plumbing,
  'electric_bolt': Icons.electric_bolt,
  'cleaning_services': Icons.cleaning_services,
  'handyman': Icons.handyman,
  'format_paint': Icons.format_paint,
  'ac_unit': Icons.ac_unit,
  'build': Icons.build,
  'home_repair_service': Icons.home_repair_service,
  'local_laundry_service': Icons.local_laundry_service,
  'pest_control': Icons.pest_control,
  'grass': Icons.grass,
  'key': Icons.key,
  'lock': Icons.lock,
  'power': Icons.power,
  'directions_car': Icons.directions_car,
  'local_shipping': Icons.local_shipping,
  'kitchen': Icons.kitchen,
  'bed': Icons.bed,
  'air': Icons.air,
  'water_drop': Icons.water_drop,
  'wb_sunny': Icons.wb_sunny,
  'roofing': Icons.roofing,
  'window': Icons.window,
  'tv': Icons.tv,
  'router': Icons.router,
  'category': Icons.category,
};

const IconData kCategoryFallbackIcon = Icons.category;

IconData iconDataForKey(String? key) =>
    kCategoryIconMap[key] ?? kCategoryFallbackIcon;
