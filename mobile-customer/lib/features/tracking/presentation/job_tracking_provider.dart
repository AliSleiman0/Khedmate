import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/signalr_service.dart';
import '../../../core/utils/distance_utils.dart';
import '../../booking/presentation/booking_provider.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
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
        customerLatitude: (json['customerLatitude'] as num?)?.toDouble() ?? 0.0,
        customerLongitude: (json['customerLongitude'] as num?)?.toDouble() ?? 0.0,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class JobTrackingNotifier extends FamilyAsyncNotifier<JobTrackingState, String> {
  @override
  Future<JobTrackingState> build(String arg) async {
    _subscribeToStatusChanges(arg);
    _subscribeToProviderLocation(arg);
    final data = await ref.read(bookingRepositoryProvider).getJobStatus(arg);
    return JobTrackingState.fromJson(data);
  }

  void _subscribeToStatusChanges(String jobId) {
    ref.read(signalRServiceProvider).on('JobStatusChanged', (args) {
      final data = args?[0] as Map<String, dynamic>?;
      if (data == null) return;
      if (data['jobId'].toString() != jobId) return;
      final newStatus = data['status'] as String? ?? '';
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(status: newStatus));
      }
    });
  }

  void _subscribeToProviderLocation(String jobId) {
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref.read(bookingRepositoryProvider).getJobStatus(jobId);
      return JobTrackingState.fromJson(data);
    });
  }
}

final jobTrackingNotifierProvider =
    AsyncNotifierProviderFamily<JobTrackingNotifier, JobTrackingState, String>(
        JobTrackingNotifier.new);
