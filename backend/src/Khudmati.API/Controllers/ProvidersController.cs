using System.Security.Claims;
using Khudmati.Modules.Payments.Application.Commands;
using Khudmati.Modules.Payments.Application.Queries;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProvidersController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IProvidersRepository _providersRepo;

    public ProvidersController(IMediator mediator, IProvidersRepository providersRepo)
    {
        _mediator = mediator;
        _providersRepo = providersRepo;
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
}

public record UpdateProviderProfileRequest(string FullName);
