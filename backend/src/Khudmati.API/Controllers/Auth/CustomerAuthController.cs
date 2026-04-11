using FluentValidation;
using Khudmati.Modules.Customers.Application.Commands.Auth;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Khudmati.API.Controllers.Auth;

[ApiController]
[Route("api/auth/customers")]
public class CustomerAuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public CustomerAuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterCustomerCommand command, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(command, ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpCommand command, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(command, ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginCustomerCommand command, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(command, ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp([FromBody] ResendOtpCommand command, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(command, ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshCustomerTokenCommand command, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(command, ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(new ForgotPasswordCustomerCommand(request.Phone), ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request, CancellationToken ct)
    {
        try
        {
            var result = await _mediator.Send(
                new ResetPasswordCustomerCommand(request.Phone, request.Otp, request.NewPassword), ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    [Authorize(Policy = "CustomerOrProvider")]
    [HttpPost("logout")]    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(sub, out var accountId))
            return Unauthorized(new { success = false, error = "INVALID_TOKEN" });

        try
        {
            var result = await _mediator.Send(new LogoutCustomerCommand(accountId), ct);
            return ResultToResponse(result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new { success = false, error = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage)) });
        }
    }

    private IActionResult ResultToResponse<T>(Result<T> result)
    {
        if (result.Success) return Ok(new { success = true, data = result.Data });
        return result.Error switch
        {
            "PHONE_ALREADY_REGISTERED" => Conflict(new { success = false, error = result.Error }),
            "EMAIL_ALREADY_REGISTERED" => Conflict(new { success = false, error = result.Error }),
            "INVALID_CREDENTIALS" => Unauthorized(new { success = false, error = result.Error }),
            "INVALID_REFRESH_TOKEN" => Unauthorized(new { success = false, error = result.Error }),
            "MAX_ATTEMPTS_EXCEEDED" or "RATE_LIMIT_EXCEEDED" => StatusCode(429, new { success = false, error = result.Error }),
            "NOT_FOUND" or "CUSTOMER_NOT_FOUND" => NotFound(new { success = false, error = result.Error }),
            _ => BadRequest(new { success = false, error = result.Error })
        };
    }
}

public record ForgotPasswordRequest(string Phone);
public record ResetPasswordRequest(string Phone, string Otp, string NewPassword);
