using System.Security.Claims;
using System.Text.RegularExpressions;
using Khudmati.API.Domain;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Application.Auth;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/superadmin")]
[Authorize(Policy = "SuperAdminOnly")]
public class SuperAdminController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IJwtService _jwtService;
    private readonly ILogger<SuperAdminController> _logger;

    public SuperAdminController(AppDbContext context, IJwtService jwtService, ILogger<SuperAdminController> logger)
    {
        _context = context;
        _jwtService = jwtService;
        _logger = logger;
    }

    private Guid CallerAdminId =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Dashboard ─────────────────────────────────────────────────────────────

    // GET /api/superadmin/dashboard
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard(CancellationToken ct)
    {
        try
        {
            var now = DateTime.UtcNow;
            var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

            var totalCustomers = await _context.Set<Customer>().CountAsync(ct);
            var totalProviders = await _context.Set<Provider>().CountAsync(ct);

            var platformRevenueMtd = await _context.Set<Transaction>()
                .Where(t => t.Status == "Released" && t.CreatedAt >= monthStart)
                .SumAsync(t => (decimal?)t.CommissionAmount, ct) ?? 0m;

            var activeJobs = await _context.Set<Job>()
                .CountAsync(j => j.Status == JobStatus.Accepted || j.Status == JobStatus.EnRoute || j.Status == JobStatus.InProgress, ct);

            return Ok(new
            {
                success = true,
                data = new
                {
                    totalCustomers,
                    totalProviders,
                    platformRevenueMtd,
                    activeJobs
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching dashboard stats");
            return StatusCode(500, new { success = false, error = "INTERNAL_ERROR" });
        }
    }

    // ── Admin Management ──────────────────────────────────────────────────────

    // GET /api/superadmin/admins
    [HttpGet("admins")]
    public async Task<IActionResult> GetAdmins([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken ct = default)
    {
        var query = _context.Set<AdminAccount>()
            .OrderByDescending(a => a.CreatedAt);

        var total = await query.CountAsync(ct);
        var admins = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new
            {
                a.Id,
                a.Email,
                a.Role,
                a.IsActive,
                a.CreatedAt
            })
            .ToListAsync(ct);

        return Ok(new
        {
            success = true,
            data = new { admins, total, page, pageSize }
        });
    }

    // POST /api/superadmin/admins
    [HttpPost("admins")]
    public async Task<IActionResult> CreateAdmin([FromBody] CreateAdminRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Email) ||
            string.IsNullOrWhiteSpace(request.Password) ||
            string.IsNullOrWhiteSpace(request.Role))
            return BadRequest(new { success = false, error = "INVALID_REQUEST" });

        if (!IsValidPassword(request.Password))
            return BadRequest(new { success = false, error = "INVALID_PASSWORD_FORMAT" });

        var exists = await _context.Set<AdminAccount>()
            .AnyAsync(a => a.Email == request.Email.ToLower(), ct);
        if (exists)
            return BadRequest(new { success = false, error = "EMAIL_ALREADY_EXISTS" });

        var hash = _jwtService.HashPassword(request.Password);
        var admin = AdminAccount.Create(request.Email.ToLower(), hash, request.Role);
        await _context.Set<AdminAccount>().AddAsync(admin, ct);

        var audit = AuditLogEntry.Create(
            CallerAdminId,
            "CREATE",
            $"Created admin account {admin.Email} with role {admin.Role}",
            "AdminAccount",
            admin.Id.ToString());
        await _context.Set<AuditLogEntry>().AddAsync(audit, ct);

        await _context.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new { admin.Id, admin.Email, admin.Role }
        });
    }

    // PUT /api/superadmin/admins/{id}
    [HttpPut("admins/{id:guid}")]
    public async Task<IActionResult> UpdateAdmin(Guid id, [FromBody] UpdateAdminRequest request, CancellationToken ct)
    {
        if (id == CallerAdminId)
            return BadRequest(new { success = false, error = "CANNOT_MODIFY_SELF" });

        var admin = await _context.Set<AdminAccount>().FirstOrDefaultAsync(a => a.Id == id, ct);
        if (admin is null)
            return NotFound(new { success = false, error = "ADMIN_NOT_FOUND" });

        var oldRole = admin.Role;
        var wasActive = admin.IsActive;

        if (!string.IsNullOrWhiteSpace(request.Role) && request.Role != admin.Role)
            admin.UpdateRole(request.Role);

        if (request.IsActive && !wasActive)
            admin.Activate();
        else if (!request.IsActive && wasActive)
            admin.Deactivate();

        // Build descriptive audit message
        string auditDesc;
        if (oldRole != admin.Role)
            auditDesc = $"Changed role of {admin.Email} from {oldRole} to {admin.Role}";
        else if (!wasActive && admin.IsActive)
            auditDesc = $"Reactivated admin account {admin.Email}";
        else
            auditDesc = $"Updated admin account {admin.Email}";

        var audit = AuditLogEntry.Create(CallerAdminId, "UPDATE", auditDesc, "AdminAccount", id.ToString());
        await _context.Set<AuditLogEntry>().AddAsync(audit, ct);

        await _context.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new { admin.Id, admin.Role, admin.IsActive }
        });
    }

    // DELETE /api/superadmin/admins/{id}
    [HttpDelete("admins/{id:guid}")]
    public async Task<IActionResult> RevokeAdmin(Guid id, CancellationToken ct)
    {
        if (id == CallerAdminId)
            return BadRequest(new { success = false, error = "CANNOT_MODIFY_SELF" });

        var admin = await _context.Set<AdminAccount>().FirstOrDefaultAsync(a => a.Id == id, ct);
        if (admin is null)
            return NotFound(new { success = false, error = "ADMIN_NOT_FOUND" });

        if (!admin.IsActive)
            return BadRequest(new { success = false, error = "ALREADY_REVOKED" });

        admin.Deactivate();

        // Invalidate all active refresh tokens for this admin
        var tokens = await _context.Set<AdminRefreshToken>()
            .Where(t => t.AccountId == id)
            .ToListAsync(ct);
        _context.Set<AdminRefreshToken>().RemoveRange(tokens);

        var audit = AuditLogEntry.Create(CallerAdminId, "DELETE", $"Revoked admin account {admin.Email}", "AdminAccount", id.ToString());
        await _context.Set<AuditLogEntry>().AddAsync(audit, ct);

        await _context.SaveChangesAsync(ct);

        return Ok(new { success = true });
    }

    // ── Platform Config ───────────────────────────────────────────────────────

    // GET /api/superadmin/config
    [HttpGet("config")]
    public async Task<IActionResult> GetConfig(CancellationToken ct)
    {
        var config = await _context.Set<PlatformConfig>().FirstOrDefaultAsync(ct);
        if (config is null)
        {
            config = PlatformConfig.CreateDefaults();
            await _context.Set<PlatformConfig>().AddAsync(config, ct);
            await _context.SaveChangesAsync(ct);
        }

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

    // PUT /api/superadmin/config
    [HttpPut("config")]
    public async Task<IActionResult> UpdateConfig([FromBody] UpdateConfigRequest request, CancellationToken ct)
    {
        if (request.CommissionRate < 1 || request.CommissionRate > 50 ||
            request.JobTimeoutMinutes < 1 || request.JobTimeoutMinutes > 60 ||
            request.MaxProvidersPerArea < 1 || request.MaxProvidersPerArea > 100 ||
            request.MinRatingToRemain < 0 || request.MinRatingToRemain > 100 ||
            request.AutoRefundThresholdDays < 1 || request.AutoRefundThresholdDays > 30)
            return BadRequest(new { success = false, error = "INVALID_CONFIG_VALUE" });

        var config = await _context.Set<PlatformConfig>().FirstOrDefaultAsync(ct);
        if (config is null)
        {
            config = PlatformConfig.CreateDefaults();
            await _context.Set<PlatformConfig>().AddAsync(config, ct);
            await _context.SaveChangesAsync(ct);
        }

        config.Update(
            request.CommissionRate,
            request.JobTimeoutMinutes,
            request.MaxProvidersPerArea,
            request.MinRatingToRemain,
            request.AutoRefundThresholdDays,
            CallerAdminId);

        var audit = AuditLogEntry.Create(
            CallerAdminId,
            "UPDATE",
            $"Updated platform config: commission={request.CommissionRate}%, timeout={request.JobTimeoutMinutes}min",
            "PlatformConfig",
            "1");
        await _context.Set<AuditLogEntry>().AddAsync(audit, ct);

        await _context.SaveChangesAsync(ct);

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

    // ── Financials ────────────────────────────────────────────────────────────

    // GET /api/superadmin/financials
    [HttpGet("financials")]
    public async Task<IActionResult> GetFinancials(
        [FromQuery] string? from,
        [FromQuery] string? to,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var fromDate = string.IsNullOrWhiteSpace(from)
            ? new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc)
            : DateTime.Parse(from).ToUniversalTime();
        var toDate = string.IsNullOrWhiteSpace(to)
            ? new DateTime(now.Year, now.Month, DateTime.DaysInMonth(now.Year, now.Month), 23, 59, 59, DateTimeKind.Utc)
            : DateTime.Parse(to).ToUniversalTime().AddDays(1).AddSeconds(-1);

        var txQuery = _context.Set<Transaction>()
            .Where(t => t.CreatedAt >= fromDate && t.CreatedAt <= toDate);

        // Summary — across full date range
        var totalSettled = await txQuery
            .Where(t => t.Status == "Released")
            .SumAsync(t => (decimal?)t.GrossAmount, ct) ?? 0m;
        var totalPending = await txQuery
            .Where(t => t.Status == "Held" || t.Status == "Pending")
            .SumAsync(t => (decimal?)t.GrossAmount, ct) ?? 0m;
        var totalRefunded = await txQuery
            .Where(t => t.Status == "Refunded")
            .SumAsync(t => (decimal?)t.GrossAmount, ct) ?? 0m;

        var total = await txQuery.CountAsync(ct);

        // Paginated rows with joins
        var rows = await txQuery
            .OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Set<Job>(),
                  t => t.JobId,
                  j => j.Id,
                  (t, j) => new { t, j.ReferenceNumber })
            .Join(_context.Set<Customer>(),
                  tj => tj.t.CustomerId,
                  c => c.Id,
                  (tj, c) => new { tj.t, tj.ReferenceNumber, CustomerName = c.FullName })
            .Join(_context.Set<Provider>(),
                  tjc => tjc.t.ProviderId,
                  p => p.Id,
                  (tjc, p) => new
                  {
                      tjc.t.Id,
                      tjc.ReferenceNumber,
                      tjc.CustomerName,
                      ProviderName = p.FullName,
                      tjc.t.GrossAmount,
                      tjc.t.CommissionAmount,
                      NetPayout = tjc.t.NetAmount,
                      tjc.t.Status,
                      tjc.t.CreatedAt
                  })
            .ToListAsync(ct);

        return Ok(new
        {
            success = true,
            data = new
            {
                summary = new { totalSettled, totalPending, totalRefunded },
                transactions = rows,
                total,
                page,
                pageSize
            }
        });
    }

    // ── Audit Log ─────────────────────────────────────────────────────────────

    // GET /api/superadmin/audit
    [HttpGet("audit")]
    public async Task<IActionResult> GetAudit(
        [FromQuery] string? from,
        [FromQuery] string? to,
        [FromQuery] string? actionType,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var fromDate = string.IsNullOrWhiteSpace(from)
            ? new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc)
            : DateTime.Parse(from).ToUniversalTime();
        var toDate = string.IsNullOrWhiteSpace(to)
            ? new DateTime(now.Year, now.Month, DateTime.DaysInMonth(now.Year, now.Month), 23, 59, 59, DateTimeKind.Utc)
            : DateTime.Parse(to).ToUniversalTime().AddDays(1).AddSeconds(-1);

        var actionTypes = string.IsNullOrWhiteSpace(actionType)
            ? null
            : actionType.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        var query = _context.Set<AuditLogEntry>()
            .Where(a => a.CreatedAt >= fromDate && a.CreatedAt <= toDate);

        if (actionTypes is { Length: > 0 })
            query = query.Where(a => actionTypes.Contains(a.ActionType));

        var total = await query.CountAsync(ct);

        var entries = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Set<AdminAccount>(),
                  a => a.AdminId,
                  acc => acc.Id,
                  (a, acc) => new
                  {
                      a.Id,
                      AdminEmail = acc.Email,
                      a.ActionType,
                      a.Description,
                      a.TargetType,
                      a.TargetId,
                      a.CreatedAt
                  })
            .ToListAsync(ct);

        return Ok(new
        {
            success = true,
            data = new { entries, total, page, pageSize }
        });
    }

    // ── Subscription Plans ────────────────────────────────────────────────────

    // GET /api/superadmin/subscription-plans
    [HttpGet("subscription-plans")]
    public async Task<IActionResult> GetSubscriptionPlans(CancellationToken ct)
    {
        var plans = await _context.Set<SubscriptionPlan>()
            .OrderBy(p => p.CreatedAt)
            .Select(p => new
            {
                p.Id,
                p.Name,
                p.MonthlyFee,
                p.CommissionRate,
                p.PriorityDelaySeconds,
                p.IsActive,
                p.StripePriceId,
                p.UpdatedAt
            })
            .ToListAsync(ct);

        return Ok(new { success = true, data = plans });
    }

    // PATCH /api/superadmin/subscription-plans/{id}
    [HttpPatch("subscription-plans/{id:guid}")]
    public async Task<IActionResult> UpdateSubscriptionPlan(Guid id, [FromBody] UpdateSubscriptionPlanRequest request, CancellationToken ct)
    {
        var plan = await _context.Set<SubscriptionPlan>().FirstOrDefaultAsync(p => p.Id == id, ct);
        if (plan is null)
            return NotFound(new { success = false, error = "PLAN_NOT_FOUND" });

        if (request.CommissionRate.HasValue && (request.CommissionRate < 0 || request.CommissionRate > 100))
            return BadRequest(new { success = false, error = "INVALID_COMMISSION_RATE" });

        if (request.MonthlyFee.HasValue && request.MonthlyFee < 0)
            return BadRequest(new { success = false, error = "INVALID_MONTHLY_FEE" });

        if (request.PriorityDelaySeconds.HasValue && (request.PriorityDelaySeconds < 0 || request.PriorityDelaySeconds > 300))
            return BadRequest(new { success = false, error = "INVALID_PRIORITY_DELAY" });

        plan.Update(request.MonthlyFee, request.CommissionRate, request.PriorityDelaySeconds, request.StripePriceId, request.IsActive);

        var audit = AuditLogEntry.Create(
            CallerAdminId,
            "UPDATE_PLAN",
            $"Updated subscription plan '{plan.Name}': fee={plan.MonthlyFee} SAR, commission={plan.CommissionRate}%, delay={plan.PriorityDelaySeconds}s",
            "SubscriptionPlan",
            id.ToString());
        await _context.Set<AuditLogEntry>().AddAsync(audit, ct);

        await _context.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new
            {
                plan.Id,
                plan.Name,
                plan.MonthlyFee,
                plan.CommissionRate,
                plan.PriorityDelaySeconds,
                plan.IsActive,
                plan.StripePriceId,
                plan.UpdatedAt
            }
        });
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static bool IsValidPassword(string password) =>
        password.Length >= 8 &&
        password.Any(char.IsUpper) &&
        password.Any(char.IsLower) &&
        password.Any(char.IsDigit);
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

public record CreateAdminRequest(string Email, string Password, string Role);

public record UpdateAdminRequest(string Role, bool IsActive);

public record UpdateConfigRequest(
    int CommissionRate,
    int JobTimeoutMinutes,
    int MaxProvidersPerArea,
    int MinRatingToRemain,
    int AutoRefundThresholdDays);

public record UpdateSubscriptionPlanRequest(
    decimal? MonthlyFee,
    decimal? CommissionRate,
    int? PriorityDelaySeconds,
    string? StripePriceId,
    bool? IsActive);
