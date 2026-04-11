using System.Security.Claims;
using Khudmati.API.Domain;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace Khudmati.API.Controllers.Providers;

[ApiController]
[Route("api/providers/me/subscription")]
[Authorize(Policy = "ProviderOnly")]
public class ProviderSubscriptionController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;
    private readonly IHubContext<JobHub> _hub;
    private readonly ILogger<ProviderSubscriptionController> _logger;

    public ProviderSubscriptionController(
        AppDbContext context,
        IConfiguration config,
        IHubContext<JobHub> hub,
        ILogger<ProviderSubscriptionController> logger)
    {
        _context = context;
        _config = config;
        _hub = hub;
        _logger = logger;
    }

    // GET /api/providers/me/subscription
    // Returns the provider's current active/past-due subscription, or 404 if none.
    [HttpGet]
    public async Task<IActionResult> GetSubscription(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var sub = await _context.Set<ProviderSubscription>()
            .Where(s => s.ProviderId == providerId && (s.Status == "Active" || s.Status == "PastDue"))
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (sub is null)
            return NotFound(new { success = false, data = (object?)null });

        var plan = await _context.Set<SubscriptionPlan>().FindAsync([sub.PlanId], ct);

        return Ok(new
        {
            success = true,
            data = new
            {
                plan = "PowerProvider",
                status = sub.Status,
                monthlyFee = plan?.MonthlyFee ?? 99m,
                commissionRate = plan?.CommissionRate ?? 10m,
                currentPeriodEnd = sub.CurrentPeriodEnd,
                cancelsAtPeriodEnd = sub.CancelsAtPeriodEnd,
                currency = "SAR",
            }
        });
    }

    // GET /api/providers/me/subscription/setup-intent
    // Creates a Stripe SetupIntent so the Flutter app can present PaymentSheet.
    [HttpGet("setup-intent")]
    public async Task<IActionResult> GetSetupIntent(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Block if already has an active subscription
        var existing = await _context.Set<ProviderSubscription>()
            .AnyAsync(s => s.ProviderId == providerId && (s.Status == "Active" || s.Status == "PastDue"), ct);
        if (existing)
            return Conflict(new { success = false, error = "ALREADY_SUBSCRIBED" });

        var provider = await _context.Set<Provider>().FindAsync([providerId], ct);
        if (provider is null || provider.Tier != VerificationTier.Active)
            return UnprocessableEntity(new { success = false, error = "PROVIDER_NOT_ACTIVE" });

        try
        {
            StripeConfiguration.ApiKey = _config["Stripe:SecretKey"];

            // Create or retrieve Stripe customer for this provider
            var customerService = new CustomerService();
            var customers = await customerService.ListAsync(new CustomerListOptions
            {
                Email = provider.Phone + "@stripe.khudmati.com",
                Limit = 1,
            }, cancellationToken: ct);

            string stripeCustomerId;
            if (customers.Data.Count > 0)
            {
                stripeCustomerId = customers.Data[0].Id;
            }
            else
            {
                var customer = await customerService.CreateAsync(new CustomerCreateOptions
                {
                    Email = provider.Phone + "@stripe.khudmati.com",
                    Name = provider.FullName,
                    Metadata = new Dictionary<string, string> { ["providerId"] = providerId.ToString() }
                }, cancellationToken: ct);
                stripeCustomerId = customer.Id;
            }

            // Create SetupIntent
            var setupService = new SetupIntentService();
            var setupIntent = await setupService.CreateAsync(new SetupIntentCreateOptions
            {
                Customer = stripeCustomerId,
                PaymentMethodTypes = ["card"],
                Metadata = new Dictionary<string, string> { ["providerId"] = providerId.ToString() }
            }, cancellationToken: ct);

            return Ok(new { success = true, data = new { clientSecret = setupIntent.ClientSecret } });
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error creating setup intent for provider {ProviderId}", providerId);
            return StatusCode(503, new { success = false, error = "STRIPE_ERROR" });
        }
    }

    // POST /api/providers/me/subscription
    // Body: { paymentMethodId } — paymentMethodId is the SetupIntent ID (seti_xxx)
    // Backend retrieves the confirmed PaymentMethod from the SetupIntent and creates the subscription.
    [HttpPost]
    public async Task<IActionResult> Subscribe([FromBody] SubscribeRequest request, CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var provider = await _context.Set<Provider>().FindAsync([providerId], ct);
        if (provider is null || provider.Tier != VerificationTier.Active)
            return UnprocessableEntity(new { success = false, error = "PROVIDER_NOT_ACTIVE" });

        var existing = await _context.Set<ProviderSubscription>()
            .AnyAsync(s => s.ProviderId == providerId && (s.Status == "Active" || s.Status == "PastDue"), ct);
        if (existing)
            return Conflict(new { success = false, error = "ALREADY_SUBSCRIBED" });

        var plan = await _context.Set<SubscriptionPlan>()
            .FirstOrDefaultAsync(p => p.IsActive, ct);
        if (plan is null)
            return StatusCode(503, new { success = false, error = "STRIPE_ERROR" });

        try
        {
            StripeConfiguration.ApiKey = _config["Stripe:SecretKey"];

            // If paymentMethodId starts with "seti_", retrieve the setup intent to get the payment method
            string paymentMethodId;
            if (request.PaymentMethodId.StartsWith("seti_"))
            {
                var siService = new SetupIntentService();
                var si = await siService.GetAsync(request.PaymentMethodId, cancellationToken: ct);
                if (si.PaymentMethodId is null)
                    return UnprocessableEntity(new { success = false, error = "PAYMENT_METHOD_INVALID" });
                paymentMethodId = si.PaymentMethodId;
            }
            else
            {
                paymentMethodId = request.PaymentMethodId;
            }

            // Determine or create Stripe customer
            var customerService = new CustomerService();
            var customers = await customerService.ListAsync(new CustomerListOptions
            {
                Email = provider.Phone + "@stripe.khudmati.com",
                Limit = 1,
            }, cancellationToken: ct);

            string stripeCustomerId = customers.Data.Count > 0
                ? customers.Data[0].Id
                : (await customerService.CreateAsync(new CustomerCreateOptions
                {
                    Email = provider.Phone + "@stripe.khudmati.com",
                    Name = provider.FullName,
                    Metadata = new Dictionary<string, string> { ["providerId"] = providerId.ToString() }
                }, cancellationToken: ct)).Id;

            // Attach payment method to customer
            var pmService = new PaymentMethodService();
            await pmService.AttachAsync(paymentMethodId, new PaymentMethodAttachOptions
            {
                Customer = stripeCustomerId,
            }, cancellationToken: ct);

            // Set as default
            await customerService.UpdateAsync(stripeCustomerId, new CustomerUpdateOptions
            {
                InvoiceSettings = new CustomerInvoiceSettingsOptions
                {
                    DefaultPaymentMethod = paymentMethodId,
                }
            }, cancellationToken: ct);

            // Create the Stripe Subscription
            var subService = new SubscriptionService();
            var stripeSub = await subService.CreateAsync(new SubscriptionCreateOptions
            {
                Customer = stripeCustomerId,
                Items =
                [
                    new SubscriptionItemOptions { Price = plan.StripePriceId ?? "price_test_placeholder" }
                ],
                PaymentSettings = new SubscriptionPaymentSettingsOptions
                {
                    PaymentMethodTypes = ["card"],
                },
                Expand = ["latest_invoice.payment_intent"],
            }, cancellationToken: ct);

            // Persist subscription record
            var providerSub = ProviderSubscription.Create(
                providerId,
                plan.Id,
                stripeSub.Id,
                stripeCustomerId,
                stripeSub.CurrentPeriodStart,
                stripeSub.CurrentPeriodEnd);

            _context.Set<ProviderSubscription>().Add(providerSub);
            await _context.SaveChangesAsync(ct);

            // SignalR notification
            await _hub.Clients
                .Group($"provider-{providerId}")
                .SendAsync("SubscriptionActivated", new
                {
                    plan = "PowerProvider",
                    commissionRate = plan.CommissionRate,
                    currentPeriodEnd = stripeSub.CurrentPeriodEnd,
                }, ct);

            return Ok(new { success = true });
        }
        catch (StripeException ex) when (ex.StripeError?.Type == "card_error")
        {
            _logger.LogWarning(ex, "Card error subscribing provider {ProviderId}", providerId);
            return UnprocessableEntity(new { success = false, error = "PAYMENT_METHOD_INVALID" });
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error subscribing provider {ProviderId}", providerId);
            return StatusCode(503, new { success = false, error = "STRIPE_ERROR" });
        }
    }

    // DELETE /api/providers/me/subscription
    [HttpDelete]
    public async Task<IActionResult> CancelSubscription(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var sub = await _context.Set<ProviderSubscription>()
            .Where(s => s.ProviderId == providerId && s.Status == "Active")
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (sub is null)
            return NotFound(new { success = false, error = "NOT_SUBSCRIBED" });

        try
        {
            StripeConfiguration.ApiKey = _config["Stripe:SecretKey"];

            if (!string.IsNullOrEmpty(sub.StripeSubscriptionId))
            {
                var subService = new SubscriptionService();
                await subService.UpdateAsync(sub.StripeSubscriptionId, new SubscriptionUpdateOptions
                {
                    CancelAtPeriodEnd = true,
                }, cancellationToken: ct);
            }

            sub.SetCancelsAtPeriodEnd(true);
            await _context.SaveChangesAsync(ct);

            await _hub.Clients
                .Group($"provider-{providerId}")
                .SendAsync("SubscriptionCancelled", new { endsAt = sub.CurrentPeriodEnd }, ct);

            return Ok(new
            {
                success = true,
                data = new { cancelsAt = sub.CurrentPeriodEnd }
            });
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error cancelling subscription for provider {ProviderId}", providerId);
            return StatusCode(503, new { success = false, error = "STRIPE_ERROR" });
        }
    }
}

public record SubscribeRequest(string PaymentMethodId);
