using System.Security.Claims;
using Khudmati.API.Domain;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Payments.Application.Commands;
using Khudmati.Modules.Payments.Application.Queries;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProvidersController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IProvidersRepository _providersRepo;
    private readonly AppDbContext _context;
    private readonly ILogger<ProvidersController> _logger;

    public ProvidersController(
        IMediator mediator,
        IProvidersRepository providersRepo,
        AppDbContext context,
        ILogger<ProvidersController> logger)
    {
        _mediator = mediator;
        _providersRepo = providersRepo;
        _context = context;
        _logger = logger;
    }

    // PATCH /api/providers/me — update own profile (provider only)
    [HttpPatch("me")]
    [Authorize(Policy = "ProviderOnly")]
    public async Task<IActionResult> UpdateMe([FromBody] UpdateProviderProfileRequest request, CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var provider = await _providersRepo.GetByIdAsync(providerId, ct);
        if (provider is null)
            return NotFound(new { success = false, error = "PROVIDER_NOT_FOUND" });

        if (string.IsNullOrWhiteSpace(request.FullName) || request.FullName.Trim().Length < 2)
            return BadRequest(new { success = false, error = "INVALID_FULL_NAME" });

        provider.UpdateFullName(request.FullName);
        await _providersRepo.UpdateAsync(provider, ct);
        await _providersRepo.SaveChangesAsync(ct);

        return Ok(new { success = true });
    }

    // GET /api/providers/{id} — public provider profile (any authenticated user)
    [HttpGet("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var provider = await _providersRepo.GetByIdAsync(id, ct);
        if (provider is null)
            return NotFound(new { success = false, error = "PROVIDER_NOT_FOUND" });

        return Ok(new
        {
            success = true,
            data = new
            {
                provider.Id,
                provider.FullName,
                provider.Phone,
                provider.Tier,
                provider.ServiceCategories,
                provider.Rating,
                provider.JobsCompleted,
                provider.CreatedAt
            }
        });
    }

    // GET /api/providers/earnings/summary
    [HttpGet("earnings/summary")]
    [Authorize(Policy = "ProviderOnly")]
    public async Task<IActionResult> GetEarningsSummary(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _mediator.Send(new GetProviderEarningsSummaryQuery(providerId), ct);
        return Ok(new { success = true, data = result.Data });
    }

    // POST /api/providers/stripe/onboard
    [HttpPost("stripe/onboard")]
    [Authorize(Policy = "ProviderOnly")]
    public async Task<IActionResult> StripeOnboard(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var provider = await _providersRepo.GetByIdAsync(providerId, ct);
        if (provider is null)
            return NotFound(new { success = false, error = "PROVIDER_NOT_FOUND" });

        var result = await _mediator.Send(
            new OnboardProviderStripeCommand(providerId, provider.Phone + "@stripe.khudmati.com"), ct);

        if (!result.Success)
            return StatusCode(422, new { success = false, error = result.Error });

        return Ok(new { success = true, data = new { onboardingUrl = result.Data!.OnboardingUrl } });
    }

    /// <summary>
    /// DELETE /api/providers/me — Apple 5.1.1(v) / Google Data Safety: user-initiated
    /// account deletion. Blocks when the provider has active jobs or an active
    /// subscription (they must cancel first). Anonymises PII, deletes refresh tokens,
    /// OTPs, device tokens, and location rows. Keeps completed-job history,
    /// transactions, ratings, and tier-history intact for the 7-year tax-law window
    /// via the anonymised foreign-key reference.
    /// </summary>
    [HttpDelete("me")]
    [Authorize(Policy = "ProviderOnly")]
    public async Task<IActionResult> DeleteMe(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var provider = await _providersRepo.GetByIdAsync(providerId, ct);
        if (provider is null)
            return NotFound(new { success = false, error = "PROVIDER_NOT_FOUND" });

        var hasActiveJob = await _context.Set<Job>().AnyAsync(
            j => j.ProviderId == providerId &&
                 (j.Status == JobStatus.Accepted ||
                  j.Status == JobStatus.EnRoute ||
                  j.Status == JobStatus.InProgress),
            ct);
        if (hasActiveJob)
            return Conflict(new { success = false, error = "HAS_ACTIVE_JOBS" });

        var hasActiveSubscription = await _context.Set<ProviderSubscription>().AnyAsync(
            s => s.ProviderId == providerId &&
                 (s.Status == "Active" || s.Status == "PastDue"),
            ct);
        if (hasActiveSubscription)
            return Conflict(new { success = false, error = "HAS_ACTIVE_SUBSCRIPTION" });

        await using var tx = await _context.Database.BeginTransactionAsync(ct);
        try
        {
            await _context.Set<ProviderRefreshToken>()
                .Where(t => t.AccountId == providerId).ExecuteDeleteAsync(ct);
            await _context.Set<ProviderOtpVerification>()
                .Where(o => o.AccountId == providerId).ExecuteDeleteAsync(ct);
            await _context.Set<DeviceToken>()
                .Where(d => d.OwnerId == providerId && d.OwnerType == "provider")
                .ExecuteDeleteAsync(ct);
            await _context.Set<ProviderLocation>()
                .Where(l => l.ProviderId == providerId).ExecuteDeleteAsync(ct);

            provider.SoftDeletePii();
            await _providersRepo.UpdateAsync(provider, ct);
            await _providersRepo.SaveChangesAsync(ct);

            await tx.CommitAsync(ct);
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync(ct);
            _logger.LogError(ex, "Failed to delete provider account {ProviderId}", providerId);
            return StatusCode(500, new { success = false, error = "DELETE_FAILED" });
        }

        _logger.LogInformation("Provider account {ProviderId} deleted via /me", providerId);
        return Ok(new { success = true });
    }
}

public record UpdateProviderProfileRequest(string FullName);
