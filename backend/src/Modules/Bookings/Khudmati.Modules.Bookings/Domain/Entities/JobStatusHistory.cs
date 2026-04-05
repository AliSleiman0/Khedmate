namespace Khudmati.Modules.Bookings.Domain.Entities;

public class JobStatusHistory
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid JobId { get; private set; }
    public string PreviousStatus { get; private set; } = string.Empty;
    public string NewStatus { get; private set; } = string.Empty;
    public Guid ChangedBy { get; private set; }
    public DateTime ChangedAt { get; private set; }

    private JobStatusHistory() { }

    public static JobStatusHistory Create(Guid jobId, string previousStatus, string newStatus, Guid changedBy) =>
        new()
        {
            JobId = jobId,
            PreviousStatus = previousStatus,
            NewStatus = newStatus,
            ChangedBy = changedBy,
            ChangedAt = DateTime.UtcNow
        };
}
