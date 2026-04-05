using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands.Auth;

public record ResendProviderOtpCommand(string Phone) : IRequest<Result<object>>;

public class ResendProviderOtpCommandHandler : IRequestHandler<ResendProviderOtpCommand, Result<object>>
{
    private readonly IProvidersRepository _repository;
    private readonly IJwtService _jwtService;
    private readonly IOtpNotificationService _otpNotificationService;

    public ResendProviderOtpCommandHandler(
        IProvidersRepository repository,
        IJwtService jwtService,
        IOtpNotificationService otpNotificationService)
    {
        _repository = repository;
        _jwtService = jwtService;
        _otpNotificationService = otpNotificationService;
    }

    public async Task<Result<object>> Handle(ResendProviderOtpCommand request, CancellationToken cancellationToken)
    {
        var provider = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (provider is null)
            return Result<object>.Ok(new { message = "If the account exists, an OTP has been sent." });

        var rateLimitSince = DateTime.UtcNow.AddMinutes(-10);
        var recentAttempts = await _repository.CountRecentOtpResendAttemptsAsync(
            request.Phone, rateLimitSince, cancellationToken);
        if (recentAttempts >= 3)
            return Result<object>.Fail("RATE_LIMIT_EXCEEDED");

        var existingOtp = await _repository.GetLatestOtpAsync(provider.Id, cancellationToken);
        if (existingOtp is not null)
            await _repository.RemoveOtpAsync(existingOtp, cancellationToken);

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var otpHash = _jwtService.HashPassword(otp);
        var otpRecord = ProviderOtpVerification.Create(provider.Id, otpHash, DateTime.UtcNow.AddMinutes(10));
        await _repository.AddOtpAsync(otpRecord, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        await _otpNotificationService.SendOtpAsync(request.Phone, provider.Email, otp, cancellationToken);

        return Result<object>.Ok(new { message = "OTP sent" });
    }
}
