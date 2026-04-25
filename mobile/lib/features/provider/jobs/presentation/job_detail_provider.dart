import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../data/job_repository.dart';

const _tag = 'JobDetailNotifier';

class JobDetailState {
  final JobDetail job;
  final int secondsRemaining;
  final bool isExpired;
  final bool isAccepted;

  const JobDetailState({
    required this.job,
    required this.secondsRemaining,
    this.isExpired = false,
    this.isAccepted = false,
  });

  JobDetailState copyWith({
    JobDetail? job,
    int? secondsRemaining,
    bool? isExpired,
    bool? isAccepted,
  }) =>
      JobDetailState(
        job: job ?? this.job,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        isExpired: isExpired ?? this.isExpired,
        isAccepted: isAccepted ?? this.isAccepted,
      );
}

class JobDetailNotifier extends FamilyAsyncNotifier<JobDetailState, String> {
  Timer? _countdownTimer;

  @override
  Future<JobDetailState> build(String arg) async {
    log.d(_tag, 'build', data: {'jobId': arg});
    final job = await ref.read(jobRepositoryProvider).getJobById(arg);
    _startCountdown(job.id, job.secondsRemaining);
    ref.onDispose(() {
      log.d(_tag, 'dispose', data: {'jobId': arg});
      _countdownTimer?.cancel();
    });
    return JobDetailState(job: job, secondsRemaining: job.secondsRemaining);
  }

  void _startCountdown(String jobId, int initialSeconds) {
    _countdownTimer?.cancel();
    log.i(_tag, 'countdown start',
        data: {'jobId': jobId, 'seconds': initialSeconds});
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.value;
      if (current == null) return;
      if (current.secondsRemaining <= 1) {
        _countdownTimer?.cancel();
        log.w(_tag, 'expired', data: {'jobId': jobId});
        state = AsyncValue.data(
            current.copyWith(secondsRemaining: 0, isExpired: true));
      } else {
        log.v(_tag, 'tick', data: {
          'jobId': jobId,
          'remaining': current.secondsRemaining - 1,
        });
        state = AsyncValue.data(
            current.copyWith(secondsRemaining: current.secondsRemaining - 1));
      }
    });
  }

  Future<void> acceptJob() async {
    final current = state.value;
    if (current == null || current.isExpired) {
      log.w(_tag, 'accept blocked', data: {'reason': 'expired_or_no_state'});
      return;
    }
    log.d(_tag, 'accept start', data: {'jobId': current.job.id});
    _countdownTimer?.cancel();
    state = const AsyncValue.loading();
    try {
      await ref
          .read(jobRepositoryProvider)
          .respondToJob(current.job.id, 'accept');
      log.i(_tag, 'accept ok', data: {'jobId': current.job.id});
      state = AsyncValue.data(current.copyWith(isAccepted: true));
    } catch (e, st) {
      log.e(_tag, 'accept failed',
          error: e, stack: st, data: {'jobId': current.job.id});
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectJob() async {
    final current = state.value;
    if (current == null) return;
    log.d(_tag, 'reject start', data: {'jobId': current.job.id});
    _countdownTimer?.cancel();
    try {
      await ref
          .read(jobRepositoryProvider)
          .respondToJob(current.job.id, 'reject');
      log.i(_tag, 'reject ok', data: {'jobId': current.job.id});
    } catch (e) {
      // Rejection failure is silent — navigate back regardless
      log.w(_tag, 'reject failed',
          error: e, data: {'jobId': current.job.id});
    }
  }
}

final jobDetailNotifierProvider = AsyncNotifierProviderFamily<JobDetailNotifier,
    JobDetailState, String>(JobDetailNotifier.new);
