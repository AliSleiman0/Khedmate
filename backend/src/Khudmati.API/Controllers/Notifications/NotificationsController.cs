using Khudmati.Modules.Notifications.Application.Commands;
using Khudmati.Modules.Notifications.Application.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Khudmati.API.Controllers.Notifications;

[ApiController]
[Route("api/notifications")]
[Authorize(Policy = "CustomerOrProvider")]
public class NotificationsController : ControllerBase
{
    private readonly IMediator _mediator;

    public NotificationsController(IMediator mediator) => _mediator = mediator;

    /// <summary>POST /api/notifications/device-token — upsert FCM token</summary>
    [HttpPost("device-token")]
    public async Task<IActionResult> RegisterDeviceToken(
        [FromBody] RegisterDeviceTokenRequest request,
        CancellationToken ct)
    {
        var (callerId, callerType) = GetCallerInfo();
        var result = await _mediator.Send(
            new RegisterDeviceTokenCommand(callerId, callerType, request.FcmToken, request.Platform),
            ct);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>GET /api/notifications — paginated inbox</summary>
    [HttpGet]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var (callerId, callerType) = GetCallerInfo();
        var result = await _mediator.Send(
            new GetNotificationsQuery(callerId, callerType, page, pageSize),
            ct);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>POST /api/notifications/{id}/read — mark read</summary>
    [HttpPost("{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id, CancellationToken ct)
    {
        var (callerId, _) = GetCallerInfo();
        var result = await _mediator.Send(
            new MarkNotificationReadCommand(id, callerId),
            ct);

        if (!result.Success)
        {
            if (result.Error == "FORBIDDEN") return Forbid();
            if (result.Error == "NOTIFICATION_NOT_FOUND") return NotFound(result);
            return BadRequest(result);
        }

        return Ok(result);
    }

    private (Guid id, string type) GetCallerInfo()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? string.Empty;
        var aud = User.FindFirstValue("aud") ?? string.Empty;
        return (Guid.Parse(sub), aud);
    }
}

public record RegisterDeviceTokenRequest(string FcmToken, string Platform);
