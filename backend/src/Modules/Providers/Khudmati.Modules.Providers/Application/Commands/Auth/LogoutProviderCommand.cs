using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands.Auth;

public record LogoutProviderCommand(Guid AccountId) : IRequest<Result<object>>;

public class LogoutProviderCommandHandler : IRequestHandler<LogoutProviderCommand, Result<object>>
{
    private readonly IProvidersRepository _repository;

    public LogoutProviderCommandHandler(IProvidersRepository repository)
    {
        _repository = repository;
    }

    public async Task<Result<object>> Handle(LogoutProviderCommand request, CancellationToken cancellationToken)
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
