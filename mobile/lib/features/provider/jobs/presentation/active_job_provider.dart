import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/redact.dart';
import '../../../../core/services/signalr_service.dart';
import '../data/job_repository.dart';

const _tag = 'ActiveJobNotifier';

class ActiveJobNotifier extends FamilyAsyncNotifier<JobDetail, String> {
  Timer? _locationTimer;

  @override
  Future<JobDetail> build(String arg) async {
    log.d(_tag, 'build', data: {'jobId': arg});
    ref.onDispose(() {
      log.d(_tag, 'dispose', data: {'jobId': arg});
      _stopLocationBroadcast(arg, reason: 'disposed');
    });
    _subscribeToStatusChanges(arg);
    final job = await ref.read(jobRepositoryProvider).getJobById(arg);
    if (job.status == 'EnRoute') {
      _startLocationBroadcast(arg);
    }
    return job;
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
        final previousStatus = current.status;
        log.i(_tag, 'status', data: {
          'jobId': jobId,
          'from': previousStatus,
          'to': newStatus,
          'source': 'signalr',
        });
        state = AsyncData(current.copyWith(status: newStatus));

        if (newStatus == 'EnRoute' && previousStatus != 'EnRoute') {
          _startLocationBroadcast(jobId);
        } else if (previousStatus == 'EnRoute' && newStatus != 'EnRoute') {
          _stopLocationBroadcast(jobId, reason: 'arrived');
        }
      }
    });
  }

  void _startLocationBroadcast(String jobId) {
    _stopLocationBroadcast(jobId, reason: 'restart');
    log.i(_tag, 'gps broadcast start',
        data: {'jobId': jobId, 'intervalMs': 3000});
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            log.w(_tag, 'gps permission denied', data: {'jobId': jobId});
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          log.w(_tag, 'gps permission denied forever',
              data: {'jobId': jobId});
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        log.v(_tag, 'gps push', data: {
          'jobId': jobId,
          'coords': redactLatLng(position.latitude, position.longitude),
        });
        await ref.read(jobRepositoryProvider).sendLocationForJob(
              jobId,
              position.latitude,
              position.longitude,
            );
      } catch (e, st) {
        // Silent — broadcast is non-critical
        log.e(_tag, 'gps failed',
            error: e, stack: st, data: {'jobId': jobId});
      }
    });
  }

  void _stopLocationBroadcast(String jobId, {required String reason}) {
    if (_locationTimer != null) {
      log.i(_tag, 'gps broadcast stop',
          data: {'jobId': jobId, 'reason': reason});
    }
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> advanceStatus() async {
    final job = state.valueOrNull;
    if (job == null) {
      log.w(_tag, 'advance blocked', data: {'reason': 'no_state'});
      return;
    }
    final previousStatus = job.status;
    log.d(_tag, 'advance start',
        data: {'jobId': job.id, 'from': previousStatus});
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).advanceJobStatus(job.id),
    );
    state = result;

    final newJob = result.valueOrNull;
    if (newJob != null) {
      log.i(_tag, 'status', data: {
        'jobId': job.id,
        'from': previousStatus,
        'to': newJob.status,
        'source': 'advance_api',
      });
      if (newJob.status == 'EnRoute' && previousStatus != 'EnRoute') {
        _startLocationBroadcast(job.id);
      } else if (previousStatus == 'EnRoute' && newJob.status != 'EnRoute') {
        _stopLocationBroadcast(job.id, reason: 'arrived');
      }
    } else {
      log.e(_tag, 'advance failed',
          error: result.error, data: {'jobId': job.id});
    }
  }
}

final activeJobNotifierProvider =
    AsyncNotifierProviderFamily<ActiveJobNotifier, JobDetail, String>(
        ActiveJobNotifier.new);
