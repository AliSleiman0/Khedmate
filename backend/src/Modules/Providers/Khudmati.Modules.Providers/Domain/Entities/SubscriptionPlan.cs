using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Providers.Domain.Entities;

public class SubscriptionPlan : AuditableEntity
{
    public string Name { get; private set; } = string.Empty;
    public decimal MonthlyFee { get; private set; }
    public decimal CommissionRate { get; private set; }
    public int PriorityDelaySeconds { get; private set; }
    public bool IsActive { get; private set; }
    public string? StripePriceId { get; private set; }

    private SubscriptionPlan() { }

    public static SubscriptionPlan Create(string name, decimal monthlyFee, decimal commissionRate, int priorityDelaySeconds, string? stripePriceId = null) =>
        new()
        {
            Name = name,
            MonthlyFee = monthlyFee,
            CommissionRate = commissionRate,
            PriorityDelaySeconds = priorityDelaySeconds,
            IsActive = true,
            StripePriceId = stripePriceId
        };

    public void Update(decimal? monthlyFee, decimal? commissionRate, int? priorityDelaySeconds, string? stripePriceId, bool? isActive)
    {
        if (monthlyFee.HasValue) MonthlyFee = monthlyFee.Value;
        if (commissionRate.HasValue) CommissionRate = commissionRate.Value;
        if (priorityDelaySeconds.HasValue) PriorityDelaySeconds = priorityDelaySeconds.Value;
        if (stripePriceId is not null) StripePriceId = stripePriceId;
        if (isActive.HasValue) IsActive = isActive.Value;
        SetUpdated();
    }
}
