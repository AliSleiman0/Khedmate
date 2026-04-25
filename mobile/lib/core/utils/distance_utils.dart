import 'dart:math';

/// Calculate the distance in kilometers between two geographic coordinates
/// using the Haversine formula.
double calculateDistanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const R = 6371.0; // Earth radius in kilometers

  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

double _toRad(double degrees) {
  return degrees * pi / 180;
}
