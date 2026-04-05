using Khudmati.Modules.Providers.Domain.Enums;

namespace Khudmati.Modules.Providers.Application.DTOs;

public record OnboardingStatusDto(
    VerificationTier VerificationTier,
    OnboardingStepsDto Steps,
    bool CanAcceptJobs
);

public record OnboardingStepsDto(
    OnboardingStepDto IdVerified,
    OnboardingStepDto SkillTested,
    OnboardingStepDto PhoneVerified
);

public record OnboardingStepDto(
    string Status,  // "Complete", "PendingReview", "Required", "Rejected"
    DateTime? CompletedAt,
    DateTime? SubmittedAt,
    string? RejectionReason
);
