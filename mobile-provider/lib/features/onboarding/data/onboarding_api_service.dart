import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/onboarding_status.dart';
import '../domain/skill_test.dart';
import '../../../../core/api/api_client.dart';

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
