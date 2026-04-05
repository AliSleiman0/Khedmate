using System.Security.Claims;
using Khudmati.Modules.Providers.Application.Commands;
using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Application.Queries;
using Khudmati.Modules.Providers.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers.Providers;

[ApiController]
[Route("api/providers/onboarding")]
[Authorize(Policy = "ProviderOnly")]
public class ProviderOnboardingController : ControllerBase
{
    private readonly IMediator _mediator;

    public ProviderOnboardingController(IMediator mediator)
    {
        _mediator = mediator;
    }

    // GET /api/providers/onboarding/status
    [HttpGet("status")]
    public async Task<IActionResult> GetOnboardingStatus(CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _mediator.Send(new GetOnboardingStatusQuery(providerId), ct);

        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        return Ok(new { success = true, data = result.Data });
    }

    // POST /api/providers/onboarding/documents
    [HttpPost("documents")]
    public async Task<IActionResult> SubmitDocuments(
        [FromForm] string documentType,
        [FromForm] IFormFile frontImage,
        [FromForm] IFormFile? backImage,
        CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        if (!Enum.TryParse<DocumentType>(documentType, true, out var docType))
            return BadRequest(new { success = false, error = "INVALID_DOCUMENT_TYPE" });

        var command = new SubmitDocumentsCommand(providerId, docType, frontImage, backImage);
        var result = await _mediator.Send(command, ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "SUBMISSION_ALREADY_PENDING" => Conflict(new { success = false, error = result.Error }),
                "FILE_TOO_LARGE" => BadRequest(new { success = false, error = result.Error }),
                "UNSUPPORTED_FILE_TYPE" => BadRequest(new { success = false, error = result.Error }),
                _ => StatusCode(500, new { success = false, error = result.Error })
            };
        }

        return Ok(new { success = true, data = result.Data });
    }

    // GET /api/providers/skill-test/{categoryId}
    [HttpGet("skill-test/{categoryId}")]
    public async Task<IActionResult> GetSkillTest(string categoryId, CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var command = new StartSkillTestCommand(providerId, categoryId);
        var result = await _mediator.Send(command, ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "TEST_COOLDOWN_ACTIVE" => StatusCode(429, new { success = false, error = result.Error, retryAfter = result.Data }),
                _ => BadRequest(new { success = false, error = result.Error })
            };
        }

        return Ok(new { success = true, data = result.Data });
    }

    // POST /api/providers/skill-test/{categoryId}/submit
    [HttpPost("skill-test/{categoryId}/submit")]
    public async Task<IActionResult> SubmitSkillTest(
        string categoryId,
        [FromBody] SubmitSkillTestRequest request,
        CancellationToken ct)
    {
        var providerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var command = new SubmitSkillTestCommand(providerId, request.TestId, categoryId, request.Answers);
        var result = await _mediator.Send(command, ct);

        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        return Ok(new { success = true, data = result.Data });
    }
}

public record SubmitSkillTestRequest(
    Guid TestId,
    List<SkillTestAnswerDto> Answers
);
