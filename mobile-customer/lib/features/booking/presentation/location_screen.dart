import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';
import 'booking_provider.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _mapController = MapController();
  final _addressController = TextEditingController();

  LatLng _center = const LatLng(24.7136, 46.6753); // Riyadh default
  bool _locationConfirmed = false;
  bool _isGeocodingLoading = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    final booking = ref.read(bookingNotifierProvider).valueOrNull;
    if (booking?.latitude != null && booking?.longitude != null) {
      _center = LatLng(booking!.latitude!, booking.longitude!);
      _addressController.text = booking.address ?? '';
      _locationConfirmed = true;
    }
    _requestLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationDenied = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() => _locationDenied = true);
      return;
    }

    await _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 15);
      setState(() {
        _center = latLng;
        _locationConfirmed = false;
      });
      await _reverseGeocode(latLng);
    } catch (_) {
      // silently fail — user can drag pin manually
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'حدد موقع الخدمة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/booking/description'),
          ),
        ),
        body: Column(
          children: [
            // Map
            Expanded(
              flex: 3,
              child: _locationDenied
                  ? _ManualAddressEntry(controller: _addressController)
                  : Stack(
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
                            onMapReady: () {},
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
                            label: const Text(
                              'تأكيد الموقع',
                              style: TextStyle(fontFamily: 'Cairo'),
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

            // Bottom panel
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use current location button
                  if (!_locationDenied)
                    TextButton.icon(
                      onPressed: _goToCurrentLocation,
                      icon: const Icon(Icons.my_location,
                          color: AppColors.brandBlue),
                      label: const Text(
                        'استخدم موقعي الحالي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Address field
                  if (_isGeocodingLoading)
                    const LinearProgressIndicator(color: AppColors.brandBlue)
                  else
                    TextField(
                      controller: _addressController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: 'العنوان',
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

                  // Location denied explanation
                  if (_locationDenied)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Text(
                        'لم يتم منح إذن الموقع. يمكنك كتابة عنوانك يدوياً.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      ),
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
                                    _locationDenied ? 0 : _center.latitude,
                                    _locationDenied ? 0 : _center.longitude,
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
                      child: const Text(
                        'التالي',
                        style: TextStyle(
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
          ],
        ),
      ),
    );
  }
}

class _ManualAddressEntry extends StatelessWidget {
  final TextEditingController controller;

  const _ManualAddressEntry({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'أدخل عنوانك يدوياً',
            style: TextStyle(
                fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'مثال: حي النزهة، الرياض',
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}
