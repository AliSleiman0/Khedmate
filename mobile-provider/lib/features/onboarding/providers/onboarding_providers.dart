import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/onboarding_api_service.dart';
import '../domain/onboarding_status.dart';
import '../../../core/api/api_client.dart';

final onboardingApiServiceProvider = Provider<OnboardingApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingApiService(apiClient);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final onboardingStatusProvider =
    FutureProvider.autoDispose<OnboardingStatus>((ref) async {
  final service = ref.watch(onboardingApiServiceProvider);
  return await service.getOnboardingStatus();
});
