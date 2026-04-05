import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/rating_repository.dart';

// ---------------------------------------------------------------------------
// Rating submission state (per job)
// ---------------------------------------------------------------------------
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
    state = state.copyWith(isSubmitting: true);
    try {
      final success = await _ref.read(ratingRepositoryProvider).submitRating(
            jobId: jobId,
            isPositive: state.isPositive!,
            tags: state.selectedTags,
          );
      if (success) {
        state = state.copyWith(isSubmitting: false, isSubmitted: true);
        // Refresh pending ratings so the banner clears
        _ref.invalidate(pendingRatingsProvider);
      } else {
        state = state.copyWith(isSubmitting: false, error: 'فشل الإرسال');
      }
    } catch (_) {
      state = state.copyWith(isSubmitting: false, error: 'فشل الإرسال');
    }
  }
}

final ratingNotifierProvider =
    StateNotifierProvider.family<RatingNotifier, RatingState, String>(
  (ref, jobId) => RatingNotifier(jobId, ref),
);

// ---------------------------------------------------------------------------
// Pending ratings (for home screen banner)
// ---------------------------------------------------------------------------
final pendingRatingsProvider = FutureProvider<List<PendingRatingItem>>((ref) {
  return ref.read(ratingRepositoryProvider).getPendingRatings();
});
