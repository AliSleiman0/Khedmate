namespace Khudmati.Modules.Providers.Application.DTOs;

public record SkillTestResultDto(
    bool Passed,
    int Score,
    int TotalQuestions,
    int Passmark,
    DateTime? NextRetryAt
);
