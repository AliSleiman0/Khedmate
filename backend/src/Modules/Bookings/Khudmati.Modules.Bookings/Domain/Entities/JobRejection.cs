namespace Khudmati.Modules.Bookings.Domain.Entities;

public class JobRejection
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid JobId { get; private set; }
    public Guid ProviderId { get; private set; }
    public DateTime RejectedAt { get; private set; } = DateTime.UtcNow;

    private JobRejection() { }

    public static JobRejection Create(Guid jobId, Guid providerId) =>
        new() { JobId = jobId, ProviderId = providerId };
}
