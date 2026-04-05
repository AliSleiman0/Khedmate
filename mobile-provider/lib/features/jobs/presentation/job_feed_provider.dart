import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/job_repository.dart';
import '../../../core/services/signalr_service.dart';

class JobFeedNotifier extends AsyncNotifier<List<JobSummary>> {
  @override
  Future<List<JobSummary>> build() async {
    await _connectSignalR();
    _subscribeToNewJobs();
    await _updateLocation();
    return ref.read(jobRepositoryProvider).getAvailableJobs();
  }

  Future<void> _connectSignalR() async {
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (_) {
      // Non-fatal — feed still loads via HTTP
    }
  }

  void _subscribeToNewJobs() {
    ref.read(signalRServiceProvider).on('NewJobAvailable', (args) {
      if (args == null || args.isEmpty) return;
      try {
        final data = args[0] as Map<String, dynamic>;
        final newJob = JobSummary.fromJson(data);
        final current = state.valueOrNull ?? [];
        // Avoid duplicates
        if (current.any((j) => j.id == newJob.id)) return;
        state = AsyncValue.data([newJob, ...current]);
      } catch (_) {}
    });
  }

  Future<void> _updateLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      await ref.read(jobRepositoryProvider).updateLocation(
            pos.latitude,
            pos.longitude,
          );
    } catch (_) {
      // Location not available — continue without it
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await _updateLocation();
      final jobs = await ref.read(jobRepositoryProvider).getAvailableJobs();
      state = AsyncValue.data(jobs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void removeJob(String jobId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((j) => j.id != jobId).toList());
  }
}

final jobFeedNotifierProvider =
    AsyncNotifierProvider<JobFeedNotifier, List<JobSummary>>(JobFeedNotifier.new);
