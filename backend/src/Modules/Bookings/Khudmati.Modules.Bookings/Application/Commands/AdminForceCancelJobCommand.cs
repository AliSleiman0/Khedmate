using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record AdminForceCancelJobCommand(Guid JobId, Guid AdminId) : IRequest<Result<AdminForceCancelResultDto>>;

public record AdminForceCancelResultDto(Guid JobId, string NewStatus);

public class AdminForceCancelJobCommandHandler
    : IRequestHandler<AdminForceCancelJobCommand, Result<AdminForceCancelResultDto>>
{
    private readonly IBookingsRepository _repo;
    private readonly IMediator _mediator;
    private readonly IPushNotificationService _push;

    public AdminForceCancelJobCommandHandler(
        IBookingsRepository repo,
        IMediator mediator,
        IPushNotificationService push)
    {
        _repo = repo;
        _mediator = mediator;
        _push = push;
    }

    public async Task<Result<AdminForceCancelResultDto>> Handle(
        AdminForceCancelJobCommand request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null)
            return Result<AdminForceCancelResultDto>.Fail("JOB_NOT_FOUND");

        if (job.Status != JobStatus.Pending && job.Status != JobStatus.Accepted)
            return Result<AdminForceCancelResultDto>.Fail("CANNOT_CANCEL_JOB_IN_CURRENT_STATUS");

        var previousStatus = job.Status.ToString();
        job.AdminForceExpire();

        var history = JobStatusHistory.Create(
            job.Id,
            previousStatus,
            JobStatus.Expired.ToString(),
            request.AdminId);
        await _repo.AddStatusHistoryAsync(history, cancellationToken);

        await _repo.SaveChangesAsync(cancellationToken);

        foreach (var evt in job.DomainEvents)
            await _mediator.Publish(evt, cancellationToken);

        await _push.SendAsync(
            job.CustomerId,
            "customer",
            "تم إلغاء الطلب",
            $"تم إلغاء طلبك {job.ReferenceNumber} من قِبل فريق الدعم.",
            new Dictionary<string, string> { { "jobId", job.Id.ToString() }, { "type", "force_cancel" } },
            cancellationToken);

        return Result<AdminForceCancelResultDto>.Ok(
            new AdminForceCancelResultDto(job.Id, JobStatus.Expired.ToString()));
    }
}
