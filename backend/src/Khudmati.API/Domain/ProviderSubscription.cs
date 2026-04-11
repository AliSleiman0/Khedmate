namespace Khudmati.API.Domain;

/// <summary>Maps to providers.provider_subscriptions table (Feature #18).</summary>
public class ProviderSubscription
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid ProviderId { get; private set; }
    public Guid PlanId { get; private set; }
    public string Status { get; private set; } = string.Empty; // Active | PastDue | Cancelled | Paused
    public string? StripeSubscriptionId { get; private set; }
    public string? StripeCustomerId { get; private set; }
    public DateTime CurrentPeriodStart { get; private set; }
    public DateTime CurrentPeriodEnd { get; private set; }
    public bool CancelsAtPeriodEnd { get; private set; }
    public DateTime? CancelledAt { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; private set; }

    private ProviderSubscription() { }

    public static ProviderSubscription Create(
        Guid providerId,
        Guid planId,
        string stripeSubscriptionId,
        string stripeCustomerId,
        DateTime periodStart,
        DateTime periodEnd) => new()
    {
        ProviderId = providerId,
        PlanId = planId,
        Status = "Active",
        StripeSubscriptionId = stripeSubscriptionId,
        StripeCustomerId = stripeCustomerId,
        CurrentPeriodStart = periodStart,
        CurrentPeriodEnd = periodEnd,
        CancelsAtPeriodEnd = false,
    };

    public void SetStatus(string status)
    {
        Status = status;
        UpdatedAt = DateTime.UtcNow;
    }

    public void SetCancelsAtPeriodEnd(bool value)
    {
        CancelsAtPeriodEnd = value;
        if (value) CancelledAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdatePeriod(DateTime start, DateTime end)
    {
        CurrentPeriodStart = start;
        CurrentPeriodEnd = end;
        UpdatedAt = DateTime.UtcNow;
    }
}

