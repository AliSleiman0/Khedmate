using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Providers.Domain.Entities;

public class TierHistory : BaseEntity
{
    public Guid ProviderId { get; private set; }
    public VerificationTier PreviousTier { get; private set; }
    public VerificationTier NewTier { get; private set; }
    public Guid ChangedBy { get; private set; }
    public DateTime ChangedAt { get; private set; } = DateTime.UtcNow;
    public string? Reason { get; private set; }

    private TierHistory() { }

    public static TierHistory Create(Guid providerId, VerificationTier previousTier, VerificationTier newTier, Guid changedBy, string? reason = null)
    {
        return new TierHistory
        {
            ProviderId = providerId,
            PreviousTier = previousTier,
            NewTier = newTier,
            ChangedBy = changedBy,
            ChangedAt = DateTime.UtcNow,
            Reason = reason
        };
    }
}
