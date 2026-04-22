import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import 'booking_provider.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _mapController = MapController();
  final _addressController = TextEditingController();

  LatLng _center = const LatLng(33.8938, 35.5018); // Beirut default
  bool _locationConfirmed = false;
  bool _isGeocodingLoading = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final booking = ref.read(bookingNotifierProvider).valueOrNull;
    if (booking?.latitude != null && booking?.longitude != null) {
      _center = LatLng(booking!.latitude!, booking.longitude!);
      _addressController.text = booking.address ?? '';
      _locationConfirmed = true;
    } else {
      // Enable Next button immediately — user can always confirm position manually
      _locationConfirmed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reverseGeocode(_center));
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.read(ref).locPermissionDenied,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = latLng);
      _mapController.move(latLng, 16);
      await _reverseGeocode(latLng);
    } catch (_) {
      // silently ignore — user can drag pin manually
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocodingLoading = true);
    try {
      final placemarks = await placemarkFromCoordinates(
          latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .join('، ');
        _addressController.text = parts;
      }
    } catch (_) {
      // Fallback to coordinate string so the address field is not empty
      _addressController.text =
          '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
    } finally {
      setState(() {
        _isGeocodingLoading = false;
        _locationConfirmed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.locTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/booking/description'),
          ),
        ),
        body: Column(
          children: [
            // Map — takes upper 60% of screen
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 15,
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture) {
                          // No setState — rebuilding on every drag frame causes
                          // flutter_map to fight itself and freeze the map.
                          // _center is only read on button tap, so this is safe.
                          _center = camera.center ?? _center;
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.khudmati.customer',
                      ),
                    ],
                  ),
                  // Center pin
                  const IgnorePointer(
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 44,
                    ),
                  ),
                  // GPS — use my location button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'gps_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandBlue,
                      tooltip: s.locMyLocation,
                      onPressed: _isLocating ? null : _goToMyLocation,
                      child: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandBlue,
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                  // Confirm position button
                  Positioned(
                    bottom: 12,
                    child: ElevatedButton.icon(
                      onPressed: () => _reverseGeocode(_center),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        s.locConfirm,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom panel — scrollable to prevent overflow on small screens
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address field
                    if (_isGeocodingLoading)
                      const LinearProgressIndicator(color: AppColors.brandBlue)
                    else
                      TextField(
                        controller: _addressController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: s.locAddress,
                          labelStyle: const TextStyle(fontFamily: 'Cairo'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.brandBlue, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),

                    const SizedBox(height: 16),

                    // Next button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_locationConfirmed ||
                                _addressController.text.trim().isNotEmpty)
                            ? () {
                                ref
                                    .read(bookingNotifierProvider.notifier)
                                    .setLocation(
                                      _center.latitude,
                                      _center.longitude,
                                      _addressController.text.trim(),
                                    );
                                context.go('/booking/summary');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: Text(
                          s.next,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
