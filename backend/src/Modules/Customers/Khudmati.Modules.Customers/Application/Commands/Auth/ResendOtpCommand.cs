using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record ResendOtpCommand(string Phone) : IRequest<Result<object>>;

public class ResendOtpCommandHandler : IRequestHandler<ResendOtpCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;
    private readonly IOtpNotificationService _otpNotificationService;

    public ResendOtpCommandHandler(
        ICustomersRepository repository,
        IJwtService jwtService,
        IOtpNotificationService otpNotificationService)
    {
        _repository = repository;
        _jwtService = jwtService;
        _otpNotificationService = otpNotificationService;
    }

    public async Task<Result<object>> Handle(ResendOtpCommand request, CancellationToken cancellationToken)
    {
        var customer = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (customer is null)
            return Result<object>.Ok(new { message = "If the account exists, an OTP has been sent." });

        var rateLimitSince = DateTime.UtcNow.AddMinutes(-10);
        var recentAttempts = await _repository.CountRecentOtpResendAttemptsAsync(
            request.Phone, rateLimitSince, cancellationToken);
        if (recentAttempts >= 3)
            return Result<object>.Fail("RATE_LIMIT_EXCEEDED");

        var existingOtp = await _repository.GetLatestOtpAsync(customer.Id, cancellationToken);
        if (existingOtp is not null)
            await _repository.RemoveOtpAsync(existingOtp, cancellationToken);

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var otpHash = _jwtService.HashPassword(otp);
        var otpRecord = OtpVerification.Create(customer.Id, otpHash, DateTime.UtcNow.AddMinutes(10));
        await _repository.AddOtpAsync(otpRecord, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        await _otpNotificationService.SendOtpAsync(request.Phone, customer.Email, otp, cancellationToken);

        return Result<object>.Ok(new { message = "OTP sent" });
    }
}
