/**
 * Curated Material-icon keys exposed in the admin Category dropdown.
 *
 * IMPORTANT — keep this list in lockstep with
 *   mobile/lib/core/constants/category_icons.dart
 * Adding a new key here without adding it to the mobile map renders the
 * fallback `category` icon on phones.
 */
export const CATEGORY_ICON_KEYS = [
  'plumbing',
  'electric_bolt',
  'cleaning_services',
  'handyman',
  'format_paint',
  'ac_unit',
  'build',
  'home_repair_service',
  'local_laundry_service',
  'pest_control',
  'grass',
  'key',
  'lock',
  'power',
  'directions_car',
  'local_shipping',
  'kitchen',
  'bed',
  'air',
  'water_drop',
  'wb_sunny',
  'roofing',
  'window',
  'tv',
  'router',
  'category',
] as const

export type CategoryIconKey = (typeof CATEGORY_ICON_KEYS)[number]

export const DEFAULT_CATEGORY_ICON: CategoryIconKey = 'category'
