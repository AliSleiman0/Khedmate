import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../jobs/presentation/active_job_provider.dart';

class NavigationPage extends ConsumerStatefulWidget {
  final String jobId;
  const NavigationPage({super.key, required this.jobId});

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage> {
  LatLng? _providerLocation;

  @override
  void initState() {
    super.initState();
    _fetchProviderLocation();
  }

  Future<void> _fetchProviderLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(
            () => _providerLocation = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  Future<void> _advanceStatus() async {
    final job =
        ref.read(activeJobNotifierProvider(widget.jobId)).valueOrNull;
    if (job == null) return;

    if (job.status == 'InProgress') {
      if (mounted) {
        context.push('/provider/active-job/${widget.jobId}/after-photos');
      }
      return;
    }

    await ref
        .read(activeJobNotifierProvider(widget.jobId).notifier)
        .advanceStatus();

    final updated =
        ref.read(activeJobNotifierProvider(widget.jobId)).valueOrNull;
    if (updated != null &&
        (updated.status == 'Completed' || updated.status == 'Paid')) {
      if (mounted) context.go('/provider/jobs');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final asyncJob = ref.watch(activeJobNotifierProvider(widget.jobId));

    return asyncJob.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(s.navPageTitle)),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.brandBlue)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(s.navPageTitle)),
        body: Center(child: Text(s.jobLoadError)),
      ),
      data: (job) {
        final customerPin = LatLng(job.latitude, job.longitude);
        final mapCenter = _providerLocation ?? customerPin;

        final statusLabel = {
              'EnRoute': s.navPageEnRoute,
              'InProgress': s.navPageStarted,
              'Completed': s.navPageDone,
              'Paid': s.navPageDone,
            }[job.status] ??
            job.status;

        final buttonLabel =
            job.status == 'EnRoute' ? s.navPageArrive : s.jobFinish;
        final showButton =
            job.status == 'EnRoute' || job.status == 'InProgress';

        return Scaffold(
          appBar: AppBar(title: Text('${s.navPageTitle} #${widget.jobId}')),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.khudmati.app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: customerPin,
                      child: const Icon(Icons.location_on,
                          color: AppColors.amber, size: 40),
                    ),
                    if (_providerLocation != null)
                      Marker(
                        point: _providerLocation!,
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
                        statusLabel,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.district,
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      if (showButton)
                        ElevatedButton(
                          onPressed:
                              asyncJob.isLoading ? null : _advanceStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            buttonLabel,
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
      },
    );
  }
}
