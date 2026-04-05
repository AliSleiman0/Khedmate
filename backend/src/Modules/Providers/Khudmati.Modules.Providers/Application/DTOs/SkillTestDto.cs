namespace Khudmati.Modules.Providers.Application.DTOs;

public record SkillTestDto(
    Guid TestId,
    string CategoryId,
    string CategoryName,
    List<SkillTestQuestionDto> Questions
);

public record SkillTestQuestionDto(
    Guid Id,
    string QuestionText,
    List<SkillTestOptionDto> Options
);

public record SkillTestOptionDto(
    string Key,      // "A", "B", "C", "D"
    string Text
);

public record SkillTestAnswerDto(
    Guid QuestionId,
    string SelectedKey
);
