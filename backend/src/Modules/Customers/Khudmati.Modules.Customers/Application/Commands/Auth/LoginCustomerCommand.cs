using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Application.Auth;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record LoginCustomerCommand(
    string Phone,
    string Password
) : IRequest<Result<object>>;

public class LoginCustomerCommandHandler : IRequestHandler<LoginCustomerCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;
    private readonly IJwtService _jwtService;

    public LoginCustomerCommandHandler(ICustomersRepository repository, IJwtService jwtService)
    {
        _repository = repository;
        _jwtService = jwtService;
    }

    public async Task<Result<object>> Handle(LoginCustomerCommand request, CancellationToken cancellationToken)
    {
        var customer = await _repository.GetByPhoneAsync(request.Phone, cancellationToken);
        if (customer is null)
            return Result<object>.Fail("INVALID_CREDENTIALS");

        if (!customer.IsVerified)
            return Result<object>.Fail("EMAIL_NOT_VERIFIED");

        if (!_jwtService.VerifyPassword(request.Password, customer.PasswordHash))
            return Result<object>.Fail("INVALID_CREDENTIALS");

        var existingToken = await _repository.GetRefreshTokenByAccountIdAsync(customer.Id, cancellationToken);
        if (existingToken is not null)
            await _repository.RemoveRefreshTokenAsync(existingToken, cancellationToken);

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
