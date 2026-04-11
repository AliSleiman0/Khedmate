using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record ForgotPasswordCustomerCommand(string Phone) : IRequest<Result<object>>;

public class ForgotPasswordCustomerCommandHandler
    : IRequestHandler<ForgotPasswordCustomerCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;
    private readonly IOtpNotificationService _otpNotificationService;

    public ForgotPasswordCustomerCommandHandler(
        ICustomersRepository repository,
        IJwtService jwtService,
        IOtpNotificationService otpNotificationService)
    {
        _repository = repository;
        _jwtService = jwtService;
        _otpNotificationService = otpNotificationService;
    }

    public async Task<Result<object>> Handle(
        ForgotPasswordCustomerCommand request,
        CancellationToken cancellationToken)
    {
        // Always return success to avoid phone enumeration
        var customer = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (customer is null)
            return Result<object>.Ok(new { message = "If the phone is registered, an OTP has been sent." });

        // Remove any existing OTP
        var existingOtp = await _repository.GetLatestOtpAsync(customer.Id, cancellationToken);
        if (existingOtp is not null)
            await _repository.RemoveOtpAsync(existingOtp, cancellationToken);

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var otpHash = _jwtService.HashPassword(otp);
        var otpRecord = OtpVerification.Create(customer.Id, otpHash, DateTime.UtcNow.AddMinutes(10));
        await _repository.AddOtpAsync(otpRecord, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        await _otpNotificationService.SendOtpAsync(request.Phone, customer.Email, otp, cancellationToken);

        return Result<object>.Ok(new { message = "If the phone is registered, an OTP has been sent." });
    }
}
