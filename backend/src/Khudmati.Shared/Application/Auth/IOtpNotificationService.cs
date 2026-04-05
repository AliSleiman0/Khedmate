namespace Khudmati.Shared.Application.Auth;

public interface IOtpNotificationService
{
    Task SendOtpAsync(string phone, string? email, string otp, CancellationToken ct = default);
}
