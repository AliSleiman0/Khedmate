using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin/disputes")]
[Authorize(Policy = "AdminOnly")]
public class AdminDisputesController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminDisputesController(IMediator mediator) => _mediator = mediator;

    private Guid GetAdminId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/admin/disputes
    [HttpGet]
    public async Task<IActionResult> GetDisputes(
        [FromQuery] string? status,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _mediator.Send(
            new GetAdminDisputesQuery(status, search, page, pageSize), ct);

        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        var data = result.Data!;
        return Ok(new
        {
            success = true,
            data = new
            {
                items       = data.Items,
                totalCount  = data.TotalCount,
                page        = data.Page,
                pageSize    = data.PageSize,
                openCount   = data.OpenCount,
                resolvedCount = data.ResolvedCount,
                rejectedCount = data.RejectedCount
            }
        });
    }

    // GET /api/admin/disputes/{disputeId}
    [HttpGet("{disputeId:guid}")]
    public async Task<IActionResult> GetDisputeDetail(Guid disputeId, CancellationToken ct = default)
    {
        var result = await _mediator.Send(new GetAdminDisputeDetailQuery(disputeId), ct);

        if (!result.Success)
        {
            return result.Error == "DISPUTE_NOT_FOUND"
                ? NotFound(new { success = false, error = result.Error })
                : BadRequest(new { success = false, error = result.Error });
        }

        return Ok(new { success = true, data = result.Data });
    }

    // POST /api/admin/disputes/{disputeId}/resolve
    [HttpPost("{disputeId:guid}/resolve")]
    public async Task<IActionResult> ResolveDispute(
        Guid disputeId,
        [FromBody] ResolveDisputeRequest request,
        CancellationToken ct = default)
    {
        var adminId = GetAdminId();
        var result = await _mediator.Send(
            new ResolveDisputeCommand(disputeId, request.Action, request.AdminNote, adminId), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "DISPUTE_NOT_FOUND"               => NotFound(new { success = false, error = result.Error }),
                "STRIPE_REFUND_FAILED"            => StatusCode(502, new { success = false, error = result.Error }),
                "PROVIDER_STRIPE_ACCOUNT_NOT_FOUND" => UnprocessableEntity(new { success = false, error = result.Error }),
                _                                 => UnprocessableEntity(new { success = false, error = result.Error })
            };
        }

        return Ok(new
        {
            success = true,
            data = new
            {
                disputeId = result.Data!.DisputeId,
                newStatus = result.Data.NewStatus
            }
        });
    }
}

public record ResolveDisputeRequest(string Action, string AdminNote);
