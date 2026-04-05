using Khudmati.Modules.Payments.Application;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;

namespace Khudmati.Modules.Payments.Infrastructure.Stripe;

/// <summary>
/// Stripe implementation of IPaymentProvider.
/// All Stripe-specific code lives here — no Stripe imports anywhere else.
/// Configured with test keys by default; switch to live keys in config = live mode.
/// </summary>
public class StripePaymentProvider : IPaymentProvider
{
    private readonly IConfiguration _config;
    private readonly ILogger<StripePaymentProvider> _logger;

    public StripePaymentProvider(IConfiguration config, ILogger<StripePaymentProvider> logger)
    {
        _config = config;
        _logger = logger;
        StripeConfiguration.ApiKey = config["Stripe:SecretKey"]
            ?? throw new InvalidOperationException("Stripe:SecretKey is not configured.");
    }

    public async Task<CreatePaymentIntentResult> CreatePaymentIntentAsync(
        decimal amount, string currency, CancellationToken ct = default)
    {
        var service = new PaymentIntentService();
        var options = new PaymentIntentCreateOptions
        {
            Amount = ToStripeAmount(amount, currency),
            Currency = currency.ToLowerInvariant(),
            AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
            {
                Enabled = true
            }
        };

        var intent = await service.CreateAsync(options, cancellationToken: ct);
        _logger.LogInformation("Created PaymentIntent {IntentId} for {Amount} {Currency}",
            intent.Id, amount, currency);

        return new CreatePaymentIntentResult(intent.Id, intent.ClientSecret);
    }

    public async Task<ConfirmPaymentResult> GetPaymentIntentStatusAsync(
        string paymentIntentId, CancellationToken ct = default)
    {
        var service = new PaymentIntentService();
        var intent = await service.GetAsync(paymentIntentId, cancellationToken: ct);
        var succeeded = intent.Status == "succeeded";
        return new ConfirmPaymentResult(succeeded, succeeded ? null : intent.LastPaymentError?.Message);
    }

    public async Task<TransferResult> TransferToProviderAsync(
        string providerStripeAccountId, decimal amount, string currency, CancellationToken ct = default)
    {
        var service = new TransferService();
        var options = new TransferCreateOptions
        {
            Amount = ToStripeAmount(amount, currency),
            Currency = currency.ToLowerInvariant(),
            Destination = providerStripeAccountId
        };

        var transfer = await service.CreateAsync(options, cancellationToken: ct);
        _logger.LogInformation("Transferred {Amount} {Currency} to account {Account} via transfer {TransferId}",
            amount, currency, providerStripeAccountId, transfer.Id);

        return new TransferResult(transfer.Id);
    }

    public async Task<OnboardProviderResult> CreateOrGetProviderAccountAsync(
        Guid providerId, string email, CancellationToken ct = default)
    {
        // Always create a new Express account (if existing, caller should have the ID stored)
        var accountService = new AccountService();
        var account = await accountService.CreateAsync(new AccountCreateOptions
        {
            Type = "express",
            Email = email,
            Capabilities = new AccountCapabilitiesOptions
            {
                Transfers = new AccountCapabilitiesTransfersOptions { Requested = true }
            },
            Metadata = new Dictionary<string, string>
            {
                { "khudmati_provider_id", providerId.ToString() }
            }
        }, cancellationToken: ct);

        var linkService = new AccountLinkService();
        var link = await linkService.CreateAsync(new AccountLinkCreateOptions
        {
            Account = account.Id,
            RefreshUrl = _config["Stripe:Connect:RefreshUrl"] ?? "https://khudmati.com/stripe/reauth",
            ReturnUrl = _config["Stripe:Connect:ReturnUrl"] ?? "https://khudmati.com/stripe/return",
            Type = "account_onboarding"
        }, cancellationToken: ct);

        _logger.LogInformation("Created Stripe Connect account {AccountId} for provider {ProviderId}",
            account.Id, providerId);

        return new OnboardProviderResult(account.Id, link.Url);
    }

    /// <summary>Converts decimal amount to Stripe's integer smallest-unit format (cents for USD).</summary>
    private static long ToStripeAmount(decimal amount, string currency) =>
        currency.ToLowerInvariant() == "lbp"
            ? (long)amount          // LBP has no subunit
            : (long)(amount * 100); // USD, EUR, etc. use cents

    public async Task<bool> RefundAsync(
        string paymentIntentId, decimal amount, string currency, CancellationToken ct = default)
    {
        var service = new RefundService();
        var options = new RefundCreateOptions
        {
            PaymentIntent = paymentIntentId,
            Amount = ToStripeAmount(amount, currency)
        };

        var refund = await service.CreateAsync(options, cancellationToken: ct);
        _logger.LogInformation(
            "Issued refund {RefundId} for PaymentIntent {IntentId}, amount {Amount} {Currency}",
            refund.Id, paymentIntentId, amount, currency);

        return refund.Status == "succeeded" || refund.Status == "pending";
    }
}
