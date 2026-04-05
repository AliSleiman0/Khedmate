using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Domain.Events;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands;

public record ApproveProviderDocumentsCommand(
    Guid AdminId,
    Guid ProviderId,
    Guid SubmissionId
) : IRequest<Result<bool>>;

public class ApproveProviderDocumentsCommandHandler : IRequestHandler<ApproveProviderDocumentsCommand, Result<bool>>
{
    private readonly IDocumentSubmissionRepository _submissionRepo;
    private readonly IProvidersRepository _providerRepo;
    private readonly ITierHistoryRepository _tierHistoryRepo;
    private readonly IMediator _mediator;

    public ApproveProviderDocumentsCommandHandler(
        IDocumentSubmissionRepository submissionRepo,
        IProvidersRepository providerRepo,
        ITierHistoryRepository tierHistoryRepo,
        IMediator mediator)
    {
        _submissionRepo = submissionRepo;
        _providerRepo = providerRepo;
        _tierHistoryRepo = tierHistoryRepo;
        _mediator = mediator;
    }

    public async Task<Result<bool>> Handle(
        ApproveProviderDocumentsCommand request, CancellationToken cancellationToken)
    {
        var submission = await _submissionRepo.GetByIdAsync(request.SubmissionId, cancellationToken);
        if (submission == null)
            return Result<bool>.Fail("SUBMISSION_NOT_FOUND");

        if (submission.ProviderId != request.ProviderId)
            return Result<bool>.Fail("PROVIDER_MISMATCH");

        if (!submission.IsPending())
            return Result<bool>.Fail("SUBMISSION_ALREADY_REVIEWED");

        submission.Approve(request.AdminId);
        await _submissionRepo.SaveChangesAsync(cancellationToken);

        // Advance provider tier to IdVerified
        var provider = await _providerRepo.GetByIdAsync(request.ProviderId, cancellationToken);
        if (provider != null && provider.Tier < VerificationTier.IdVerified)
        {
            var previousTier = provider.Tier;
            provider.UpgradeTier(VerificationTier.IdVerified);
            await _providerRepo.SaveChangesAsync(cancellationToken);

            // Log tier change
            var history = TierHistory.Create(
                request.ProviderId,
                previousTier,
                VerificationTier.IdVerified,
                request.AdminId,
                "ID documents approved"
            );
            await _tierHistoryRepo.AddAsync(history, cancellationToken);
            await _tierHistoryRepo.SaveChangesAsync(cancellationToken);

            // Fire SignalR event
            await _mediator.Publish(new VerificationStatusChangedEvent(
                request.ProviderId,
                VerificationTier.IdVerified,
                "Approved",
                "تم قبول مستنداتك. يمكنك الآن إجراء اختبار المهارة."
            ), cancellationToken);
        }

        return Result<bool>.Ok(true);
    }
}
