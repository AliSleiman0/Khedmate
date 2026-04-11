using System.Security.Claims;
using Khudmati.Modules.Customers.Application.Commands;
using Khudmati.Modules.Customers.Application.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/customers")]
public class CustomersController : ControllerBase
{
    private readonly IMediator _mediator;

    public CustomersController(IMediator mediator) => _mediator = mediator;

    private Guid GetCustomerId() =>
        Guid.Parse(
            User.FindFirstValue(ClaimTypes.NameIdentifier)
         ?? User.FindFirstValue("sub")
         ?? throw new UnauthorizedAccessException("Missing sub claim."));

    // ── Admin endpoints ────────────────────────────────────────────────────

    [HttpGet]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _mediator.Send(new GetAllCustomersQuery(search, isActive, page, pageSize), ct);
        if (!result.Success)
            return BadRequest(new { success = false, error = result.Error });

        return Ok(new
        {
            success = true,
            data = new
            {
                customers = result.Data.Customers,
                total = result.Data.Total,
                page,
                pageSize
            }
        });
    }

    [HttpGet("{id:guid}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetCustomerByIdQuery(id), ct);
        if (!result.Success)
            return result.Error == "CUSTOMER_NOT_FOUND"
                ? NotFound(new { success = false, error = result.Error })
                : BadRequest(new { success = false, error = result.Error });

        return Ok(new { success = true, data = result.Data });
    }

    [HttpPatch("{id:guid}/deactivate")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
    {
        var result = await _mediator.Send(new DeactivateCustomerCommand(id), ct);
        if (!result.Success)
            return result.Error == "CUSTOMER_NOT_FOUND"
                ? NotFound(new { success = false, error = result.Error })
                : BadRequest(new { success = false, error = result.Error });

        return Ok(new { success = true });
    }

    // ── Customer referral endpoints ────────────────────────────────────────

    /// <summary>GET /api/customers/me/referral — returns this customer's referral code and credit balance.</summary>
    [HttpGet("me/referral")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> GetMyReferral(CancellationToken ct)
    {
        var result = await _mediator.Send(new GetReferralInfoQuery(GetCustomerId()), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    /// <summary>POST /api/customers/referral/apply — apply a referral code to this customer's account (once only).</summary>
    [HttpPost("referral/apply")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> ApplyReferralCode(
        [FromBody] ApplyReferralCodeRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(
            new ApplyReferralCodeCommand(GetCustomerId(), request.Code), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}

public record ApplyReferralCodeRequest(string Code);

