using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers.Tracking;

[ApiController]
[Route("api/tracking")]
[Authorize(Policy = "ProviderOnly")]
public class TrackingController : ControllerBase
{
    private readonly IMediator _mediator;

    public TrackingController(IMediator mediator)
    {
        _mediator = mediator;
    }

    private Guid GetProviderId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? User.FindFirstValue("sub")
               ?? throw new UnauthorizedAccessException("Missing sub claim.");
        return Guid.Parse(sub);
    }

    // POST /api/tracking/jobs/{jobId}/location
    [HttpPost("jobs/{jobId:guid}/location")]
    public async Task<ActionResult<Result<bool>>> UpdateLocation(
        Guid jobId,
        [FromBody] UpdateLocationRequest request,
        CancellationToken ct)
    {
        var providerId = GetProviderId();
        var command = new UpdateProviderLocationCommand(
            jobId,
            providerId,
            request.Latitude,
            request.Longitude
        );

        var result = await _mediator.Send(command, ct);
        
        if (!result.Success)
        {
            return result.Error switch
            {
                "TRACKING_NOT_ACTIVE" => BadRequest(result),
                "JOB_NOT_FOUND" => NotFound(result),
                _ => BadRequest(result)
            };
        }

        return Ok(result);
    }
}

public record UpdateLocationRequest(double Latitude, double Longitude);
