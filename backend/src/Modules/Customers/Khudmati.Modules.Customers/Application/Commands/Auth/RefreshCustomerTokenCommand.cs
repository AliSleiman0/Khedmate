using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record RefreshCustomerTokenCommand(string RefreshToken) : IRequest<Result<object>>;

public class RefreshCustomerTokenCommandHandler : IRequestHandler<RefreshCustomerTokenCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;

    public RefreshCustomerTokenCommandHandler(ICustomersRepository repository, IJwtService jwtService)
    {
        _repository = repository;
        _jwtService = jwtService;
    }

    public async Task<Result<object>> Handle(RefreshCustomerTokenCommand request, CancellationToken cancellationToken)
    {
        var parts = request.RefreshToken.Split(':', 2);
        if (parts.Length != 2 || !Guid.TryParse(parts[0], out var tokenId))
            return Result<object>.Fail("INVALID_REFRESH_TOKEN");

        var plainToken = parts[1];

        var tokenRecord = await _repository.GetRefreshTokenByIdAsync(tokenId, cancellationToken);
        if (tokenRecord is null)
            return Result<object>.Fail("INVALID_REFRESH_TOKEN");

        if (tokenRecord.ExpiresAt <= DateTime.UtcNow)
            return Result<object>.Fail("INVALID_REFRESH_TOKEN");

        if (!_jwtService.VerifyTokenValue(plainToken, tokenRecord.TokenHash))
            return Result<object>.Fail("INVALID_REFRESH_TOKEN");

        var customer = await _repository.GetByIdAsync(tokenRecord.AccountId, cancellationToken);
        if (customer is null)
            return Result<object>.Fail("INVALID_REFRESH_TOKEN");

        await _repository.RemoveRefreshTokenAsync(tokenRecord, cancellationToken);

        var accessToken = _jwtService.GenerateAccessToken(customer.Id, "customer", expiryMinutes: 15);
        var (newTokenId, newClientToken, newTokenHash) = _jwtService.GenerateRefreshToken();
        var newRefreshToken = CustomerRefreshToken.Create(
            newTokenId, customer.Id, newTokenHash, DateTime.UtcNow.AddDays(30));
        await _repository.AddRefreshTokenAsync(newRefreshToken, cancellationToken);

        await _repository.SaveChangesAsync(cancellationToken);

        return Result<object>.Ok(new
        {
            accessToken,
            refreshToken = $"{newTokenId}:{newClientToken}"
        });
    }
}
