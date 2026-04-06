using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands.Auth;

public record RegisterProviderCommand(
    string Phone,
    string Email,
    string FullName,
    string Password,
    string[] ServiceCategories
) : IRequest<Result<object>>;

public class RegisterProviderCommandHandler : IRequestHandler<RegisterProviderCommand, Result<object>>
{
    private readonly IProvidersRepository _repository;
    private readonly IJwtService _jwtService;
    private readonly IOtpNotificationService _otpNotificationService;

    public RegisterProviderCommandHandler(
        IProvidersRepository repository,
        IJwtService jwtService,
        IOtpNotificationService otpNotificationService)
    {
        _repository = repository;
        _jwtService = jwtService;
        _otpNotificationService = otpNotificationService;
    }

    public async Task<Result<object>> Handle(RegisterProviderCommand request, CancellationToken cancellationToken)
    {
        var existing = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (existing is not null)
            return Result<object>.Fail("PHONE_ALREADY_REGISTERED");

        var passwordHash = _jwtService.HashPassword(request.Password);
        var provider = Provider.Create(request.FullName, request.Phone, request.Email, passwordHash, request.ServiceCategories);
        await _repository.AddAsync(provider, cancellationToken);

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var otpHash = _jwtService.HashPassword(otp);
        var otpRecord = ProviderOtpVerification.Create(provider.Id, otpHash, DateTime.UtcNow.AddMinutes(10));
        await _repository.AddOtpAsync(otpRecord, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        await _otpNotificationService.SendOtpAsync(request.Phone, request.Email, otp, cancellationToken);

        return Result<object>.Ok(new { message = "OTP sent" });
    }
}
