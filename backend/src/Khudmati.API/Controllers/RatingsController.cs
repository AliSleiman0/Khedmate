using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Modules.Providers.Application.Queries;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/ratings")]
public class RatingsController : ControllerBase
{
    private readonly IMediator _mediator;

    public RatingsController(IMediator mediator) => _mediator = mediator;

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub")
                ?? throw new UnauthorizedAccessException("Missing sub claim."));

    private string GetAudience() =>
        User.FindFirstValue("aud") ?? string.Empty;

    // POST /api/ratings
    [HttpPost]
    [Authorize(Policy = "CustomerOrProvider")]
    public async Task<IActionResult> SubmitRating(
        [FromBody] SubmitRatingRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        var raterType = GetAudience(); // "customer" or "provider"

        var result = await _mediator.Send(
            new SubmitRatingCommand(request.JobId, userId, raterType, request.IsPositive, request.Tags ?? []),
            ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND"              => NotFound(new { success = false, error = result.Error }),
                "ALREADY_RATED"              => Conflict(new { success = false, error = result.Error }),
                "JOB_NOT_ELIGIBLE_FOR_RATING" => BadRequest(new { success = false, error = result.Error }),
                "RATING_WINDOW_EXPIRED"      => BadRequest(new { success = false, error = result.Error }),
                _                            => BadRequest(new { success = false, error = result.Error })
            };
        }

        return Ok(new { success = true, data = result.Data });
    }

    // GET /api/ratings/pending
    [HttpGet("pending")]
    [Authorize(Policy = "CustomerOrProvider")]
    public async Task<IActionResult> GetPendingRatings(CancellationToken ct)
    {
        var userId = GetUserId();
        var raterType = GetAudience();

        var result = await _mediator.Send(new GetPendingRatingsQuery(userId, raterType), ct);
        return Ok(new { success = true, data = result.Data });
    }

    // GET /api/providers/{providerId}/rating
    [HttpGet("/api/providers/{providerId:guid}/rating")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProviderRating(Guid providerId, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetProviderRatingQuery(providerId), ct);
        return Ok(new { success = true, data = result.Data });
    }
}

public record SubmitRatingRequest(Guid JobId, bool IsPositive, IReadOnlyList<string>? Tags);
