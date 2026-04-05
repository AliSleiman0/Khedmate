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

    [HttpGet]
    [Authorize(Policy = "AdminOnly")]
    public IActionResult GetAll() =>
        Ok(new { message = "List providers — TODO: wire MediatR query" });

    [HttpGet("{id:guid}")]
    [Authorize]
    public IActionResult GetById(Guid id) =>
        Ok(new { message = $"Get provider {id} — TODO: wire MediatR query" });

    [HttpPatch("{id:guid}/tier")]
    [Authorize(Policy = "AdminOnly")]
    public IActionResult UpgradeTier(Guid id, [FromBody] int newTier) =>
        Ok(new { message = $"Upgrade provider {id} to tier {newTier} — TODO: wire MediatR command" });

    [HttpPatch("{id:guid}/online")]
    [Authorize(Policy = "CustomerOrProvider")]
    public IActionResult SetOnline(Guid id, [FromBody] bool online) =>
        Ok(new { message = $"Set provider {id} online={online} — TODO: wire MediatR command" });

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
