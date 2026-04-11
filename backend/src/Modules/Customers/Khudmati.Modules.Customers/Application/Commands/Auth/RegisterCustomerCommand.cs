using System.Security.Cryptography;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record RegisterCustomerCommand(
    string Phone,
    string Email,
    string FullName,
    string Password
) : IRequest<Result<object>>;

public class RegisterCustomerCommandHandler : IRequestHandler<RegisterCustomerCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;
    private readonly IOtpNotificationService _otpNotificationService;

    public RegisterCustomerCommandHandler(
        ICustomersRepository repository,
        IJwtService jwtService,
        IOtpNotificationService otpNotificationService)
    {
        _repository = repository;
        _jwtService = jwtService;
        _otpNotificationService = otpNotificationService;
    }

    public async Task<Result<object>> Handle(RegisterCustomerCommand request, CancellationToken cancellationToken)
    {
        var existing = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (existing is not null)
            return Result<object>.Fail("PHONE_ALREADY_REGISTERED");

        if (!string.IsNullOrWhiteSpace(request.Email))
        {
            var existingByEmail = await _repository.GetByEmailAsync(request.Email, cancellationToken);
            if (existingByEmail is not null)
                return Result<object>.Fail("EMAIL_ALREADY_REGISTERED");
        }

        var passwordHash = _jwtService.HashPassword(request.Password);
        var customer = Customer.Create(request.FullName, request.Phone, request.Email, passwordHash);
        await _repository.AddAsync(customer, cancellationToken);

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var otpHash = _jwtService.HashPassword(otp);
        var otpRecord = OtpVerification.Create(customer.Id, otpHash, DateTime.UtcNow.AddMinutes(10));
        await _repository.AddOtpAsync(otpRecord, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        // Auto-generate a unique referral code for the new customer
        var referralCode = await GenerateUniqueCodeAsync(cancellationToken);
        await _repository.AddReferralCodeAsync(ReferralCode.Create(customer.Id, referralCode), cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        await _otpNotificationService.SendOtpAsync(request.Phone, request.Email, otp, cancellationToken);

        return Result<object>.Ok(new { message = "OTP sent" });
    }

    /// <summary>
    /// Generates a collision-resistant 8-character uppercase alphanumeric code,
    /// retrying on duplicate key (extremely rare in practice).
    /// </summary>
    private async Task<string> GenerateUniqueCodeAsync(CancellationToken ct)
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no ambiguous chars
        while (true)
        {
            var code = new string(Enumerable.Range(0, 8)
                .Select(_ => chars[RandomNumberGenerator.GetInt32(chars.Length)])
                .ToArray());

            var existing = await _repository.GetReferralCodeByCodeAsync(code, ct);
            if (existing is null)
                return code;
        }
    }
}
