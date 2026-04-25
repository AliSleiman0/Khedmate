import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/redact.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../booking/data/booking_repository.dart';

const _tag = 'TrackingNotifier';

class JobTrackingState {
  final String jobId;
  final String status;
  final String referenceNumber;
  final String category;
  final String providerName;
  final double customerLatitude;
  final double customerLongitude;
  final double? providerLatitude;
  final double? providerLongitude;
  final double? distanceKm;
  final DateTime? lastLocationUpdate;

  const JobTrackingState({
    required this.jobId,
    required this.status,
    required this.referenceNumber,
    required this.category,
    required this.providerName,
    required this.customerLatitude,
    required this.customerLongitude,
    this.providerLatitude,
    this.providerLongitude,
    this.distanceKm,
    this.lastLocationUpdate,
  });

  JobTrackingState copyWith({
    String? status,
    double? providerLatitude,
    double? providerLongitude,
    double? distanceKm,
    DateTime? lastLocationUpdate,
  }) =>
      JobTrackingState(
        jobId: jobId,
        status: status ?? this.status,
        referenceNumber: referenceNumber,
        category: category,
        providerName: providerName,
        customerLatitude: customerLatitude,
        customerLongitude: customerLongitude,
        providerLatitude: providerLatitude ?? this.providerLatitude,
        providerLongitude: providerLongitude ?? this.providerLongitude,
        distanceKm: distanceKm ?? this.distanceKm,
        lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      );

  factory JobTrackingState.fromJson(Map<String, dynamic> json) =>
      JobTrackingState(
        jobId: (json['jobId'] ?? '').toString(),
        status: json['status'] as String? ?? 'Accepted',
        referenceNumber: json['referenceNumber'] as String? ?? '',
        category: json['category'] as String? ?? '',
        providerName: json['providerName'] as String? ?? '',
        customerLatitude:
            (json['customerLatitude'] as num?)?.toDouble() ?? 0.0,
        customerLongitude:
            (json['customerLongitude'] as num?)?.toDouble() ?? 0.0,
      );
}

class JobTrackingNotifier
    extends FamilyAsyncNotifier<JobTrackingState, String> {
  @override
  Future<JobTrackingState> build(String arg) async {
    log.d(_tag, 'build', data: {'jobId': arg});
    _subscribeToStatusChanges(arg);
    _subscribeToProviderLocation(arg);
    ref.onDispose(() => log.d(_tag, 'unsubscribed', data: {'jobId': arg}));
    final data = await ref.read(bookingRepositoryProvider).getJobStatus(arg);
    final initial = JobTrackingState.fromJson(data);
    log.i(_tag, 'initial status',
        data: {'jobId': arg, 'status': initial.status});
    return initial;
  }

  void _subscribeToStatusChanges(String jobId) {
    log.d(_tag, 'signalr subscribe',
        data: {'event': 'JobStatusChanged', 'jobId': jobId});
    ref.read(signalRServiceProvider).on('JobStatusChanged', (args) {
      final data = args?[0] as Map<String, dynamic>?;
      if (data == null) return;
      if (data['jobId'].toString() != jobId) return;
      final newStatus = data['status'] as String? ?? '';
      final current = state.valueOrNull;
      if (current != null) {
        log.i(_tag, 'status transition',
            data: {'jobId': jobId, 'from': current.status, 'to': newStatus});
        state = AsyncData(current.copyWith(status: newStatus));
      }
    });
  }

  void _subscribeToProviderLocation(String jobId) {
    log.d(_tag, 'signalr subscribe',
        data: {'event': 'ProviderLocationUpdated', 'jobId': jobId});
    ref.read(signalRServiceProvider).on('ProviderLocationUpdated', (args) {
      final data = args?[0] as Map<String, dynamic>?;
      if (data == null) return;
      if (data['jobId'].toString() != jobId) return;

      final newLat = (data['latitude'] as num?)?.toDouble();
      final newLng = (data['longitude'] as num?)?.toDouble();

      if (newLat == null || newLng == null) return;

      final current = state.valueOrNull;
      if (current != null) {
        final distance = calculateDistanceKm(
          current.customerLatitude,
          current.customerLongitude,
          newLat,
          newLng,
        );

        final ageMs = current.lastLocationUpdate == null
            ? null
            : DateTime.now()
                .difference(current.lastLocationUpdate!)
                .inMilliseconds;
        log.v(_tag, 'loc update', data: {
          'jobId': jobId,
          'coords': redactLatLng(newLat, newLng),
          'distanceKm': distance.toStringAsFixed(2),
          'ageMs': ageMs,
        });

        state = AsyncData(current.copyWith(
          providerLatitude: newLat,
          providerLongitude: newLng,
          distanceKm: distance,
          lastLocationUpdate: DateTime.now(),
        ));
      }
    });
  }

  Future<void> refresh(String jobId) async {
    log.d(_tag, 'refresh', data: {'jobId': jobId});
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data =
          await ref.read(bookingRepositoryProvider).getJobStatus(jobId);
      return JobTrackingState.fromJson(data);
    });
  }
}

final jobTrackingNotifierProvider = AsyncNotifierProviderFamily<
    JobTrackingNotifier, JobTrackingState, String>(JobTrackingNotifier.new);
