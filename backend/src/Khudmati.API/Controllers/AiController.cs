using Khudmati.API.Services;
using Khudmati.Shared.Application;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize(Policy = "CustomerOnly")]
public class AiController : ControllerBase
{
    private readonly IGrokService _grokService;
    private readonly bool _aiAssistEnabled;

    public AiController(IGrokService grokService, IConfiguration configuration)
    {
        _grokService = grokService;
        _aiAssistEnabled = configuration.GetValue<bool>("Features:AiAssist");
    }

    /// <summary>
    /// Accepts a rough booking description and returns a polished version via Grok AI.
    /// Requires customer JWT. Returns 503 if the feature flag is disabled.
    /// </summary>
    [HttpPost("improve-description")]
    public async Task<ActionResult<Result<ImproveDescriptionResponseDto>>> ImproveDescription(
        [FromBody] ImproveDescriptionRequestDto request,
        CancellationToken ct)
    {
        if (!_aiAssistEnabled)
            return StatusCode(503, Result<ImproveDescriptionResponseDto>.Fail("AI_ASSIST_DISABLED"));

        if (string.IsNullOrWhiteSpace(request.RoughDescription))
            return BadRequest(Result<ImproveDescriptionResponseDto>.Fail("INVALID_REQUEST"));

        if (request.RoughDescription.Length > 500)
            return BadRequest(Result<ImproveDescriptionResponseDto>.Fail("DESCRIPTION_TOO_LONG"));

        var improved = await _grokService.ImproveDescriptionAsync(
            request.RoughDescription.Trim(),
            request.CategoryName?.Trim() ?? string.Empty,
            ct);

        if (improved is null)
            return StatusCode(502, Result<ImproveDescriptionResponseDto>.Fail("AI_SERVICE_ERROR"));

        return Ok(Result<ImproveDescriptionResponseDto>.Ok(
            new ImproveDescriptionResponseDto(improved)));
    }
}

public record ImproveDescriptionRequestDto(
    string RoughDescription,
    string? CategoryName);

public record ImproveDescriptionResponseDto(
    string ImprovedDescription);
