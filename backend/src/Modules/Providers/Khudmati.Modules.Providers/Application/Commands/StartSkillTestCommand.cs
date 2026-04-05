using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Commands;

public record StartSkillTestCommand(
    Guid ProviderId,
    string CategoryId
) : IRequest<Result<SkillTestDto>>;

public class StartSkillTestCommandHandler : IRequestHandler<StartSkillTestCommand, Result<SkillTestDto>>
{
    private readonly ISkillTestRepository _testRepo;
    private readonly IProvidersRepository _providerRepo;

    public StartSkillTestCommandHandler(
        ISkillTestRepository testRepo,
        IProvidersRepository providerRepo)
    {
        _testRepo = testRepo;
        _providerRepo = providerRepo;
    }

    public async Task<Result<SkillTestDto>> Handle(StartSkillTestCommand request, CancellationToken cancellationToken)
    {
        // Check cooldown - if provider failed recently
        var latestSession = await _testRepo.GetLatestSessionAsync(request.ProviderId, request.CategoryId, cancellationToken);
        if (latestSession?.NextRetryAt != null && latestSession.NextRetryAt > DateTime.UtcNow)
        {
            return Result<SkillTestDto>.Fail("TEST_COOLDOWN_ACTIVE");
        }

        // Get questions for this category
        var questions = await _testRepo.GetActiveQuestionsByCategoryAsync(request.CategoryId, cancellationToken);
        if (questions.Count < 10)
            return Result<SkillTestDto>.Fail("INSUFFICIENT_QUESTIONS");

        // Create new session
        var session = SkillTestSession.Create(request.ProviderId, request.CategoryId);
        await _testRepo.AddSessionAsync(session, cancellationToken);
        await _testRepo.SaveChangesAsync(cancellationToken);

        // Shuffle questions and randomize option order
        var shuffledQuestions = questions
            .OrderBy(_ => Guid.NewGuid())
            .Take(10)
            .Select(q => new SkillTestQuestionDto(
                q.Id,
                q.QuestionText,
                ShuffleOptions(q)
            ))
            .ToList();

        var categoryNames = new Dictionary<string, string>
        {
            ["plumbing"] = "سباكة",
            ["electrical"] = "كهرباء",
            ["cleaning"] = "تنظيف",
            ["carpentry"] = "نجارة",
            ["painting"] = "دهان",
            ["ac_maintenance"] = "تكييف"
        };

        return Result<SkillTestDto>.Ok(new SkillTestDto(
            session.Id,
            request.CategoryId,
            categoryNames.GetValueOrDefault(request.CategoryId, request.CategoryId),
            shuffledQuestions
        ));
    }

    private static List<SkillTestOptionDto> ShuffleOptions(SkillTestQuestion question)
    {
        var options = new List<SkillTestOptionDto>
        {
            new("A", question.OptionA),
            new("B", question.OptionB),
            new("C", question.OptionC),
            new("D", question.OptionD)
        };

        return options.OrderBy(_ => Guid.NewGuid()).ToList();
    }
}
