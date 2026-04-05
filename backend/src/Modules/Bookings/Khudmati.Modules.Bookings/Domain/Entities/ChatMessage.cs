namespace Khudmati.Modules.Bookings.Domain.Entities;

public class ChatMessage
{
    public Guid Id { get; private set; }
    public Guid JobId { get; private set; }
    public Guid SenderId { get; private set; }
    public string SenderType { get; private set; } = string.Empty; // "customer" or "provider"
    public string Text { get; private set; } = string.Empty;
    public DateTime SentAt { get; private set; }
    public DateTime? ReadAt { get; private set; }

    private ChatMessage() { } // EF constructor

    public static ChatMessage Create(Guid jobId, Guid senderId, string senderType, string text)
        => new()
        {
            Id = Guid.NewGuid(),
            JobId = jobId,
            SenderId = senderId,
            SenderType = senderType,
            Text = text,
            SentAt = DateTime.UtcNow
        };

    public void MarkRead()
    {
        ReadAt ??= DateTime.UtcNow;
    }
}
