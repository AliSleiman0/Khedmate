using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record VerifyOtpCommand(
    string Phone,
    string Otp
) : IRequest<Result<object>>;

public class VerifyOtpCommandHandler : IRequestHandler<VerifyOtpCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;

    public VerifyOtpCommandHandler(ICustomersRepository repository, IJwtService jwtService)
    {
        _repository = repository;
        _jwtService = jwtService;
    }

    public async Task<Result<object>> Handle(VerifyOtpCommand request, CancellationToken cancellationToken)
    {
        var customer = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (customer is null)
            return Result<object>.Fail("CUSTOMER_NOT_FOUND");

        var otpRecord = await _repository.GetLatestOtpAsync(customer.Id, cancellationToken);
        if (otpRecord is null)
            return Result<object>.Fail("OTP_EXPIRED");

        if (otpRecord.ExpiresAt <= DateTime.UtcNow)
            return Result<object>.Fail("OTP_EXPIRED");

        if (otpRecord.Attempts >= 5)
            return Result<object>.Fail("MAX_ATTEMPTS_EXCEEDED");

        if (!_jwtService.VerifyTokenValue(request.Otp, otpRecord.OtpHash))
        {
            otpRecord.IncrementAttempts();
            await _repository.UpdateOtpAsync(otpRecord, cancellationToken);
            await _repository.SaveChangesAsync(cancellationToken);
            return Result<object>.Fail("INVALID_OTP");
        }

        await _repository.RemoveOtpAsync(otpRecord, cancellationToken);
        customer.SetVerified();
        await _repository.UpdateAsync(customer, cancellationToken);

        var accessToken = _jwtService.GenerateAccessToken(customer.Id, "customer", expiryMinutes: 15);
        var (tokenId, clientToken, tokenHash) = _jwtService.GenerateRefreshToken();
        var refreshTokenRecord = CustomerRefreshToken.Create(
            tokenId, customer.Id, tokenHash, DateTime.UtcNow.AddDays(30));
        await _repository.AddRefreshTokenAsync(refreshTokenRecord, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        return Result<object>.Ok(new
        {
            accessToken,
            refreshToken = $"{tokenId}:{clientToken}",
            customer = new
            {
                id = customer.Id,
                fullName = customer.FullName,
                phone = customer.Phone,
                email = customer.Email
            }
        });
    }
}
