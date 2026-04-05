namespace Khudmati.API.Domain;

public class AuditLogEntry
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid AdminId { get; private set; }
    public string ActionType { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public string? TargetType { get; private set; }
    public string? TargetId { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;

    private AuditLogEntry() { }

    public static AuditLogEntry Create(Guid adminId, string actionType, string description,
                                        string? targetType = null, string? targetId = null) =>
        new()
        {
            AdminId = adminId,
            ActionType = actionType,
            Description = description,
            TargetType = targetType,
            TargetId = targetId
        };
}
