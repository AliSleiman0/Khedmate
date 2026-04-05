namespace Khudmati.Shared.Application.Auth;

public interface IJwtService
{
    string GenerateAccessToken(Guid userId, string audience, string? role = null, int expiryMinutes = 15);
    (Guid tokenId, string clientToken, string tokenHash) GenerateRefreshToken();
    bool VerifyTokenValue(string tokenValue, string tokenHash);
    string HashPassword(string password);
    bool VerifyPassword(string password, string hash);
}
