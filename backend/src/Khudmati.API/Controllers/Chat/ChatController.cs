using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers.Chat;

[ApiController]
[Route("api/chat")]
[Authorize(Policy = "CustomerOrProvider")]
public class ChatController : ControllerBase
{
    private readonly IMediator _mediator;

    public ChatController(IMediator mediator) => _mediator = mediator;

    private Guid GetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? User.FindFirstValue("sub")
               ?? throw new UnauthorizedAccessException("Missing sub claim.");
        return Guid.Parse(sub);
    }

    private string GetUserType()
    {
        var aud = User.FindFirstValue("aud") ?? string.Empty;
        return aud == "provider" ? "provider" : "customer";
    }

    // GET /api/chat/jobs/{jobId}/messages?page=1&pageSize=50
    [HttpGet("jobs/{jobId:guid}/messages")]
    public async Task<ActionResult<Result<ChatMessagesPageDto>>> GetMessages(
        Guid jobId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken ct = default)
    {
        var userId = GetUserId();
        var userType = GetUserType();

        var result = await _mediator.Send(
            new GetChatMessagesQuery(jobId, userId, userType, page, pageSize), ct);

        return result.Success
            ? Ok(result)
            : result.Error == "FORBIDDEN" ? Forbid() : NotFound(result);
    }

    // POST /api/chat/jobs/{jobId}/messages
    [HttpPost("jobs/{jobId:guid}/messages")]
    public async Task<ActionResult<Result<SendMessageResponseDto>>> SendMessage(
        Guid jobId,
        [FromBody] SendMessageRequest request,
        CancellationToken ct)
    {
        var userId = GetUserId();
        var userType = GetUserType();

        var result = await _mediator.Send(
            new SendChatMessageCommand(jobId, userId, userType, request.Text), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND" => NotFound(result),
                "FORBIDDEN" => Forbid(),
                _ => BadRequest(result)
            };
        }

        return Ok(result);
    }

    // POST /api/chat/jobs/{jobId}/read
    [HttpPost("jobs/{jobId:guid}/read")]
    public async Task<ActionResult<Result>> MarkRead(
        Guid jobId,
        CancellationToken ct)
    {
        var userId = GetUserId();
        var userType = GetUserType();

        var result = await _mediator.Send(
            new MarkMessagesReadCommand(jobId, userId, userType), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND" => NotFound(result),
                "FORBIDDEN" => Forbid(),
                _ => BadRequest(result)
            };
        }

        return Ok(result);
    }

    // GET /api/chat/jobs/{jobId}/unread-count
    [HttpGet("jobs/{jobId:guid}/unread-count")]
    public async Task<ActionResult<Result<UnreadCountDto>>> GetUnreadCount(
        Guid jobId,
        CancellationToken ct)
    {
        var userId = GetUserId();
        var userType = GetUserType();

        var result = await _mediator.Send(
            new GetUnreadMessageCountQuery(jobId, userId, userType), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND" => NotFound(result),
                "FORBIDDEN" => Forbid(),
                _ => BadRequest(result)
            };
        }

        return Ok(result);
    }
}

public record SendMessageRequest(string Text);
