import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/locale_provider.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_info.dart';

const _tag = 'SubscriptionNotifier';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo?> {
  @override
  Future<SubscriptionInfo?> build() {
    log.d(_tag, 'build');
    return ref.read(subscriptionRepositoryProvider).getSubscription();
  }

  Future<String?> subscribe(String paymentMethodId) async {
    log.d(_tag, 'activate api start');
    state = const AsyncLoading();
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .subscribe(paymentMethodId);
      log.i(_tag, 'activate ok', data: {'status': 'Active'});
      ref.invalidateSelf();
      return null;
    } on SubscriptionApiException catch (e) {
      log.w(_tag, 'activate failed', data: {'code': e.errorCode});
      state = AsyncData(state.valueOrNull);
      return _mapError(e.errorCode);
    } catch (e, st) {
      log.e(_tag, 'activate crashed', error: e, stack: st);
      state = AsyncData(state.valueOrNull);
      return _s().errorGeneric;
    }
  }

  Future<String?> cancel() async {
    log.d(_tag, 'cancel start');
    try {
      final cancelsAt =
          await ref.read(subscriptionRepositoryProvider).cancelSubscription();
      log.i(_tag, 'cancel ok',
          data: {'cancelsAt': cancelsAt?.toIso8601String()});
      ref.invalidateSelf();
      return null;
    } on SubscriptionApiException catch (e) {
      log.w(_tag, 'cancel failed', data: {'code': e.errorCode});
      return _mapError(e.errorCode);
    } catch (e, st) {
      log.e(_tag, 'cancel crashed', error: e, stack: st);
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
