using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands;

public record SubmitSkillTestCommand(
    Guid ProviderId,
    Guid TestId,
    string CategoryId,
    List<SkillTestAnswerDto> Answers
) : IRequest<Result<SkillTestResultDto>>;

public class SubmitSkillTestCommandHandler : IRequestHandler<SubmitSkillTestCommand, Result<SkillTestResultDto>>
{
    private readonly ISkillTestRepository _testRepo;
    private readonly IProvidersRepository _providerRepo;
    private readonly ITierHistoryRepository _tierHistoryRepo;
    private const int Passmark = 7;

    public SubmitSkillTestCommandHandler(
        ISkillTestRepository testRepo,
        IProvidersRepository providerRepo,
        ITierHistoryRepository tierHistoryRepo)
    {
        _testRepo = testRepo;
        _providerRepo = providerRepo;
        _tierHistoryRepo = tierHistoryRepo;
    }

    public async Task<Result<SkillTestResultDto>> Handle(
        SubmitSkillTestCommand request, CancellationToken cancellationToken)
    {
        // Validate session
        var session = await _testRepo.GetSessionByIdAsync(request.TestId, cancellationToken);
        if (session == null)
            return Result<SkillTestResultDto>.Fail("TEST_SESSION_NOT_FOUND");

        if (session.ProviderId != request.ProviderId)
            return Result<SkillTestResultDto>.Fail("UNAUTHORIZED");

        if (!session.IsInProgress())
            return Result<SkillTestResultDto>.Fail("TEST_ALREADY_SUBMITTED");

        if (session.IsExpired())
        {
            session.MarkExpired();
            await _testRepo.SaveChangesAsync(cancellationToken);
            return Result<SkillTestResultDto>.Fail("TEST_SESSION_EXPIRED");
        }

        // Score the test
        int score = 0;
        foreach (var answer in request.Answers)
        {
            var question = await _testRepo.GetQuestionByIdAsync(answer.QuestionId, cancellationToken);
            if (question != null && question.CorrectKey.ToString() == answer.SelectedKey)
            {
                score++;
            }
        }

        var passed = score >= Passmark;

        // Update session
        if (passed)
        {
            session.MarkPassed(score);

            // Check if we should advance tier to SkillTested
            var provider = await _providerRepo.GetByIdAsync(request.ProviderId, cancellationToken);
            if (provider != null && provider.Tier < VerificationTier.SkillTested)
            {
                var previousTier = provider.Tier;
                
                // For SkillTested tier, we need IdVerified first
                if (provider.Tier >= VerificationTier.IdVerified)
                {
                    provider.UpgradeTier(VerificationTier.SkillTested);
                    await _providerRepo.SaveChangesAsync(cancellationToken);

                    // Log tier change
                    var history = TierHistory.Create(
                        request.ProviderId,
                        previousTier,
                        VerificationTier.SkillTested,
                        request.ProviderId, // self-triggered by passing test
                        $"Passed skill test for {request.CategoryId}"
                    );
                    await _tierHistoryRepo.AddAsync(history, cancellationToken);
                    await _tierHistoryRepo.SaveChangesAsync(cancellationToken);
                }
            }
        }
        else
        {
            session.MarkFailed(score);
        }

        await _testRepo.SaveChangesAsync(cancellationToken);

        return Result<SkillTestResultDto>.Ok(new SkillTestResultDto(
            passed,
            score,
            10,
            Passmark,
            session.NextRetryAt
        ));
    }
}
