using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands.Auth;

public record LogoutCustomerCommand(Guid AccountId) : IRequest<Result<object>>;

public class LogoutCustomerCommandHandler : IRequestHandler<LogoutCustomerCommand, Result<object>>
{
    private readonly ICustomersRepository _repository;

    public LogoutCustomerCommandHandler(ICustomersRepository repository)
    {
        _repository = repository;
    }

    public async Task<Result<object>> Handle(LogoutCustomerCommand request, CancellationToken cancellationToken)
    {
        var tokenRecord = await _repository.GetRefreshTokenByAccountIdAsync(request.AccountId, cancellationToken);
        if (tokenRecord is not null)
        {
            await _repository.RemoveRefreshTokenAsync(tokenRecord, cancellationToken);
            await _repository.SaveChangesAsync(cancellationToken);
        }

        return Result<object>.Ok(new { message = "Logged out" });
    }
}
