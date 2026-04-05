namespace Khudmati.Modules.Payments.Domain.Entities;

/// <summary>Stripe Connect Express account for a provider. ProviderId is the primary key.</summary>
public class ProviderStripeAccount
{
    public Guid ProviderId { get; private set; }
    public string StripeAccountId { get; private set; } = string.Empty;
    public string OnboardingStatus { get; private set; } = "pending"; // pending | complete
    public DateTime CreatedAt { get; private set; }
    public DateTime? UpdatedAt { get; private set; }

    private ProviderStripeAccount() { }

    public static ProviderStripeAccount Create(Guid providerId, string stripeAccountId) =>
        new()
        {
            ProviderId = providerId,
            StripeAccountId = stripeAccountId,
            OnboardingStatus = "pending",
            CreatedAt = DateTime.UtcNow
        };

    public void MarkComplete()
    {
        OnboardingStatus = "complete";
        UpdatedAt = DateTime.UtcNow;
    }
}
