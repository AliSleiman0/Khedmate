using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Bookings.Domain.Entities;

public class Dispute : AuditableEntity
{
    public Guid JobId { get; private set; }
    public Guid CustomerId { get; private set; }
    public Guid ProviderId { get; private set; }
    public string Complaint { get; private set; } = string.Empty;
    public string? AdminNote { get; private set; }
    public string Status { get; private set; } = "Open"; // Open | Resolved | Rejected
    public DateTime? ResolvedAt { get; private set; }
    public Guid? ResolvedByAdminId { get; private set; }

    private Dispute() { }

    public static Dispute Open(Guid jobId, Guid customerId, Guid providerId, string complaint) =>
        new()
        {
            JobId = jobId,
            CustomerId = customerId,
            ProviderId = providerId,
            Complaint = complaint
        };

    public void Resolve(string status, string adminNote, Guid adminId)
    {
        Status = status;
        AdminNote = adminNote;
        ResolvedAt = DateTime.UtcNow;
        ResolvedByAdminId = adminId;
        SetUpdated();
    }
}
