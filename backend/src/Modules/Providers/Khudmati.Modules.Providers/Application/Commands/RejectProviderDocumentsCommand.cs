using Khudmati.Modules.Providers.Domain.Events;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands;

public record RejectProviderDocumentsCommand(
    Guid AdminId,
    Guid ProviderId,
    Guid SubmissionId,
    string RejectionReason
) : IRequest<Result<bool>>;

public class RejectProviderDocumentsCommandHandler : IRequestHandler<RejectProviderDocumentsCommand, Result<bool>>
{
    private readonly IDocumentSubmissionRepository _submissionRepo;
    private readonly IProvidersRepository _providerRepo;
    private readonly IMediator _mediator;

    public RejectProviderDocumentsCommandHandler(
        IDocumentSubmissionRepository submissionRepo,
        IProvidersRepository providerRepo,
        IMediator mediator)
    {
        _submissionRepo = submissionRepo;
        _providerRepo = providerRepo;
        _mediator = mediator;
    }

    public async Task<Result<bool>> Handle(
        RejectProviderDocumentsCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.RejectionReason))
            return Result<bool>.Fail("REJECTION_REASON_REQUIRED");

        var submission = await _submissionRepo.GetByIdAsync(request.SubmissionId, cancellationToken);
        if (submission == null)
            return Result<bool>.Fail("SUBMISSION_NOT_FOUND");

        if (submission.ProviderId != request.ProviderId)
            return Result<bool>.Fail("PROVIDER_MISMATCH");

        if (!submission.IsPending())
            return Result<bool>.Fail("SUBMISSION_ALREADY_REVIEWED");

        submission.Reject(request.AdminId, request.RejectionReason);
        await _submissionRepo.SaveChangesAsync(cancellationToken);

        // Fire SignalR event
        var provider = await _providerRepo.GetByIdAsync(request.ProviderId, cancellationToken);
        await _mediator.Publish(new VerificationStatusChangedEvent(
            request.ProviderId,
            provider?.Tier ?? Domain.Enums.VerificationTier.Unverified,
            "Rejected",
            $"تم رفض مستنداتك. السبب: {request.RejectionReason}"
        ), cancellationToken);

        return Result<bool>.Ok(true);
    }
}
