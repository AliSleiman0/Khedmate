import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
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

  @override
  void initState() {
    super.initState();
    final booking = ref.read(bookingNotifierProvider).valueOrNull;
    if (booking?.latitude != null && booking?.longitude != null) {
      _center = LatLng(booking!.latitude!, booking.longitude!);
      _addressController.text = booking.address ?? '';
      _locationConfirmed = true;
    } else {
      // Auto-geocode the default Riyadh center so the Next button is enabled immediately
      WidgetsBinding.instance.addPostFrameCallback((_) => _reverseGeocode(_center));
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
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
      // leave address field empty for manual entry
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
                          setState(() {
                            _center = camera.center ?? _center;
                            _locationConfirmed = false;
                          });
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
