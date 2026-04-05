using System.Security.Claims;
using Khudmati.Modules.Providers.Application.Commands;
using Khudmati.Modules.Providers.Application.Queries;
using Khudmati.Modules.Providers.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin/providers")]
[Authorize(Policy = "AdminOnly")]
public class AdminProvidersController : ControllerBase
{
    private readonly IMediator _mediator;

    public AdminProvidersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    // GET /api/admin/providers/verification-queue
    [HttpGet("verification-queue")]
    public async Task<IActionResult> GetVerificationQueue(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _mediator.Send(new GetVerificationQueueQuery(page, pageSize), ct);
        return Ok(new { success = true, data = result.Data });
    }

    // GET /api/admin/providers
    [HttpGet]
    public async Task<IActionResult> GetAllProviders(
        [FromQuery] string? tier,
        [FromQuery] string? categoryId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        VerificationTier? tierEnum = null;
        if (!string.IsNullOrWhiteSpace(tier) && Enum.TryParse<VerificationTier>(tier, true, out var parsedTier))
            tierEnum = parsedTier;

        var result = await _mediator.Send(new GetAllProvidersQuery(tierEnum, categoryId, page, pageSize), ct);

        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        return Ok(new
        {
            success = true,
            data = new
            {
                providers = result.Data.Providers,
                total = result.Data.Item2,
                page,
                pageSize
            }
        });
    }

    // POST /api/admin/providers/{providerId}/verify-documents
    [HttpPost("{providerId:guid}/verify-documents")]
    public async Task<IActionResult> VerifyDocuments(
        Guid providerId,
        [FromBody] VerifyDocumentsRequest request,
        CancellationToken ct)
    {
        var adminId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        if (request.Action == "approve")
        {
            var command = new ApproveProviderDocumentsCommand(adminId, providerId, request.SubmissionId);
            var result = await _mediator.Send(command, ct);

            if (!result.Success)
                return BadRequest(new { success = false, error = result.Error });

            return Ok(new { success = true, data = new { status = "approved" } });
        }
        else if (request.Action == "reject")
        {
            if (string.IsNullOrWhiteSpace(request.RejectionReason))
                return BadRequest(new { success = false, error = "REJECTION_REASON_REQUIRED" });

            var command = new RejectProviderDocumentsCommand(adminId, providerId, request.SubmissionId, request.RejectionReason);
            var result = await _mediator.Send(command, ct);

            if (!result.Success)
                return BadRequest(new { success = false, error = result.Error });

            return Ok(new { success = true, data = new { status = "rejected" } });
        }
        else
        {
            return BadRequest(new { success = false, error = "INVALID_ACTION" });
        }
    }
}

public record VerifyDocumentsRequest(
    Guid SubmissionId,
    string Action,  // "approve" or "reject"
    string? RejectionReason
);
