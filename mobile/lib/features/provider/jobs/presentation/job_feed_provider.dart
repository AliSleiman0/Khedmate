import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/redact.dart';
import '../../../../core/services/signalr_service.dart';
import '../data/job_repository.dart';

const _tag = 'JobFeedNotifier';

class JobFeedNotifier extends AsyncNotifier<List<JobSummary>> {
  @override
  Future<List<JobSummary>> build() async {
    log.d(_tag, 'build');
    await _connectSignalR();
    _subscribeToNewJobs();
    await _updateLocation();
    return ref.read(jobRepositoryProvider).getAvailableJobs();
  }

  Future<void> _connectSignalR() async {
    try {
      await ref.read(signalRServiceProvider).connect();
    } catch (e) {
      // Non-fatal — feed still loads via HTTP
      log.w(_tag, 'signalr connect failed', error: e);
    }
  }

  void _subscribeToNewJobs() {
    log.d(_tag, 'signalr subscribe', data: {'event': 'NewJobAvailable'});
    ref.read(signalRServiceProvider).on('NewJobAvailable', (args) {
      if (args == null || args.isEmpty) return;
      try {
        final data = args[0] as Map<String, dynamic>;
        final newJob = JobSummary.fromJson(data);
        final current = state.valueOrNull ?? [];
        if (current.any((j) => j.id == newJob.id)) {
          log.d(_tag, 'signalr msg duplicate', data: {'jobId': newJob.id});
          return;
        }
        log.i(_tag, 'signalr new job',
            data: {'jobId': newJob.id, 'category': newJob.categoryId});
        state = AsyncValue.data([newJob, ...current]);
      } catch (e) {
        log.w(_tag, 'NewJobAvailable parse failed', error: e);
      }
    });
  }

  Future<void> _updateLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        log.w(_tag, 'location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      log.v(_tag, 'location update',
          data: {'coords': redactLatLng(pos.latitude, pos.longitude)});
      await ref.read(jobRepositoryProvider).updateLocation(
            pos.latitude,
            pos.longitude,
          );
    } catch (e) {
      // Location not available — continue without it
      log.w(_tag, 'location update failed', error: e);
    }
  }

  Future<void> refresh() async {
    log.d(_tag, 'refresh');
    state = const AsyncValue.loading();
    try {
      await _updateLocation();
      final jobs = await ref.read(jobRepositoryProvider).getAvailableJobs();
      state = AsyncValue.data(jobs);
    } catch (e, st) {
      log.e(_tag, 'refresh failed', error: e, stack: st);
      state = AsyncValue.error(e, st);
    }
  }

  void removeJob(String jobId) {
    log.d(_tag, 'removeJob', data: {'jobId': jobId});
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((j) => j.id != jobId).toList());
  }
}

final jobFeedNotifierProvider =
    AsyncNotifierProvider<JobFeedNotifier, List<JobSummary>>(
        JobFeedNotifier.new);
