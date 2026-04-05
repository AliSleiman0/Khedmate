using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record AdvanceJobStatusCommand(Guid JobId, Guid ProviderId) : IRequest<Result<AdvanceJobStatusResultDto>>;

public record AdvanceJobStatusResultDto(
    Guid JobId,
    string PreviousStatus,
    string NewStatus,
    DateTime UpdatedAt);

public class AdvanceJobStatusCommandHandler
    : IRequestHandler<AdvanceJobStatusCommand, Result<AdvanceJobStatusResultDto>>
{
    private readonly IBookingsRepository _repo;
    private readonly IMediator _mediator;

    public AdvanceJobStatusCommandHandler(IBookingsRepository repo, IMediator mediator)
    {
        _repo = repo;
        _mediator = mediator;
    }

    public async Task<Result<AdvanceJobStatusResultDto>> Handle(
        AdvanceJobStatusCommand request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        if (job is null)
            return Result<AdvanceJobStatusResultDto>.Fail("JOB_NOT_FOUND");

        if (job.ProviderId != request.ProviderId)
            return Result<AdvanceJobStatusResultDto>.Fail("FORBIDDEN");

        // Gate: InProgress → Completed requires at least 1 after-photo
        if (job.Status == JobStatus.InProgress)
        {
            var hasAfterPhoto = job.Photos.Any(p => p.PhotoType == "after");
            if (!hasAfterPhoto)
                return Result<AdvanceJobStatusResultDto>.Fail("AFTER_PHOTO_REQUIRED");
        }

        var previousStatus = job.Status.ToString();
        var result = job.Advance();

        if (!result.Success)
            return Result<AdvanceJobStatusResultDto>.Fail("INVALID_STATUS_TRANSITION");

        var history = JobStatusHistory.Create(job.Id, previousStatus, result.Data.ToString(), request.ProviderId);
        await _repo.AddStatusHistoryAsync(history, cancellationToken);
        await _repo.SaveChangesAsync(cancellationToken);

        // Publish domain events (fires JobStatusChangedEvent → SignalR handler)
        foreach (var evt in job.DomainEvents)
            await _mediator.Publish(evt, cancellationToken);

        return Result<AdvanceJobStatusResultDto>.Ok(new AdvanceJobStatusResultDto(
            job.Id,
            previousStatus,
            result.Data.ToString(),
            DateTime.UtcNow));
    }
}
