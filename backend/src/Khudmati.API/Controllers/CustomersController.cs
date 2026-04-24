using System.Security.Claims;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Customers.Application.Commands;
using Khudmati.Modules.Customers.Application.Queries;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/customers")]
public class CustomersController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly AppDbContext _context;
    private readonly ILogger<CustomersController> _logger;

    public CustomersController(
        IMediator mediator,
        AppDbContext context,
        ILogger<CustomersController> logger)
    {
        _mediator = mediator;
        _context = context;
        _logger = logger;
    }

    private Guid GetCustomerId() =>
        Guid.Parse(
            User.FindFirstValue(ClaimTypes.NameIdentifier)
         ?? User.FindFirstValue("sub")
         ?? throw new UnauthorizedAccessException("Missing sub claim."));

    // ── Admin endpoints ────────────────────────────────────────────────────

    [HttpGet]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _mediator.Send(new GetAllCustomersQuery(search, isActive, page, pageSize), ct);
        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        return Ok(new
        {
            success = true,
            data = new
            {
                customers = result.Data.Customers,
                total = result.Data.Total,
                page,
                pageSize
            }
        });
    }

    [HttpGet("{id:guid}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetCustomerByIdQuery(id), ct);
        if (!result.Success)
            return result.Error == "CUSTOMER_NOT_FOUND"
                ? NotFound(new { success = false, error = result.Error })
                : BadRequest(new { success = false, error = result.Error });

        return Ok(new { success = true, data = result.Data });
    }

    [HttpPatch("{id:guid}/deactivate")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
    {
        var result = await _mediator.Send(new DeactivateCustomerCommand(id), ct);
        if (!result.Success)
            return result.Error == "CUSTOMER_NOT_FOUND"
                ? NotFound(new { success = false, error = result.Error })
                : BadRequest(new { success = false, error = result.Error });

        return Ok(new { success = true });
    }

    // ── Customer referral endpoints ────────────────────────────────────────

    /// <summary>GET /api/customers/me/referral — returns this customer's referral code and credit balance.</summary>
    [HttpGet("me/referral")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> GetMyReferral(CancellationToken ct)
    {
        var result = await _mediator.Send(new GetReferralInfoQuery(GetCustomerId()), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>POST /api/customers/referral/apply — apply a referral code to this customer's account (once only).</summary>
    [HttpPost("referral/apply")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> ApplyReferralCode(
        [FromBody] ApplyReferralCodeRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(
            new ApplyReferralCodeCommand(GetCustomerId(), request.Code), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>
    /// DELETE /api/customers/me — Apple 5.1.1(v) / Google Data Safety: user-initiated
    /// account deletion. Anonymises PII, deletes refresh tokens + OTPs + device tokens,
    /// and keeps financial / audit rows (bookings, transactions, ratings, referrals)
    /// intact with the anonymised foreign-key reference for the 7-year tax-law window.
    /// </summary>
    [HttpDelete("me")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> DeleteMe(CancellationToken ct)
    {
        var customerId = GetCustomerId();

        var customer = await _context.Set<Customer>()
            .FirstOrDefaultAsync(c => c.Id == customerId, ct);
        if (customer is null)
            return NotFound(new { success = false, error = "CUSTOMER_NOT_FOUND" });

        var hasActiveJob = await _context.Set<Job>().AnyAsync(
            j => j.CustomerId == customerId &&
                 (j.Status == JobStatus.Pending ||
                  j.Status == JobStatus.Accepted ||
                  j.Status == JobStatus.EnRoute ||
                  j.Status == JobStatus.InProgress),
            ct);
        if (hasActiveJob)
            return Conflict(new { success = false, error = "HAS_ACTIVE_JOBS" });

        await using var tx = await _context.Database.BeginTransactionAsync(ct);
        try
        {
            await _context.Set<CustomerRefreshToken>()
                .Where(t => t.AccountId == customerId).ExecuteDeleteAsync(ct);
            await _context.Set<OtpVerification>()
                .Where(o => o.AccountId == customerId).ExecuteDeleteAsync(ct);
            await _context.Set<DeviceToken>()
                .Where(d => d.OwnerId == customerId && d.OwnerType == "customer")
                .ExecuteDeleteAsync(ct);

            customer.SoftDeletePii();
            await _context.SaveChangesAsync(ct);

            await tx.CommitAsync(ct);
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync(ct);
            _logger.LogError(ex, "Failed to delete customer account {CustomerId}", customerId);
            return StatusCode(500, new { success = false, error = "DELETE_FAILED" });
        }

        _logger.LogInformation("Customer account {CustomerId} deleted via /me", customerId);
        return Ok(new { success = true });
    }
}

public record ApplyReferralCodeRequest(string Code);

