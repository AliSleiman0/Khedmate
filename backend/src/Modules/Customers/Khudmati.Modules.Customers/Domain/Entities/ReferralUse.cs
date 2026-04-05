namespace Khudmati.Modules.Customers.Domain.Entities;

/// <summary>
/// Tracks the link between a referrer and the customer they referred.
/// Status transitions: Pending → Completed.
/// </summary>
public class ReferralUse
{
    public Guid Id { get; private set; }
    public Guid ReferrerCustomerId { get; private set; }
    public Guid ReferredCustomerId { get; private set; }
    public Guid? QualifyingBookingId { get; private set; }
    public decimal ReferrerCreditAmount { get; private set; }
    public decimal RefereeDiscountPct { get; private set; }
    public string Status { get; private set; } = "Pending"; // Pending | Completed
    public DateTime CreatedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }

    private ReferralUse() { }

    public static ReferralUse Create(
        Guid referrerCustomerId,
        Guid referredCustomerId,
        decimal referrerCreditAmount,
        decimal refereeDiscountPct) =>
        new()
        {
            Id = Guid.NewGuid(),
            ReferrerCustomerId = referrerCustomerId,
            ReferredCustomerId = referredCustomerId,
            ReferrerCreditAmount = referrerCreditAmount,
            RefereeDiscountPct = refereeDiscountPct,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };

    public void Complete(Guid qualifyingBookingId)
    {
        Status = "Completed";
        QualifyingBookingId = qualifyingBookingId;
        CompletedAt = DateTime.UtcNow;
    }
}
