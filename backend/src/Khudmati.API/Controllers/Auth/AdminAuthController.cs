using Khudmati.API.Domain;
using Khudmati.API.Infrastructure;
using Khudmati.Shared.Application.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Khudmati.API.Controllers.Auth;

[ApiController]
[Route("api/auth/admin")]
public class AdminAuthController : ControllerBase
{
    private readonly IAdminRepository _adminRepo;
    private readonly IJwtService _jwtService;

    public AdminAuthController(IAdminRepository adminRepo, IJwtService jwtService)
    {
        _adminRepo = adminRepo;
        _jwtService = jwtService;
    }

    public record LoginRequest(string Email, string Password);
    public record RefreshRequest(string RefreshToken);

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new { success = false, error = "Email and password are required." });

        var admin = await _adminRepo.GetByEmailAsync(request.Email, ct);
        if (admin is null || !admin.IsActive)
            return Unauthorized(new { success = false, error = "INVALID_CREDENTIALS" });

        if (!_jwtService.VerifyPassword(request.Password, admin.PasswordHash))
            return Unauthorized(new { success = false, error = "INVALID_CREDENTIALS" });

        var existingToken = await _adminRepo.GetRefreshTokenByAccountIdAsync(admin.Id, ct);
        if (existingToken is not null)
            await _adminRepo.RemoveRefreshTokenAsync(existingToken, ct);

        var accessToken = _jwtService.GenerateAccessToken(admin.Id, admin.Role, role: admin.Role, expiryMinutes: 60);
        var (tokenId, clientToken, tokenHash) = _jwtService.GenerateRefreshToken();
        var refreshTokenRecord = AdminRefreshToken.Create(
            tokenId, admin.Id, tokenHash, DateTime.UtcNow.AddHours(8));
        await _adminRepo.AddRefreshTokenAsync(refreshTokenRecord, ct);
        await _adminRepo.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new
            {
                accessToken,
                refreshToken = $"{tokenId}:{clientToken}",
                admin = new
                {
                    id = admin.Id,
                    email = admin.Email,
                    role = admin.Role
                }
            }
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request, CancellationToken ct)
    {
        var parts = request.RefreshToken.Split(':', 2);
        if (parts.Length != 2 || !Guid.TryParse(parts[0], out var tokenId))
            return Unauthorized(new { success = false, error = "INVALID_REFRESH_TOKEN" });

        var plainToken = parts[1];

        var tokenRecord = await _adminRepo.GetRefreshTokenByIdAsync(tokenId, ct);
        if (tokenRecord is null)
            return Unauthorized(new { success = false, error = "INVALID_REFRESH_TOKEN" });

        if (tokenRecord.ExpiresAt <= DateTime.UtcNow)
            return Unauthorized(new { success = false, error = "INVALID_REFRESH_TOKEN" });

        if (!_jwtService.VerifyTokenValue(plainToken, tokenRecord.TokenHash))
            return Unauthorized(new { success = false, error = "INVALID_REFRESH_TOKEN" });

        var admin = await _adminRepo.GetByIdAsync(tokenRecord.AccountId, ct);
        if (admin is null || !admin.IsActive)
            return Unauthorized(new { success = false, error = "INVALID_REFRESH_TOKEN" });

        await _adminRepo.RemoveRefreshTokenAsync(tokenRecord, ct);

        var accessToken = _jwtService.GenerateAccessToken(admin.Id, admin.Role, role: admin.Role, expiryMinutes: 60);
        var (newTokenId, newClientToken, newTokenHash) = _jwtService.GenerateRefreshToken();
        var newRefreshToken = AdminRefreshToken.Create(
            newTokenId, admin.Id, newTokenHash, DateTime.UtcNow.AddHours(8));
        await _adminRepo.AddRefreshTokenAsync(newRefreshToken, ct);
        await _adminRepo.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new
            {
                accessToken,
                refreshToken = $"{newTokenId}:{newClientToken}"
            }
        });
    }

    [Authorize(Policy = "AdminOrSuperAdmin")]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(sub, out var accountId))
            return Unauthorized(new { success = false, error = "INVALID_TOKEN" });

        var tokenRecord = await _adminRepo.GetRefreshTokenByAccountIdAsync(accountId, ct);
        if (tokenRecord is not null)
        {
            await _adminRepo.RemoveRefreshTokenAsync(tokenRecord, ct);
            await _adminRepo.SaveChangesAsync(ct);
        }

        return Ok(new { success = true, data = new { message = "Logged out" } });
    }

    [Authorize(Policy = "AdminOrSuperAdmin")]
    [HttpGet("me")]
    public async Task<IActionResult> Me(CancellationToken ct)
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(sub, out var accountId))
            return Unauthorized(new { success = false, error = "INVALID_TOKEN" });

        var admin = await _adminRepo.GetByIdAsync(accountId, ct);
        if (admin is null)
            return NotFound(new { success = false, error = "NOT_FOUND" });

        return Ok(new
        {
            success = true,
            data = new
            {
                id = admin.Id,
                email = admin.Email,
                role = admin.Role
            }
        });
    }
}
