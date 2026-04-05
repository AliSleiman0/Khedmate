using FluentValidation;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record RespondToJobCommand(
    Guid JobId,
    Guid ProviderId,
    string Action   // "accept" | "reject"
) : IRequest<Result<RespondToJobResultDto>>;

public record RespondToJobResultDto(Guid JobId, string Status, Guid? ProviderId);

public class RespondToJobCommandValidator : AbstractValidator<RespondToJobCommand>
{
    public RespondToJobCommandValidator()
    {
        RuleFor(x => x.Action)
            .Must(a => a == "accept" || a == "reject")
            .WithMessage("Action must be 'accept' or 'reject'.");
    }
}

public class RespondToJobCommandHandler : IRequestHandler<RespondToJobCommand, Result<RespondToJobResultDto>>
{
    private readonly IBookingsRepository _repo;
    private readonly IMediator _mediator;

    public RespondToJobCommandHandler(IBookingsRepository repo, IMediator mediator)
    {
        _repo = repo;
        _mediator = mediator;
    }

    public async Task<Result<RespondToJobResultDto>> Handle(
        RespondToJobCommand request, CancellationToken cancellationToken)
    {
        if (request.Action == "accept")
            return await HandleAccept(request, cancellationToken);

        return await HandleReject(request, cancellationToken);
    }

    private async Task<Result<RespondToJobResultDto>> HandleAccept(
        RespondToJobCommand request, CancellationToken cancellationToken)
    {
        // SELECT FOR UPDATE ensures only one provider wins the race
        var job = await _repo.AcceptJobWithLockAsync(request.JobId, request.ProviderId, cancellationToken);

        if (job is null)
            return Result<RespondToJobResultDto>.Fail("JOB_NO_LONGER_AVAILABLE");

        // Publish domain events
        foreach (var evt in job.DomainEvents)
            await _mediator.Publish(evt, cancellationToken);

        return Result<RespondToJobResultDto>.Ok(
            new RespondToJobResultDto(job.Id, job.Status.ToString(), job.ProviderId));
    }

    private async Task<Result<RespondToJobResultDto>> HandleReject(
        RespondToJobCommand request, CancellationToken cancellationToken)
    {
        var rejection = JobRejection.Create(request.JobId, request.ProviderId);
        await _repo.AddRejectionAsync(rejection, cancellationToken);
        await _repo.SaveChangesAsync(cancellationToken);

        return Result<RespondToJobResultDto>.Ok(
            new RespondToJobResultDto(request.JobId, JobStatus.Pending.ToString(), null));
    }
}
