using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record ResetPasswordCustomerCommand(
    string Phone,
    string Otp,
    string NewPassword
) : IRequest<Result<object>>;

public class ResetPasswordCustomerCommandHandler
    : IRequestHandler<ResetPasswordCustomerCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;

    public ResetPasswordCustomerCommandHandler(
        ICustomersRepository repository,
        IJwtService jwtService)
    {
        _repository = repository;
        _jwtService = jwtService;
    }

    public async Task<Result<object>> Handle(
        ResetPasswordCustomerCommand request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 8)
            return Result<object>.Fail("PASSWORD_TOO_SHORT");

        var customer = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (customer is null)
            return Result<object>.Fail("CUSTOMER_NOT_FOUND");

        var otpRecord = await _repository.GetLatestOtpAsync(customer.Id, cancellationToken);
        if (otpRecord is null)
            return Result<object>.Fail("OTP_EXPIRED");

        if (otpRecord.ExpiresAt <= DateTime.UtcNow)
        {
            await _repository.RemoveOtpAsync(otpRecord, cancellationToken);
            await _repository.SaveChangesAsync(cancellationToken);
            return Result<object>.Fail("OTP_EXPIRED");
        }

        if (otpRecord.Attempts >= 5)
            return Result<object>.Fail("MAX_ATTEMPTS_EXCEEDED");

        if (!_jwtService.VerifyPassword(request.Otp, otpRecord.OtpHash))
        {
            otpRecord.IncrementAttempts();
            await _repository.UpdateOtpAsync(otpRecord, cancellationToken);
            await _repository.SaveChangesAsync(cancellationToken);
            return Result<object>.Fail("OTP_INVALID");
        }

        // OTP valid — update password and clear OTP
        var newHash = _jwtService.HashPassword(request.NewPassword);
        customer.UpdatePassword(newHash);
        await _repository.UpdateAsync(customer, cancellationToken);
        await _repository.RemoveOtpAsync(otpRecord, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        return Result<object>.Ok(new { message = "Password reset successfully." });
    }
}
