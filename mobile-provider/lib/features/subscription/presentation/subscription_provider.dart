import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_info.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo?> {
  @override
  Future<SubscriptionInfo?> build() {
    return ref.read(subscriptionRepositoryProvider).getSubscription();
  }

  /// Returns null on success, localised error string on failure.
  Future<String?> subscribe(String paymentMethodId) async {
    state = const AsyncLoading();
    try {
      await ref.read(subscriptionRepositoryProvider).subscribe(paymentMethodId);
      ref.invalidateSelf();
      return null;
    } on SubscriptionApiException catch (e) {
      state = AsyncData(state.valueOrNull);
      return _mapError(e.errorCode);
    } catch (_) {
      state = AsyncData(state.valueOrNull);
      return _s().errorGeneric;
    }
  }

  /// Returns null on success, localised error string on failure.
  Future<String?> cancel() async {
    try {
      await ref.read(subscriptionRepositoryProvider).cancelSubscription();
      ref.invalidateSelf();
      return null;
    } on SubscriptionApiException catch (e) {
      return _mapError(e.errorCode);
    } catch (_) {
      return _s().errorGeneric;
    }
  }

  S _s() => S.of2(ref.read(localeProvider).languageCode == 'ar');

  String _mapError(String code) {
    final s = _s();
    return switch (code) {
      'PROVIDER_NOT_ACTIVE' => s.subErrorNotActive,
      'ALREADY_SUBSCRIBED' => s.subErrorAlready,
      'PAYMENT_METHOD_INVALID' => s.subErrorPayment,
      'STRIPE_ERROR' => s.subErrorStripe,
      _ => s.errorGeneric,
    };
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionInfo?>(
        SubscriptionNotifier.new);
