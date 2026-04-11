using System.Security.Claims;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers.Providers;

[ApiController]
[Route("api/providers/me/analytics")]
[Authorize(Policy = "ProviderOnly")]
public class ProviderAnalyticsController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProviderAnalyticsController(AppDbContext context) => _context = context;

    private static (DateTime from, DateTime? prevFrom, DateTime? prevTo) GetPeriodRange(string period)
    {
        var now = DateTime.UtcNow;
        return period switch
        {
            "Last7Days"    => (now.AddDays(-7),   now.AddDays(-14),  now.AddDays(-7)),
            "Last3Months"  => (now.AddMonths(-3),  now.AddMonths(-6),  now.AddMonths(-3)),
            "AllTime"      => (DateTime.MinValue, null, null),
            _              => (now.AddDays(-30),  now.AddDays(-60),  now.AddDays(-30)), // Last30Days default
        };
    }

    // GET /api/providers/me/analytics/earnings?period=Last30Days
    [HttpGet("earnings")]
    public async Task<IActionResult> GetEarnings([FromQuery] string period = "Last30Days", CancellationToken ct = default)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var (from, prevFrom, prevTo) = GetPeriodRange(period);

        // Current period released transactions
        var txQuery = _context.Set<Transaction>()
            .Where(t => t.ProviderId == providerId);

        var currentReleased = await txQuery
            .Where(t => t.Status == "Released" && t.CreatedAt >= from)
            .Select(t => new { t.NetAmount, t.CreatedAt })
            .ToListAsync(ct);

        double? prevEarnings = null;
        double? changePercent = null;

        if (prevFrom.HasValue && prevTo.HasValue)
        {
            var prev = await txQuery
                .Where(t => t.Status == "Released" && t.CreatedAt >= prevFrom && t.CreatedAt < prevTo)
                .SumAsync(t => (double?)t.NetAmount, ct) ?? 0;

            prevEarnings = prev;
            var current = currentReleased.Sum(t => (double)t.NetAmount);
            if (prev > 0)
                changePercent = Math.Round((current - prev) / prev * 100, 1);
        }

        var pending = await txQuery
            .Where(t => t.Status == "Held")
            .SumAsync(t => (double?)t.NetAmount, ct) ?? 0;

        // Group by day for chart data points
        string truncUnit = period switch
        {
            "Last7Days"   => "day",
            "Last30Days"  => "day",
            "Last3Months" => "week",
            "AllTime"     => "month",
            _             => "day"
        };

        IEnumerable<object> chartPoints;
        if (truncUnit == "day")
        {
            chartPoints = currentReleased
                .GroupBy(t => t.CreatedAt.Date)
                .OrderBy(g => g.Key)
                .Select(g => (object)new { date = g.Key, amount = g.Sum(t => (double)t.NetAmount) });
        }
        else if (truncUnit == "week")
        {
            chartPoints = currentReleased
                .GroupBy(t => t.CreatedAt.Date.AddDays(-(int)t.CreatedAt.DayOfWeek))
                .OrderBy(g => g.Key)
                .Select(g => (object)new { date = g.Key, amount = g.Sum(t => (double)t.NetAmount) });
        }
        else
        {
            chartPoints = currentReleased
                .GroupBy(t => new DateTime(t.CreatedAt.Year, t.CreatedAt.Month, 1))
                .OrderBy(g => g.Key)
                .Select(g => (object)new { date = g.Key, amount = g.Sum(t => (double)t.NetAmount) });
        }

        Response.Headers.CacheControl = "max-age=300";

        return Ok(new
        {
            success = true,
            data = new
            {
                currentPeriodEarnings = currentReleased.Sum(t => (double)t.NetAmount),
                previousPeriodEarnings = prevEarnings,
                changePercent,
                pendingEarnings = pending,
                currency = "SAR",
                chartDataPoints = chartPoints.ToList(),
            }
        });
    }

    // GET /api/providers/me/analytics/jobs?period=Last30Days
    [HttpGet("jobs")]
    public async Task<IActionResult> GetJobStats([FromQuery] string period = "Last30Days", CancellationToken ct = default)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var (from, _, _) = GetPeriodRange(period);

        // Jobs where this provider participated (accepted, or explicitly rejected)
        var assignedJobs = await _context.Set<Job>()
            .Where(j => j.ProviderId == providerId && (from == DateTime.MinValue || j.CreatedAt >= from))
            .Select(j => new { j.Status, j.CategoryId, j.CreatedAt })
            .ToListAsync(ct);

        var rejections = await _context.Set<JobRejection>()
            .Where(r => r.ProviderId == providerId && (from == DateTime.MinValue || r.RejectedAt >= from))
            .CountAsync(ct);

        var completedJobs = assignedJobs.Count(j => j.Status == JobStatus.Paid);
        var expiredJobs = assignedJobs.Count(j => j.Status == JobStatus.Pending); // jobs that timed out while assigned

        // Acceptance rate: completed / (completed + rejected + expired)
        var total = completedJobs + rejections + expiredJobs;
        var acceptanceRate = total > 0 ? Math.Round((double)completedJobs / total * 100, 1) : 0.0;

        // Average net job value from released transactions
        var avgNet = await _context.Set<Transaction>()
            .Where(t => t.ProviderId == providerId && t.Status == "Released" && (from == DateTime.MinValue || t.CreatedAt >= from))
            .AverageAsync(t => (double?)t.NetAmount, ct) ?? 0;

        // Top categories by completed job count
        var topCategories = assignedJobs
            .Where(j => j.Status == JobStatus.Paid)
            .GroupBy(j => j.CategoryId)
            .OrderByDescending(g => g.Count())
            .Take(5)
            .Select((g, i) => new
            {
                categoryId = g.Key,
                categoryName = g.Key, // client resolves the display name
                jobCount = g.Count(),
            })
            .ToList();

        Response.Headers.CacheControl = "max-age=300";

        return Ok(new
        {
            success = true,
            data = new
            {
                completedJobs,
                rejectedJobs = rejections,
                expiredJobs,
                acceptanceRate,
                avgJobValueNet = Math.Round(avgNet, 2),
                currency = "SAR",
                topCategories,
            }
        });
    }

    // GET /api/providers/me/analytics/ratings
    [HttpGet("ratings")]
    public async Task<IActionResult> GetRatingStats(CancellationToken ct = default)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var stats = await _context.Set<ProviderRatingStats>()
            .FirstOrDefaultAsync(r => r.ProviderId == providerId, ct);

        // Last 10 customer→provider ratings for sparkline
        var recentRatings = await _context.Set<Rating>()
            .Where(r => r.RateeId == providerId && r.RaterType == "customer")
            .OrderByDescending(r => r.SubmittedAt)
            .Take(10)
            .Select(r => new { r.IsPositive, date = r.SubmittedAt })
            .ToListAsync(ct);

        // Top negative tags (from recent negative ratings)
        var negativeTagsList = await _context.Set<Rating>()
            .Where(r => r.RateeId == providerId && r.RaterType == "customer" && !r.IsPositive)
            .OrderByDescending(r => r.SubmittedAt)
            .Take(50)
            .Select(r => r.Tags)
            .ToListAsync(ct);

        var topNegativeTags = negativeTagsList
            .SelectMany(t => t)
            .GroupBy(t => t)
            .OrderByDescending(g => g.Count())
            .Take(3)
            .Select(g => g.Key)
            .ToList();

        double? positiveRatePct = stats?.TotalRatings > 0
            ? Math.Round((double)stats.PositiveCount / stats.TotalRatings * 100, 1)
            : null;

        Response.Headers.CacheControl = "max-age=300";

        return Ok(new
        {
            success = true,
            data = new
            {
                positiveRatePct,
                totalRatings = stats?.TotalRatings ?? 0,
                positiveCount = stats?.PositiveCount ?? 0,
                topPositiveTags = stats?.TopTags?.Take(3).ToList() ?? (IEnumerable<string>)[],
                topNegativeTags,
                recentRatings = recentRatings.Select(r => new { r.IsPositive, r.date }).ToList(),
            }
        });
    }
}
