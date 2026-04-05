namespace Khudmati.Modules.Bookings.Domain.Entities;

public class JobPhoto
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid JobId { get; private set; }
    public string Url { get; private set; } = string.Empty;
    public string PhotoType { get; private set; } = "before"; // "before" | "after"
    public DateTime UploadedAt { get; private set; } = DateTime.UtcNow;

    private JobPhoto() { }

    public static JobPhoto Create(Guid jobId, string url, string photoType = "before") =>
        new() { JobId = jobId, Url = url, PhotoType = photoType };
}
