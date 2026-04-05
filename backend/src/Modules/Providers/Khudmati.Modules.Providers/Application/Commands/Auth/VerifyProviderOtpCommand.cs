using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands.Auth;

public record VerifyProviderOtpCommand(
    string Phone,
    string Otp
) : IRequest<Result<object>>;

public class VerifyProviderOtpCommandHandler : IRequestHandler<VerifyProviderOtpCommand, Result<object>>
{
    private readonly IProvidersRepository _repository;
    private readonly IJwtService _jwtService;

    public VerifyProviderOtpCommandHandler(IProvidersRepository repository, IJwtService jwtService)
    {
        _repository = repository;
        _jwtService = jwtService;
    }

    public async Task<Result<object>> Handle(VerifyProviderOtpCommand request, CancellationToken cancellationToken)
    {
        var provider = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (provider is null)
            return Result<object>.Fail("PROVIDER_NOT_FOUND");

        var otpRecord = await _repository.GetLatestOtpAsync(provider.Id, cancellationToken);
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
        provider.SetVerified();
        await _repository.UpdateAsync(provider, cancellationToken);

        var accessToken = _jwtService.GenerateAccessToken(provider.Id, "provider", expiryMinutes: 15);
        var (tokenId, clientToken, tokenHash) = _jwtService.GenerateRefreshToken();
        var refreshTokenRecord = ProviderRefreshToken.Create(
            tokenId, provider.Id, tokenHash, DateTime.UtcNow.AddDays(30));
        await _repository.AddRefreshTokenAsync(refreshTokenRecord, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        return Result<object>.Ok(new
        {
            accessToken,
            refreshToken = $"{tokenId}:{clientToken}",
            provider = new
            {
                id = provider.Id,
                fullName = provider.FullName,
                phone = provider.Phone,
                email = provider.Email,
                serviceCategories = provider.ServiceCategories
            }
        });
    }
}
