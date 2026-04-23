import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../shared/chat/presentation/chat_provider.dart';
import '../../../shared/rating/presentation/rating_bottom_sheet.dart';
import 'job_tracking_provider.dart';

class TrackingPage extends ConsumerStatefulWidget {
  final String jobId;

  const TrackingPage({super.key, required this.jobId});

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  @override
  void initState() {
    super.initState();
    _ensureSignalR();
  }

  Future<void> _ensureSignalR() async {
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final asyncTracking =
        ref.watch(jobTrackingNotifierProvider(widget.jobId));

    final tracking = asyncTracking.valueOrNull;
    final chatStatuses = {'Accepted', 'EnRoute', 'InProgress'};
    final showChat =
        tracking != null && chatStatuses.contains(tracking.status);

    Widget? chatFab;
    if (showChat) {
      final unreadAsync = ref.watch(unreadCountProvider(widget.jobId));
      final unreadCount = unreadAsync.valueOrNull ?? 0;
      chatFab = FloatingActionButton(
        backgroundColor: AppColors.brandBlue,
        onPressed: () => context.push(
          '/customer/chat/${widget.jobId}?name=${Uri.encodeComponent(tracking.providerName)}',
        ),
        child: Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble, color: Colors.white),
            if (unreadCount > 0)
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        floatingActionButton: chatFab,
        body: asyncTracking.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (_, __) => _ErrorView(
              onRetry: () => ref
                  .read(jobTrackingNotifierProvider(widget.jobId).notifier)
                  .refresh(widget.jobId)),
          data: (tracking) => _TrackingBody(
            tracking: tracking,
            onRefresh: () => ref
                .read(jobTrackingNotifierProvider(widget.jobId).notifier)
                .refresh(widget.jobId),
          ),
        ),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  final JobTrackingState tracking;
  final Future<void> Function() onRefresh;

  const _TrackingBody({required this.tracking, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                _StatusBanner(status: tracking.status),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RefBadge(referenceNumber: tracking.referenceNumber),
                        const SizedBox(height: 16),
                        _ProviderCard(
                          providerName: tracking.providerName,
                          category: tracking.category,
                        ),
                        const SizedBox(height: 20),
                        _StatusDetail(tracking: tracking),
                        const Spacer(),
                        _BottomActions(
                          status: tracking.status,
                          jobId: tracking.jobId,
                          providerName: tracking.providerName,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends ConsumerWidget {
  final String status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(status),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
        color: _bannerColor(status),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _bannerText(status, s),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _bannerSubtitle(status, s),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _bannerColor(String status) => switch (status) {
        'Accepted'   => AppColors.brandBlue,
        'EnRoute'    => const Color(0xFFB7770D),
        'InProgress' => AppColors.amber,
        'Completed'  => Colors.green.shade700,
        'Paid'       => Colors.green.shade800,
        _            => AppColors.brandBlue,
      };

  String _bannerText(String status, S s) => switch (status) {
        'Accepted'   => s.trackAccepted,
        'EnRoute'    => s.trackEnRoute,
        'InProgress' => s.trackInProgress,
        'Completed'  => s.trackCompleted,
        'Paid'       => s.trackPaid,
        _            => s.trackDefault,
      };

  String _bannerSubtitle(String status, S s) => switch (status) {
        'Accepted'   => s.trackAcceptedSub,
        'EnRoute'    => s.trackEnRouteSub,
        'InProgress' => s.trackInProgSub,
        'Completed'  => s.trackCompletedSub,
        'Paid'       => s.trackPaidSub,
        _            => '',
      };
}

class _RefBadge extends ConsumerWidget {
  final String referenceNumber;

  const _RefBadge({required this.referenceNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(s.trackOrderNo,
              style: const TextStyle(
                  fontFamily: 'Cairo', color: AppColors.textSecondary)),
          Text(referenceNumber,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.brandBlue,
                letterSpacing: 1.2,
              )),
        ],
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final String providerName;
  final String category;

  const _ProviderCard({required this.providerName, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.brandBlue,
              child: Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName.isNotEmpty ? providerName : s.trackProvider,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDetail extends StatelessWidget {
  final JobTrackingState tracking;

  const _StatusDetail({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return switch (tracking.status) {
      'Accepted' => _PulseIndicator(),
      'EnRoute' => _LiveTrackingMap(tracking: tracking),
      'InProgress' => _InProgressMap(tracking: tracking),
      _ => const SizedBox.shrink(),
    };
  }
}

class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _anim,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_car,
              color: AppColors.brandBlue, size: 32),
        ),
      ),
    );
  }
}

class _LiveTrackingMap extends ConsumerStatefulWidget {
  final JobTrackingState tracking;

  const _LiveTrackingMap({required this.tracking});

  @override
  ConsumerState<_LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<_LiveTrackingMap>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  LatLng? _animatedProviderPosition;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;
  AnimationController? _animController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didUpdateWidget(_LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tracking.providerLatitude != null &&
        widget.tracking.providerLongitude != null) {
      final newPos = LatLng(
        widget.tracking.providerLatitude!,
        widget.tracking.providerLongitude!,
      );

      if (_animatedProviderPosition == null) {
        setState(() {
          _animatedProviderPosition = newPos;
        });
        _fitBounds();
      } else if (_animatedProviderPosition != newPos) {
        _animateToNewPosition(newPos);
      }
    }
  }

  void _animateToNewPosition(LatLng newPos) {
    final oldPos = _animatedProviderPosition!;

    _latAnimation = Tween<double>(
      begin: oldPos.latitude,
      end: newPos.latitude,
    ).animate(CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeInOut,
    ));

    _lngAnimation = Tween<double>(
      begin: oldPos.longitude,
      end: newPos.longitude,
    ).animate(CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeInOut,
    ));

    _animController!.addListener(() {
      if (_latAnimation != null && _lngAnimation != null) {
        setState(() {
          _animatedProviderPosition = LatLng(
            _latAnimation!.value,
            _lngAnimation!.value,
          );
        });
      }
    });

    _animController!.forward(from: 0);
  }

  void _fitBounds() {
    if (_animatedProviderPosition == null) return;

    final customerPos = LatLng(
      widget.tracking.customerLatitude,
      widget.tracking.customerLongitude,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = LatLngBounds.fromPoints([
        customerPos,
        _animatedProviderPosition!,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final customerPos = LatLng(
      widget.tracking.customerLatitude,
      widget.tracking.customerLongitude,
    );

    final isLocationStale = widget.tracking.lastLocationUpdate != null &&
        DateTime.now().difference(widget.tracking.lastLocationUpdate!) >
            const Duration(seconds: 15);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 320,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: customerPos,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.khudmati.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: customerPos,
                          width: 80,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  s.trackYourLocation,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: AppColors.brandBlue,
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                        if (_animatedProviderPosition != null)
                          Marker(
                            point: _animatedProviderPosition!,
                            width: 80,
                            height: 80,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.tracking.providerName
                                        .split(' ')
                                        .first,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.directions_car,
                                  color: AppColors.amber,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isLocationStale)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.trackLocationUpdating,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.tracking.distanceKm != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFB7770D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.social_distance,
                    color: Color(0xFFB7770D), size: 20),
                const SizedBox(width: 8),
                Text(
                  s.trackDistanceLeft(
                      widget.tracking.distanceKm!.toStringAsFixed(1)),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFFB7770D),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InProgressMap extends ConsumerWidget {
  final JobTrackingState tracking;

  const _InProgressMap({required this.tracking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    if (tracking.providerLatitude == null ||
        tracking.providerLongitude == null) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.construction, color: AppColors.amber, size: 22),
            const SizedBox(width: 10),
            Text(
              s.trackProviderWorking,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final providerPos = LatLng(
      tracking.providerLatitude!,
      tracking.providerLongitude!,
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: providerPos,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.khudmati.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: providerPos,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.amber,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.amber, size: 22),
              const SizedBox(width: 10),
              Text(
                s.trackProviderArrived,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final String status;
  final String jobId;
  final String providerName;

  const _BottomActions({
    required this.status,
    required this.jobId,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    if (status == 'Paid') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => RatingBottomSheet.show(
              context,
              jobId: jobId,
              otherPartyName: providerName,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.trackRateExperience,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/customer/home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(color: AppColors.brandBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.backHome,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 17)),
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: () => context.go('/customer/home'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandBlue,
        side: const BorderSide(color: AppColors.brandBlue),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(s.backHome,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 17)),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(s.trackLoadError,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue),
              child: Text(s.retry,
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
