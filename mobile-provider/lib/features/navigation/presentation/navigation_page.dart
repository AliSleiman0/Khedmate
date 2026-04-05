import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';

class NavigationPage extends StatefulWidget {
  final String jobId;
  const NavigationPage({super.key, required this.jobId});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  String _status = 'في الطريق';

  void _updateStatus() {
    final transitions = {
      'في الطريق': 'بدأت العمل',
      'بدأت العمل': 'انتهيت من العمل',
      'انتهيت من العمل': 'مكتمل',
    };
    if (transitions.containsKey(_status)) {
      setState(() => _status = transitions[_status]!);
      if (_status == 'مكتمل') {
        Future.delayed(const Duration(seconds: 1),
            () => context.go('/jobs'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('طلب #${widget.jobId}')),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(24.7200, 46.6800),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.khudmati.provider',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: const LatLng(24.7136, 46.6753),
                  child: const Icon(Icons.location_on,
                      color: AppColors.amber, size: 40),
                ),
                Marker(
                  point: const LatLng(24.7200, 46.6800),
                  child: const Icon(Icons.my_location,
                      color: AppColors.brandBlue, size: 36),
                ),
              ]),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('حي النزهة، الرياض',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  if (_status != 'مكتمل')
                    ElevatedButton(
                      onPressed: _updateStatus,
                      child: Text(
                        _status == 'في الطريق'
                            ? 'وصلت — بدء العمل'
                            : 'إنهاء العمل',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
