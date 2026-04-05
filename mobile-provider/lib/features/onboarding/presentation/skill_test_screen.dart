import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_providers.dart';
import '../domain/skill_test.dart';

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

  final List<Map<String, String>> _categories = [
    {'id': 'plumbing', 'name': 'سباكة'},
    {'id': 'electrical', 'name': 'كهرباء'},
    {'id': 'cleaning', 'name': 'تنظيف'},
    {'id': 'carpentry', 'name': 'نجارة'},
    {'id': 'painting', 'name': 'دهان'},
    {'id': 'ac_maintenance', 'name': 'تكييف'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_test != null) {
      return _buildTestScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار المهارة'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'اختر الفئة لبدء الاختبار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              category['name']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _startTest(category['id']!),
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

  Widget _buildTestScreen() {
    final question = _test!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _test!.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'السؤال ${_currentQuestionIndex + 1} من ${_test!.questions.length}',
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                          ? 'التالي'
                          : 'إنهاء الاختبار',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTest(String categoryId) async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(onboardingApiServiceProvider);
      final test = await service.getSkillTest(categoryId);
      setState(() {
        _test = test;
        _selectedCategory = categoryId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
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

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            result.passed ? 'أحسنت! اجتزت الاختبار' : 'لم تجتز الاختبار',
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
                'النتيجة: ${result.score}/${result.totalQuestions}',
                style: const TextStyle(fontSize: 18),
              ),
              if (!result.passed && result.nextRetryAt != null) ...[
                const SizedBox(height: 8),
                Text('يمكنك إعادة المحاولة بعد 24 ساعة'),
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
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
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
