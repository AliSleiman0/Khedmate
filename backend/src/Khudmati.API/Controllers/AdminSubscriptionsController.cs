using Khudmati.API.Domain;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin/subscriptions")]
[Authorize(Policy = "AdminOnly")]
public class AdminSubscriptionsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ILogger<AdminSubscriptionsController> _logger;

    public AdminSubscriptionsController(AppDbContext context, ILogger<AdminSubscriptionsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET /api/admin/subscriptions
    [HttpGet]
    public async Task<IActionResult> GetSubscriptions(
        [FromQuery] string? search,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        try
        {
            var query =
                from sub in _context.Set<ProviderSubscription>()
                join provider in _context.Set<Provider>() on sub.ProviderId equals provider.Id
                join plan in _context.Set<SubscriptionPlan>() on sub.PlanId equals plan.Id
                select new { sub, provider, plan };

            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(x => x.provider.FullName.ToLower().Contains(search.ToLower())
                                      || x.provider.Phone.Contains(search));

            if (!string.IsNullOrWhiteSpace(status))
                query = query.Where(x => x.sub.Status == status);

            var total = await query.CountAsync(ct);

            var activeCount = await _context.Set<ProviderSubscription>()
                .CountAsync(s => s.Status == "Active", ct);
            var pastDueCount = await _context.Set<ProviderSubscription>()
                .CountAsync(s => s.Status == "PastDue", ct);

            var items = await query
                .OrderByDescending(x => x.sub.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(x => new
                {
                    subscriptionId = x.sub.Id,
                    providerId = x.provider.Id,
                    providerName = x.provider.FullName,
                    providerPhone = x.provider.Phone,
                    planId = x.plan.Id,
                    planName = x.plan.Name,
                    status = x.sub.Status,
                    monthlyFee = x.plan.MonthlyFee,
                    commissionRate = x.plan.CommissionRate,
                    currentPeriodStart = x.sub.CurrentPeriodStart,
                    currentPeriodEnd = x.sub.CurrentPeriodEnd,
                    stripeSubscriptionId = x.sub.StripeSubscriptionId,
                    createdAt = x.sub.CreatedAt
                })
                .ToListAsync(ct);

            return Ok(new
            {
                success = true,
                data = new
                {
                    items,
                    total,
                    page,
                    pageSize,
                    activeCount,
                    pastDueCount
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching admin subscriptions");
            return StatusCode(500, new { success = false, error = "INTERNAL_ERROR" });
        }
    }
}
