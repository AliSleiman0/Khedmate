import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/rating_repository.dart';

// ---------------------------------------------------------------------------
// Rating submission state (per job)
// ---------------------------------------------------------------------------
class ProviderRatingState {
  final bool? isPositive;
  final List<String> selectedTags;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? error;

  const ProviderRatingState({
    this.isPositive,
    this.selectedTags = const [],
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.error,
  });

  factory ProviderRatingState.initial() => const ProviderRatingState();

  ProviderRatingState copyWith({
    bool? isPositive,
    List<String>? selectedTags,
    bool? isSubmitting,
    bool? isSubmitted,
    String? error,
  }) =>
      ProviderRatingState(
        isPositive: isPositive ?? this.isPositive,
        selectedTags: selectedTags ?? this.selectedTags,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error,
      );
}

class ProviderRatingNotifier extends StateNotifier<ProviderRatingState> {
  final String jobId;
  final Ref _ref;

  ProviderRatingNotifier(this.jobId, this._ref)
      : super(ProviderRatingState.initial());

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
        _ref.invalidate(pendingRatingJobIdsProvider);
      } else {
        state = state.copyWith(isSubmitting: false, error: 'SEND_FAILED');
      }
    } catch (_) {
      state = state.copyWith(isSubmitting: false, error: 'SEND_FAILED');
    }
  }
}

final providerRatingNotifierProvider = StateNotifierProvider.family<
    ProviderRatingNotifier, ProviderRatingState, String>(
  (ref, jobId) => ProviderRatingNotifier(jobId, ref),
);

// ---------------------------------------------------------------------------
// Pending rating job IDs (provider side)
// ---------------------------------------------------------------------------
final pendingRatingJobIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.read(ratingRepositoryProvider).getPendingRatingJobIds();
});
