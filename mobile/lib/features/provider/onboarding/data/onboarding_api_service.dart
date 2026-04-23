import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/providers/role_provider.dart';
import '../domain/onboarding_status.dart';
import '../domain/skill_test.dart';

class OnboardingApiService {
  final ApiClient _apiClient;

  OnboardingApiService(this._apiClient);

  Future<OnboardingStatus> getOnboardingStatus() async {
    final response = await _apiClient.dio.get('/providers/onboarding/status');
    final data = response.data['data'] as Map<String, dynamic>;
    return OnboardingStatus.fromJson(data);
  }

  Future<void> submitDocuments({
    required String documentType,
    required XFile frontImage,
    XFile? backImage,
  }) async {
    final formData = FormData.fromMap({
      'documentType': documentType,
      'frontImage': await MultipartFile.fromFile(
        frontImage.path,
        filename: frontImage.name,
      ),
      if (backImage != null)
        'backImage': await MultipartFile.fromFile(
          backImage.path,
          filename: backImage.name,
        ),
    });

    await _apiClient.dio.post(
      '/providers/onboarding/documents',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
  }

  Future<SkillTest> getSkillTest(String categoryId) async {
    final response = await _apiClient.dio.get(
      '/providers/onboarding/skill-test/$categoryId',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SkillTest.fromJson(data);
  }

  Future<SkillTestResult> submitSkillTest({
    required String categoryId,
    required String testId,
    required List<SkillTestAnswer> answers,
  }) async {
    final response = await _apiClient.dio.post(
      '/providers/onboarding/skill-test/$categoryId/submit',
      data: {
        'testId': testId,
        'answers': answers.map((a) => a.toJson()).toList(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SkillTestResult.fromJson(data);
  }
}

final onboardingApiServiceProvider = Provider<OnboardingApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingApiService(apiClient);
});

final onboardingStatusProvider =
    FutureProvider.autoDispose<OnboardingStatus>((ref) async {
  final service = ref.watch(onboardingApiServiceProvider);
  final status = await service.getOnboardingStatus();
  // Persist the current verification tier so the router can gate the
  // provider shell on cold start (Phase 08).
  try {
    final storage = ref.read(secureStorageProvider);
    await storage.write(
      key: kProviderTierStorageKey,
      value: status.verificationTier.name,
    );
  } catch (_) {
    // Non-fatal — router falls back to "unknown" and lets the provider through.
  }
  return status;
});
