using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Notifications.Domain.Entities;

public class Notification : AuditableEntity
{
    public Guid RecipientId { get; private set; }
    public string RecipientType { get; private set; } = string.Empty; // "customer" | "provider"
    public string Title { get; private set; } = string.Empty;
    public string Body { get; private set; } = string.Empty;
    public bool IsRead { get; private set; } = false;

    private Notification() { }

    public static Notification Create(
        Guid recipientId,
        string recipientType,
        string title,
        string body) =>
        new()
        {
            RecipientId = recipientId,
            RecipientType = recipientType,
            Title = title,
            Body = body
        };

    public void MarkRead()
    {
        IsRead = true;
        SetUpdated();
    }
}
