using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Modules.Bookings.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin/jobs")]
[Authorize(Policy = "AdminOnly")]
public class AdminJobsController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminJobsController(IMediator mediator) => _mediator = mediator;

    // GET /api/admin/jobs
    [HttpGet]
    public async Task<IActionResult> GetJobs(
        [FromQuery] string? search,
        [FromQuery] string? status,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        if (from.HasValue && to.HasValue && from.Value > to.Value)
            return BadRequest(new { success = false, error = "DATE_RANGE_INVALID" });

        JobStatus? statusEnum = null;
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<JobStatus>(status, true, out var parsed))
            statusEnum = parsed;

        var result = await _mediator.Send(
            new GetAdminJobsQuery(search, statusEnum, from, to, page, pageSize), ct);

        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        return Ok(new
        {
            success = true,
            data = new
            {
                items = result.Data!.Items,
                totalCount = result.Data.TotalCount,
                page = result.Data.Page,
                pageSize = result.Data.PageSize,
                stats = result.Data.Stats
            }
        });
    }

    // GET /api/admin/jobs/{jobId}
    [HttpGet("{jobId:guid}")]
    public async Task<IActionResult> GetJobDetail(Guid jobId, CancellationToken ct = default)
    {
        var result = await _mediator.Send(new GetAdminJobDetailQuery(jobId), ct);

        if (!result.Success)
        {
            return result.Error == "JOB_NOT_FOUND"
                ? NotFound(new { success = false, error = result.Error })
                : BadRequest(new { success = false, error = result.Error });
        }

        return Ok(new { success = true, data = result.Data });
    }

    // POST /api/admin/jobs/{jobId}/force-cancel
    [HttpPost("{jobId:guid}/force-cancel")]
    public async Task<IActionResult> ForceCancel(Guid jobId, CancellationToken ct = default)
    {
        var adminId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var result = await _mediator.Send(new AdminForceCancelJobCommand(jobId, adminId), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND" => NotFound(new { success = false, error = result.Error }),
                "CANNOT_CANCEL_JOB_IN_CURRENT_STATUS" => UnprocessableEntity(new { success = false, error = result.Error }),
                _ => BadRequest(new { success = false, error = result.Error })
            };
        }

        return Ok(new
        {
            success = true,
            data = new
            {
                jobId = result.Data!.JobId,
                newStatus = result.Data.NewStatus
            }
        });
    }
}
