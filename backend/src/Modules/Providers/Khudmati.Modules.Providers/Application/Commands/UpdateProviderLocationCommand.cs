using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands;

public record UpdateProviderLocationCommand(
    Guid ProviderId,
    double Latitude,
    double Longitude
) : IRequest<Result<bool>>;

public class UpdateProviderLocationCommandHandler : IRequestHandler<UpdateProviderLocationCommand, Result<bool>>
{
    private readonly IProviderLocationRepository _repo;

    public UpdateProviderLocationCommandHandler(IProviderLocationRepository repo) => _repo = repo;

    public async Task<Result<bool>> Handle(UpdateProviderLocationCommand request, CancellationToken cancellationToken)
    {
        await _repo.UpsertAsync(
            request.ProviderId,
            (decimal)request.Latitude,
            (decimal)request.Longitude,
            cancellationToken);

        return Result<bool>.Ok(true);
    }
}
