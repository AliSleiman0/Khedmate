namespace Khudmati.Modules.Payments.Application;

// ── Result types ──────────────────────────────────────────────────────────────

public record CreatePaymentIntentResult(string PaymentIntentId, string ClientSecret);
public record ConfirmPaymentResult(bool Succeeded, string? ErrorMessage);
public record TransferResult(string TransferId);
public record OnboardProviderResult(string StripeAccountId, string OnboardingUrl);

// ── Interface ─────────────────────────────────────────────────────────────────

/// <summary>
/// Abstracts the payment gateway so Stripe can be swapped without touching application logic.
/// All Stripe-specific code must live in Infrastructure/Stripe/StripePaymentProvider.cs.
/// </summary>
public interface IPaymentProvider
{
    Task<CreatePaymentIntentResult> CreatePaymentIntentAsync(
        decimal amount, string currency, CancellationToken ct = default);

    Task<ConfirmPaymentResult> GetPaymentIntentStatusAsync(
        string paymentIntentId, CancellationToken ct = default);

    Task<TransferResult> TransferToProviderAsync(
        string providerStripeAccountId, decimal amount, string currency, CancellationToken ct = default);

    Task<OnboardProviderResult> CreateOrGetProviderAccountAsync(
        Guid providerId, string email, CancellationToken ct = default);

    Task<bool> RefundAsync(
        string paymentIntentId, decimal amount, string currency, CancellationToken ct = default);
}
