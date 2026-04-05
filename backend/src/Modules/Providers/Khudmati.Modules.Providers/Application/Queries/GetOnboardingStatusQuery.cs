using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Queries;

public record GetOnboardingStatusQuery(Guid ProviderId) : IRequest<Result<OnboardingStatusDto>>;

public class GetOnboardingStatusQueryHandler : IRequestHandler<GetOnboardingStatusQuery, Result<OnboardingStatusDto>>
{
    private readonly IProvidersRepository _providerRepo;
    private readonly IDocumentSubmissionRepository _submissionRepo;
    private readonly ISkillTestRepository _testRepo;

    public GetOnboardingStatusQueryHandler(
        IProvidersRepository providerRepo,
        IDocumentSubmissionRepository submissionRepo,
        ISkillTestRepository testRepo)
    {
        _providerRepo = providerRepo;
        _submissionRepo = submissionRepo;
        _testRepo = testRepo;
    }

    public async Task<Result<OnboardingStatusDto>> Handle(
        GetOnboardingStatusQuery request, CancellationToken cancellationToken)
    {
        var provider = await _providerRepo.GetByIdAsync(request.ProviderId, cancellationToken);
        if (provider == null)
            return Result<OnboardingStatusDto>.Fail("PROVIDER_NOT_FOUND");

        // Check document submission status
        var latestSubmission = await _submissionRepo.GetPendingByProviderIdAsync(request.ProviderId, cancellationToken);
        
        var idVerifiedStep = new OnboardingStepDto(
            Status: provider.Tier >= VerificationTier.IdVerified ? "Complete" :
                    latestSubmission?.Status == DocumentStatus.PendingReview ? "PendingReview" :
                    latestSubmission?.Status == DocumentStatus.Rejected ? "Rejected" :
                    "Required",
            CompletedAt: provider.Tier >= VerificationTier.IdVerified ? provider.UpdatedAt : null,
            SubmittedAt: latestSubmission?.SubmittedAt,
            RejectionReason: latestSubmission?.RejectionReason
        );

        // Check skill test status
        var hasPassedSkillTest = provider.Tier >= VerificationTier.SkillTested;
        var skillTestedStep = new OnboardingStepDto(
            Status: hasPassedSkillTest ? "Complete" : "Required",
            CompletedAt: hasPassedSkillTest ? provider.UpdatedAt : null,
            SubmittedAt: null,
            RejectionReason: null
        );

        // Phone verification is done at registration
        var phoneVerifiedStep = new OnboardingStepDto(
            Status: provider.IsVerified ? "Complete" : "Required",
            CompletedAt: provider.IsVerified ? provider.CreatedAt : null,
            SubmittedAt: null,
            RejectionReason: null
        );

        var steps = new OnboardingStepsDto(idVerifiedStep, skillTestedStep, phoneVerifiedStep);

        return Result<OnboardingStatusDto>.Ok(new OnboardingStatusDto(
            provider.Tier,
            steps,
            provider.Tier == VerificationTier.Active
        ));
    }
}
