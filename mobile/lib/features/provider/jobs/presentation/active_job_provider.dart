import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/signalr_service.dart';
import '../data/job_repository.dart';

class ActiveJobNotifier extends FamilyAsyncNotifier<JobDetail, String> {
  Timer? _locationTimer;

  @override
  Future<JobDetail> build(String arg) async {
    ref.onDispose(() {
      _stopLocationBroadcast();
    });
    _subscribeToStatusChanges(arg);
    final job = await ref.read(jobRepositoryProvider).getJobById(arg);
    if (job.status == 'EnRoute') {
      _startLocationBroadcast(arg);
    }
    return job;
  }

  void _subscribeToStatusChanges(String jobId) {
    ref.read(signalRServiceProvider).on('JobStatusChanged', (args) {
      final data = args?[0] as Map<String, dynamic>?;
      if (data == null) return;
      if (data['jobId'].toString() != jobId) return;
      final newStatus = data['status'] as String? ?? '';
      final current = state.valueOrNull;
      if (current != null) {
        final previousStatus = current.status;
        state = AsyncData(current.copyWith(status: newStatus));

        if (newStatus == 'EnRoute' && previousStatus != 'EnRoute') {
          _startLocationBroadcast(jobId);
        } else if (previousStatus == 'EnRoute' && newStatus != 'EnRoute') {
          _stopLocationBroadcast();
        }
      }
    });
  }

  void _startLocationBroadcast(String jobId) {
    _stopLocationBroadcast();
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }

        if (permission == LocationPermission.deniedForever) return;

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await ref.read(jobRepositoryProvider).sendLocationForJob(
              jobId,
              position.latitude,
              position.longitude,
            );
      } catch (_) {
        // Silent — broadcast is non-critical
      }
    });
  }

  void _stopLocationBroadcast() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> advanceStatus() async {
    final job = state.valueOrNull;
    if (job == null) return;
    final previousStatus = job.status;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).advanceJobStatus(job.id),
    );
    state = result;

    final newJob = result.valueOrNull;
    if (newJob != null) {
      if (newJob.status == 'EnRoute' && previousStatus != 'EnRoute') {
        _startLocationBroadcast(job.id);
      } else if (previousStatus == 'EnRoute' && newJob.status != 'EnRoute') {
        _stopLocationBroadcast();
      }
    }
  }
}

final activeJobNotifierProvider =
    AsyncNotifierProviderFamily<ActiveJobNotifier, JobDetail, String>(
        ActiveJobNotifier.new);
