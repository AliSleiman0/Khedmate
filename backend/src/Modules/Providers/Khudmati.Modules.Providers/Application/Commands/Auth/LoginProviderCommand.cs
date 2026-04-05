using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands.Auth;

public record LoginProviderCommand(
    string Phone,
    string Password
) : IRequest<Result<object>>;

public class LoginProviderCommandHandler : IRequestHandler<LoginProviderCommand, Result<object>>
{
    private readonly IProvidersRepository _repository;
    private readonly IJwtService _jwtService;

    public LoginProviderCommandHandler(IProvidersRepository repository, IJwtService jwtService)
    {
        _repository = repository;
        _jwtService = jwtService;
    }

    public async Task<Result<object>> Handle(LoginProviderCommand request, CancellationToken cancellationToken)
    {
        var provider = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (provider is null)
            return Result<object>.Fail("INVALID_CREDENTIALS");

        if (!provider.IsVerified)
            return Result<object>.Fail("EMAIL_NOT_VERIFIED");

        if (!_jwtService.VerifyPassword(request.Password, provider.PasswordHash))
            return Result<object>.Fail("INVALID_CREDENTIALS");

        var existingToken = await _repository.GetRefreshTokenByAccountIdAsync(provider.Id, cancellationToken);
        if (existingToken is not null)
            await _repository.RemoveRefreshTokenAsync(existingToken, cancellationToken);

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
