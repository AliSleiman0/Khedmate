using FluentValidation;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record OpenDisputeCommand(
    Guid JobId,
    Guid CustomerId,
    string Complaint
) : IRequest<Result<OpenDisputeResultDto>>;

public class OpenDisputeCommandValidator : AbstractValidator<OpenDisputeCommand>
{
    public OpenDisputeCommandValidator()
    {
        RuleFor(x => x.Complaint)
            .NotEmpty()
            .MinimumLength(20).WithMessage("Complaint must be at least 20 characters.")
            .MaximumLength(1000).WithMessage("Complaint must not exceed 1000 characters.");
    }
}

public class OpenDisputeCommandHandler : IRequestHandler<OpenDisputeCommand, Result<OpenDisputeResultDto>>
{
    private readonly IBookingsRepository _bookingsRepo;
    private readonly IPaymentsRepository _paymentsRepo;
    private readonly IMediator _mediator;

    public OpenDisputeCommandHandler(
        IBookingsRepository bookingsRepo,
        IPaymentsRepository paymentsRepo,
        IMediator mediator)
    {
        _bookingsRepo = bookingsRepo;
        _paymentsRepo = paymentsRepo;
        _mediator = mediator;
    }

    public async Task<Result<OpenDisputeResultDto>> Handle(
        OpenDisputeCommand request, CancellationToken cancellationToken)
    {
        // 1. Load job and verify ownership
        var job = await _bookingsRepo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null || job.CustomerId != request.CustomerId)
            return Result<OpenDisputeResultDto>.Fail("JOB_NOT_FOUND");

        // 2. Job must be in Paid status
        if (job.Status != JobStatus.Paid)
            return Result<OpenDisputeResultDto>.Fail("DISPUTE_NOT_ALLOWED_IN_CURRENT_STATUS");

        // 3. Transaction must still be Held (within 24h window)
        var transaction = await _paymentsRepo.GetByJobIdAsync(request.JobId, cancellationToken);
        if (transaction is null || transaction.Status != "Held")
            return Result<OpenDisputeResultDto>.Fail("DISPUTE_WINDOW_CLOSED");

        // 4. No existing open dispute for this job
        var existingDispute = await _bookingsRepo.GetDisputeByJobIdAsync(request.JobId, cancellationToken);
        if (existingDispute is { Status: "Open" })
            return Result<OpenDisputeResultDto>.Fail("DISPUTE_ALREADY_EXISTS");

        // 5. Mark transaction as Disputed to prevent auto-release
        transaction.MarkDisputed();

        // 6. Create and persist the dispute
        var dispute = Dispute.Open(
            request.JobId,
            request.CustomerId,
            job.ProviderId!.Value,
            request.Complaint);

        await _bookingsRepo.AddDisputeAsync(dispute, cancellationToken);
        await _bookingsRepo.SaveChangesAsync(cancellationToken);
        await _paymentsRepo.SaveChangesAsync(cancellationToken);

        // 7. Dispatch domain event
        await _mediator.Publish(
            new DisputeOpenedEvent(dispute.Id, request.JobId, request.CustomerId, job.ProviderId.Value),
            cancellationToken);

        return Result<OpenDisputeResultDto>.Ok(new OpenDisputeResultDto(dispute.Id));
    }
}
