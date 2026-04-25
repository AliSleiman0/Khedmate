import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../data/onboarding_api_service.dart';
import '../domain/skill_test.dart';

const _tag = 'SkillTest';

class SkillTestScreen extends ConsumerStatefulWidget {
  const SkillTestScreen({super.key});

  @override
  ConsumerState<SkillTestScreen> createState() => _SkillTestScreenState();
}

class _SkillTestScreenState extends ConsumerState<SkillTestScreen> {
  String? _selectedCategory;
  SkillTest? _test;
  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  bool _isLoading = false;
  bool _isSubmitting = false;

  static const _categoryIds = [
    'plumbing',
    'electrical',
    'cleaning',
    'carpentry',
    'painting',
    'ac_maintenance',
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    if (_test != null) {
      return _buildTestScreen(s);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(s.skillTestTitle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.skillTestSelectCategory,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categoryIds.length,
                      itemBuilder: (context, index) {
                        final categoryId = _categoryIds[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              s.categoryLabel(categoryId),
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _startTest(categoryId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTestScreen(S s) {
    final question = _test!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _test!.questions.length;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          s.skillTestQuestion(
              _currentQuestionIndex + 1, _test!.questions.length),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ...question.options.map((option) {
                    final isSelected = _answers[question.id] == option.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () {
                          log.d(_tag, 'answer', data: {
                            'q': _currentQuestionIndex,
                            'optionId': option.key,
                          });
                          setState(() {
                            _answers[question.id] = option.key;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black,
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${option.key}. ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(child: Text(option.text)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed:
                  _answers.containsKey(question.id) ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _currentQuestionIndex < _test!.questions.length - 1
                          ? s.next
                          : s.skillTestFinish,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTest(String categoryId) async {
    log.d(_tag, 'init', data: {'category': categoryId});
    setState(() => _isLoading = true);

    try {
      final service = ref.read(onboardingApiServiceProvider);
      final test = await service.getSkillTest(categoryId);
      log.i(_tag, 'session start', data: {
        'sessionId': test.testId,
        'category': categoryId,
        'total': test.questions.length,
      });
      setState(() {
        _test = test;
        _selectedCategory = categoryId;
        _isLoading = false;
      });
    } catch (e) {
      log.w(_tag, 'session start failed',
          error: e, data: {'category': categoryId});
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.read(ref).onboardingError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _test!.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      await _submitTest();
    }
  }

  Future<void> _submitTest() async {
    log.d(_tag, 'submit start', data: {'sessionId': _test?.testId});
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(onboardingApiServiceProvider);
      final answers = _answers.entries
          .map((e) => SkillTestAnswer(questionId: e.key, selectedKey: e.value))
          .toList();

      final result = await service.submitSkillTest(
        categoryId: _selectedCategory!,
        testId: _test!.testId,
        answers: answers,
      );

      log.i(_tag, 'session ok', data: {
        'sessionId': _test?.testId,
        'score': result.score,
        'total': result.totalQuestions,
        'passed': result.passed,
      });
      if (!result.passed) {
        log.w(_tag, 'session failed cooldown',
            data: {'nextRetryAt': result.nextRetryAt?.toIso8601String()});
      }

      if (!mounted) return;

      final s = S.read(ref);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            result.passed ? s.skillTestPassed : s.skillTestFailed,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.passed ? Icons.celebration : Icons.info,
                size: 64,
                color: result.passed ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                s.skillTestScore(result.score, result.totalQuestions),
                style: const TextStyle(fontSize: 18),
              ),
              if (!result.passed && result.nextRetryAt != null) ...[
                const SizedBox(height: 8),
                Text(s.skillTestRetry),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.invalidate(onboardingStatusProvider);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(s.okay),
            ),
          ],
        ),
      );
    } catch (e) {
      log.e(_tag, 'submit failed',
          error: e, data: {'sessionId': _test?.testId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.read(ref).onboardingError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
