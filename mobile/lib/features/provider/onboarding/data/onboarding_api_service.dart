import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../domain/onboarding_status.dart';
import '../domain/skill_test.dart';

const _tag = 'OnboardingApi';

class OnboardingApiService {
  final ApiClient _apiClient;

  OnboardingApiService(this._apiClient);

  Future<OnboardingStatus> getOnboardingStatus() async {
    log.d(_tag, 'status start');
    try {
      final response =
          await _apiClient.dio.get('/providers/onboarding/status');
      final data = response.data['data'] as Map<String, dynamic>;
      final status = OnboardingStatus.fromJson(data);
      final stepsDone = [
        status.steps.idVerified,
        status.steps.skillTested,
        status.steps.phoneVerified,
      ].where((s) => s.isComplete).length;
      log.i(_tag, 'status ok', data: {
        'tier': status.verificationTier.name,
        'stepsDone': stepsDone,
      });
      return status;
    } on DioException catch (e) {
      log.e(_tag, 'status failed', error: e);
      rethrow;
    }
  }

  Future<void> submitDocuments({
    required String documentType,
    required XFile frontImage,
    XFile? backImage,
  }) async {
    final frontBytes = await frontImage.length();
    final backBytes = backImage == null ? 0 : await backImage.length();
    log.d(_tag, 'doc upload start', data: {
      'type': documentType,
      'bytes': frontBytes + backBytes,
    });
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

    try {
      await _apiClient.dio.post(
        '/providers/onboarding/documents',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      log.i(_tag, 'doc upload ok', data: {'type': documentType});
    } on DioException catch (e) {
      log.e(_tag, 'doc upload failed',
          error: e, data: {'type': documentType});
      rethrow;
    }
  }

  Future<SkillTest> getSkillTest(String categoryId) async {
    log.d(_tag, 'skill test fetch start',
        data: {'category': categoryId});
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
    log.d(_tag, 'skill test submit start', data: {
      'category': categoryId,
      'testId': testId,
      'answerCount': answers.length,
    });
    try {
      final response = await _apiClient.dio.post(
        '/providers/onboarding/skill-test/$categoryId/submit',
        data: {
          'testId': testId,
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return SkillTestResult.fromJson(data);
    } on DioException catch (e) {
      log.e(_tag, 'skill test submit failed',
          error: e, data: {'category': categoryId});
      rethrow;
    }
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
    final previous = await storage.read(key: kProviderTierStorageKey);
    final next = status.verificationTier.name;
    if (previous != null && previous != next) {
      log.i(_tag, 'tier bumped',
          data: {'from': previous, 'to': next});
    }
    await storage.write(
      key: kProviderTierStorageKey,
      value: next,
    );
  } catch (e) {
    // Non-fatal — router falls back to "unknown" and lets the provider through.
    log.w(_tag, 'tier persist failed', error: e);
  }
  return status;
});
