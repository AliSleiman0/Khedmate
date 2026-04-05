using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Payments.Application.Commands;

/// <summary>
/// Sets the provider on a transaction once a provider accepts the job.
/// Called by the API-layer JobAcceptedEventHandler.
/// </summary>
public record AssignTransactionProviderCommand(Guid JobId, Guid ProviderId) : IRequest<Result>;

public class AssignTransactionProviderCommandHandler
    : IRequestHandler<AssignTransactionProviderCommand, Result>
{
    private readonly IPaymentsRepository _repo;
    private readonly ILogger<AssignTransactionProviderCommandHandler> _logger;

    public AssignTransactionProviderCommandHandler(
        IPaymentsRepository repo,
        ILogger<AssignTransactionProviderCommandHandler> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result> Handle(
        AssignTransactionProviderCommand request, CancellationToken cancellationToken)
    {
        var transaction = await _repo.GetByJobIdPaidAsync(request.JobId, cancellationToken);

        if (transaction is null)
        {
            // No paid transaction for this job — cash job or payment not yet confirmed
            _logger.LogDebug(
                "No paid transaction found for job {JobId} when assigning provider.", request.JobId);
            return Result.Ok();
        }

        transaction.AssignProvider(request.ProviderId);
        await _repo.SaveChangesAsync(cancellationToken);

        return Result.Ok();
    }
}
