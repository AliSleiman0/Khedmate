using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Bookings.Application.Commands;

/// <summary>
/// Transitions a Completed job to Paid once payment has been released to the provider.
/// Called by the API-level PaymentReleasedEventHandler.
/// </summary>
public record MarkJobPaidCommand(Guid JobId) : IRequest<Result>;

public class MarkJobPaidCommandHandler : IRequestHandler<MarkJobPaidCommand, Result>
{
    private readonly IBookingsRepository _repo;
    private readonly ILogger<MarkJobPaidCommandHandler> _logger;

    public MarkJobPaidCommandHandler(IBookingsRepository repo, ILogger<MarkJobPaidCommandHandler> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result> Handle(MarkJobPaidCommand request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        if (job is null)
        {
            _logger.LogError("MarkJobPaidCommand: job {JobId} not found.", request.JobId);
            return Result.Fail("JOB_NOT_FOUND");
        }

        try
        {
            job.MarkPaid();
            await _repo.SaveChangesAsync(cancellationToken);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "MarkJobPaidCommand: cannot mark job {JobId} as paid.", request.JobId);
            return Result.Fail("INVALID_STATUS_TRANSITION");
        }

        return Result.Ok();
    }
}
