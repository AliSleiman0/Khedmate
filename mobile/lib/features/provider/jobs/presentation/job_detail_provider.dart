import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_repository.dart';

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
    final job = await ref.read(jobRepositoryProvider).getJobById(arg);
    _startCountdown(job.secondsRemaining);
    ref.onDispose(() => _countdownTimer?.cancel());
    return JobDetailState(job: job, secondsRemaining: job.secondsRemaining);
  }

  void _startCountdown(int initialSeconds) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.value;
      if (current == null) return;
      if (current.secondsRemaining <= 1) {
        _countdownTimer?.cancel();
        state = AsyncValue.data(
            current.copyWith(secondsRemaining: 0, isExpired: true));
      } else {
        state = AsyncValue.data(
            current.copyWith(secondsRemaining: current.secondsRemaining - 1));
      }
    });
  }

  Future<void> acceptJob() async {
    final current = state.value;
    if (current == null || current.isExpired) return;
    _countdownTimer?.cancel();
    state = const AsyncValue.loading();
    try {
      await ref
          .read(jobRepositoryProvider)
          .respondToJob(current.job.id, 'accept');
      state = AsyncValue.data(current.copyWith(isAccepted: true));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectJob() async {
    final current = state.value;
    if (current == null) return;
    _countdownTimer?.cancel();
    try {
      await ref
          .read(jobRepositoryProvider)
          .respondToJob(current.job.id, 'reject');
    } catch (_) {
      // Rejection failure is silent — navigate back regardless
    }
  }
}

final jobDetailNotifierProvider = AsyncNotifierProviderFamily<JobDetailNotifier,
    JobDetailState, String>(JobDetailNotifier.new);
