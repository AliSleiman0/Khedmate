using Microsoft.Extensions.Logging;

namespace Khudmati.Shared.Application.Auth;

public class ConsoleOtpNotificationService : IOtpNotificationService
{
    private readonly ILogger<ConsoleOtpNotificationService> _logger;

    public ConsoleOtpNotificationService(ILogger<ConsoleOtpNotificationService> logger)
    {
        _logger = logger;
    }

    public Task SendOtpAsync(string phone, string? email, string otp, CancellationToken ct = default)
    {
        _logger.LogInformation("[OTP STUB] Sending OTP {otp} to phone={phone} email={email}", otp, phone, email);
        return Task.CompletedTask;
    }
}
