namespace Khudmati.API.Domain;

/// <summary>Maps to public.reminder_rules table (Feature #19).</summary>
public class ReminderRule
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public string Category { get; private set; } = string.Empty;
    public int IntervalDays { get; private set; }
    public bool IsActive { get; private set; } = true;
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; private set; }

    private ReminderRule() { }

    public static ReminderRule Create(string category, int intervalDays) =>
        new() { Category = category, IntervalDays = intervalDays, IsActive = true };

    public void Update(int intervalDays, bool isActive)
    {
        IntervalDays = intervalDays;
        IsActive = isActive;
        UpdatedAt = DateTime.UtcNow;
    }
}
