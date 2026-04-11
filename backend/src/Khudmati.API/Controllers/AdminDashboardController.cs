using Khudmati.API.Domain;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Policy = "AdminOnly")]
public class AdminDashboardController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ILogger<AdminDashboardController> _logger;

    public AdminDashboardController(AppDbContext context, ILogger<AdminDashboardController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET /api/admin/dashboard
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard(CancellationToken ct)
    {
        try
        {
            var today = DateTime.UtcNow.Date;
            var tomorrowUtc = today.AddDays(1);

            var totalJobs = await _context.Set<Job>().CountAsync(ct);

            var pendingJobs = await _context.Set<Job>()
                .CountAsync(j => j.Status == JobStatus.Pending, ct);

            var activeJobs = await _context.Set<Job>()
                .CountAsync(j => j.Status == JobStatus.Accepted
                               || j.Status == JobStatus.EnRoute
                               || j.Status == JobStatus.InProgress, ct);

            var openDisputes = await _context.Set<Dispute>()
                .CountAsync(d => d.Status == "Open", ct);

            var pendingVerifications = await _context.Set<DocumentSubmission>()
                .CountAsync(d => d.Status == DocumentStatus.PendingReview, ct);

            var todayRevenue = await _context.Set<Transaction>()
                .Where(t => t.Status == "Released"
                         && t.CreatedAt >= today
                         && t.CreatedAt < tomorrowUtc)
                .SumAsync(t => (decimal?)t.CommissionAmount, ct) ?? 0m;

            var recentJobs = await _context.Set<Job>()
                .OrderByDescending(j => j.CreatedAt)
                .Take(5)
                .Join(_context.Set<Customer>(),
                      j => j.CustomerId,
                      c => c.Id,
                      (j, c) => new
                      {
                          jobId = j.Id,
                          referenceNumber = j.ReferenceNumber,
                          customerName = c.FullName,
                          status = j.Status.ToString(),
                          createdAt = j.CreatedAt
                      })
                .ToListAsync(ct);

            return Ok(new
            {
                success = true,
                data = new
                {
                    totalJobs,
                    pendingJobs,
                    activeJobs,
                    openDisputes,
                    pendingVerifications,
                    todayRevenue,
                    recentJobs
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching admin dashboard stats");
            return StatusCode(500, new { success = false, error = "INTERNAL_ERROR" });
        }
    }

    // GET /api/admin/platform-config  (read-only for admins)
    [HttpGet("platform-config")]
    public async Task<IActionResult> GetPlatformConfig(CancellationToken ct)
    {
        var config = await _context.Set<PlatformConfig>().FirstOrDefaultAsync(ct)
                     ?? PlatformConfig.CreateDefaults();

        return Ok(new
        {
            success = true,
            data = new
            {
                config.CommissionRate,
                config.JobTimeoutMinutes,
                config.MaxProvidersPerArea,
                config.MinRatingToRemain,
                config.AutoRefundThresholdDays,
                config.UpdatedAt
            }
        });
    }
}
