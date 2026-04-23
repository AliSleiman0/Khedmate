class SkillTest {
  final String testId;
  final String categoryId;
  final String categoryName;
  final List<SkillTestQuestion> questions;

  const SkillTest({
    required this.testId,
    required this.categoryId,
    required this.categoryName,
    required this.questions,
  });

  factory SkillTest.fromJson(Map<String, dynamic> json) {
    return SkillTest(
      testId: json['testId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      questions: (json['questions'] as List)
          .map((q) => SkillTestQuestion.fromJson(q))
          .toList(),
    );
  }
}

class SkillTestQuestion {
  final String id;
  final String questionText;
  final List<SkillTestOption> options;

  const SkillTestQuestion({
    required this.id,
    required this.questionText,
    required this.options,
  });

  factory SkillTestQuestion.fromJson(Map<String, dynamic> json) {
    return SkillTestQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      options: (json['options'] as List)
          .map((o) => SkillTestOption.fromJson(o))
          .toList(),
    );
  }
}

class SkillTestOption {
  final String key;
  final String text;

  const SkillTestOption({
    required this.key,
    required this.text,
  });

  factory SkillTestOption.fromJson(Map<String, dynamic> json) {
    return SkillTestOption(
      key: json['key'] as String,
      text: json['text'] as String,
    );
  }
}

class SkillTestResult {
  final bool passed;
  final int score;
  final int totalQuestions;
  final int passmark;
  final DateTime? nextRetryAt;

  const SkillTestResult({
    required this.passed,
    required this.score,
    required this.totalQuestions,
    required this.passmark,
    this.nextRetryAt,
  });

  factory SkillTestResult.fromJson(Map<String, dynamic> json) {
    return SkillTestResult(
      passed: json['passed'] as bool,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      passmark: json['passmark'] as int,
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.parse(json['nextRetryAt'])
          : null,
    );
  }
}

class SkillTestAnswer {
  final String questionId;
  final String selectedKey;

  const SkillTestAnswer({
    required this.questionId,
    required this.selectedKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedKey': selectedKey,
    };
  }
}
