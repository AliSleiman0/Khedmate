class OnboardingStatus {
  final VerificationTier verificationTier;
  final OnboardingSteps steps;
  final bool canAcceptJobs;

  const OnboardingStatus({
    required this.verificationTier,
    required this.steps,
    required this.canAcceptJobs,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      verificationTier: VerificationTier.values.firstWhere(
        (e) => e.name == json['verificationTier'],
        orElse: () => VerificationTier.unverified,
      ),
      steps: OnboardingSteps.fromJson(json['steps']),
      canAcceptJobs: json['canAcceptJobs'] as bool,
    );
  }
}

class OnboardingSteps {
  final OnboardingStep idVerified;
  final OnboardingStep skillTested;
  final OnboardingStep phoneVerified;

  const OnboardingSteps({
    required this.idVerified,
    required this.skillTested,
    required this.phoneVerified,
  });

  factory OnboardingSteps.fromJson(Map<String, dynamic> json) {
    return OnboardingSteps(
      idVerified: OnboardingStep.fromJson(json['idVerified']),
      skillTested: OnboardingStep.fromJson(json['skillTested']),
      phoneVerified: OnboardingStep.fromJson(json['phoneVerified']),
    );
  }
}

class OnboardingStep {
  final String status;
  final DateTime? completedAt;
  final DateTime? submittedAt;
  final String? rejectionReason;

  const OnboardingStep({
    required this.status,
    this.completedAt,
    this.submittedAt,
    this.rejectionReason,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      status: json['status'] as String,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  bool get isComplete => status == 'Complete';
  bool get isPending => status == 'PendingReview';
  bool get isRejected => status == 'Rejected';
  bool get isRequired => status == 'Required';
}

enum VerificationTier {
  unverified,
  phoneVerified,
  idVerified,
  skillTested,
  active,
}
