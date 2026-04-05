using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Providers.Domain.Entities;

public class SkillTestSession : AuditableEntity
{
    public Guid ProviderId { get; private set; }
    public string CategoryId { get; private set; } = string.Empty;
    public SkillTestStatus Status { get; private set; } = SkillTestStatus.InProgress;
    public int? Score { get; private set; }
    public DateTime StartedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? SubmittedAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }
    public DateTime? NextRetryAt { get; private set; }

    private SkillTestSession() { }

    public static SkillTestSession Create(Guid providerId, string categoryId)
    {
        return new SkillTestSession
        {
            ProviderId = providerId,
            CategoryId = categoryId,
            Status = SkillTestStatus.InProgress,
            StartedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(30)
        };
    }

    public void MarkPassed(int score)
    {
        if (score < 0 || score > 10)
            throw new ArgumentOutOfRangeException(nameof(score), "Score must be between 0 and 10.");

        Status = SkillTestStatus.Passed;
        Score = score;
        SubmittedAt = DateTime.UtcNow;
        SetUpdated();
    }

    public void MarkFailed(int score)
    {
        if (score < 0 || score > 10)
            throw new ArgumentOutOfRangeException(nameof(score), "Score must be between 0 and 10.");

        Status = SkillTestStatus.Failed;
        Score = score;
        SubmittedAt = DateTime.UtcNow;
        NextRetryAt = DateTime.UtcNow.AddHours(24);
        SetUpdated();
    }

    public void MarkExpired()
    {
        Status = SkillTestStatus.Expired;
        SetUpdated();
    }

    public bool IsExpired() => DateTime.UtcNow > ExpiresAt;

    public bool IsInProgress() => Status == SkillTestStatus.InProgress;
}
