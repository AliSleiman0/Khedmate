import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../data/rating_repository.dart';

const _tag = 'RatingNotifier';

class RatingState {
  final bool? isPositive;
  final List<String> selectedTags;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? error;

  const RatingState({
    this.isPositive,
    this.selectedTags = const [],
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.error,
  });

  factory RatingState.initial() => const RatingState();

  RatingState copyWith({
    bool? isPositive,
    List<String>? selectedTags,
    bool? isSubmitting,
    bool? isSubmitted,
    String? error,
  }) =>
      RatingState(
        isPositive: isPositive ?? this.isPositive,
        selectedTags: selectedTags ?? this.selectedTags,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error,
      );
}

class RatingNotifier extends StateNotifier<RatingState> {
  final String jobId;
  final Ref _ref;

  RatingNotifier(this.jobId, this._ref) : super(RatingState.initial());

  void setThumb(bool isPositive) {
    state = state.copyWith(isPositive: isPositive, selectedTags: []);
  }

  void toggleTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  Future<void> submit() async {
    if (state.isPositive == null) return;
    log.d(_tag, 'submit start', data: {
      'jobId': jobId,
      'thumbsUp': state.isPositive,
      'tags': state.selectedTags.length,
    });
    state = state.copyWith(isSubmitting: true);
    try {
      final success = await _ref.read(ratingRepositoryProvider).submitRating(
            jobId: jobId,
            isPositive: state.isPositive!,
            tags: state.selectedTags,
          );
      if (success) {
        log.i(_tag, 'submit ok', data: {'jobId': jobId});
        state = state.copyWith(isSubmitting: false, isSubmitted: true);
        _ref.invalidate(pendingRatingsProvider);
        _ref.invalidate(pendingRatingJobIdsProvider);
      } else {
        log.w(_tag, 'submit failed',
            data: {'jobId': jobId, 'code': 'SEND_FAILED'});
        state = state.copyWith(isSubmitting: false, error: 'SEND_FAILED');
      }
    } catch (e, st) {
      log.e(_tag, 'submit crashed',
          error: e, stack: st, data: {'jobId': jobId});
      state = state.copyWith(isSubmitting: false, error: 'SEND_FAILED');
    }
  }
}

final ratingNotifierProvider =
    StateNotifierProvider.family<RatingNotifier, RatingState, String>(
  (ref, jobId) => RatingNotifier(jobId, ref),
);
