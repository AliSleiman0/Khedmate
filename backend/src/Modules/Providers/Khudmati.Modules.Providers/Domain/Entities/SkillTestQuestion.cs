using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Providers.Domain.Entities;

public class SkillTestQuestion : AuditableEntity
{
    public string CategoryId { get; private set; } = string.Empty;
    public string QuestionText { get; private set; } = string.Empty;
    public string OptionA { get; private set; } = string.Empty;
    public string OptionB { get; private set; } = string.Empty;
    public string OptionC { get; private set; } = string.Empty;
    public string OptionD { get; private set; } = string.Empty;
    public char CorrectKey { get; private set; } = 'A';
    public bool IsActive { get; private set; } = true;

    private SkillTestQuestion() { }

    public static SkillTestQuestion Create(string categoryId, string questionText, 
        string optionA, string optionB, string optionC, string optionD, char correctKey)
    {
        if (correctKey != 'A' && correctKey != 'B' && correctKey != 'C' && correctKey != 'D')
            throw new ArgumentException("Correct key must be A, B, C, or D.", nameof(correctKey));

        return new SkillTestQuestion
        {
            CategoryId = categoryId,
            QuestionText = questionText,
            OptionA = optionA,
            OptionB = optionB,
            OptionC = optionC,
            OptionD = optionD,
            CorrectKey = correctKey
        };
    }

    public void Deactivate()
    {
        IsActive = false;
        SetUpdated();
    }
}
