import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/signalr_service.dart';
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
    // If job is already EnRoute, start broadcasting
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
        
        // Start location broadcast when transitioning to EnRoute
        if (newStatus == 'EnRoute' && previousStatus != 'EnRoute') {
          _startLocationBroadcast(jobId);
        }
        // Stop location broadcast when leaving EnRoute status
        else if (previousStatus == 'EnRoute' && newStatus != 'EnRoute') {
          _stopLocationBroadcast();
        }
      }
    });
  }

  void _startLocationBroadcast(String jobId) {
    _stopLocationBroadcast(); // Ensure no duplicate timers
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        // Check location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            // Permission denied - stop broadcasting
            return;
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          // Permission denied forever - stop broadcasting
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        await ref.read(jobRepositoryProvider).sendLocationForJob(
          jobId,
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        // Silently fail - location broadcast is not critical to job flow
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
    
    // Handle location broadcast based on new status
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
