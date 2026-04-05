using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers.Jobs;

[ApiController]
[Route("api/jobs")]
[Authorize(Policy = "CustomerOrProvider")]
public class JobsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IProvidersRepository _providersRepo;

    public JobsController(IMediator mediator, IProvidersRepository providersRepo)
    {
        _mediator = mediator;
        _providersRepo = providersRepo;
    }

    // GET /api/jobs/{jobId}/status
    [HttpGet("{jobId:guid}/status")]
    public async Task<ActionResult<Result<JobStatusDto>>> GetJobStatus(
        Guid jobId, CancellationToken ct)
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? User.FindFirstValue("sub")
               ?? throw new UnauthorizedAccessException("Missing sub claim.");

        var userId = Guid.Parse(sub);
        var audience = User.FindFirstValue("aud") ?? string.Empty;

        var result = await _mediator.Send(new GetJobStatusQuery(jobId, userId, audience), ct);

        if (!result.Success)
            return NotFound(result);

        // Resolve provider name cross-module at the API layer
        var dto = result.Data!;
        if (dto.ProviderId.HasValue)
        {
            var provider = await _providersRepo.GetByIdAsync(dto.ProviderId.Value, ct);
            if (provider is not null)
            {
                var enriched = dto with { ProviderName = provider.FullName };
                return Ok(Result<JobStatusDto>.Ok(enriched));
            }
        }

        return Ok(result);
    }
}
