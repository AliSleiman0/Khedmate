namespace Khudmati.Modules.Customers.Domain.Entities;

/// <summary>
/// Platform credit wallet entry per customer.
/// source_type: Referral | Promo | Refund
/// </summary>
public class CustomerCredit
{
    public Guid Id { get; private set; }
    public Guid CustomerId { get; private set; }
    public decimal Amount { get; private set; }      // remaining balance (always positive)
    public string SourceType { get; private set; } = string.Empty; // Referral | Promo | Refund
    public Guid? SourceId { get; private set; }      // referral_uses.id etc.
    public DateTime ExpiresAt { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? UsedAt { get; private set; }    // set when fully consumed

    private CustomerCredit() { }

    public static CustomerCredit Create(
        Guid customerId,
        decimal amount,
        string sourceType,
        Guid? sourceId,
        DateTime expiresAt) =>
        new()
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            Amount = amount,
            SourceType = sourceType,
            SourceId = sourceId,
            ExpiresAt = expiresAt,
            CreatedAt = DateTime.UtcNow
        };

    /// <summary>Mark fully consumed.</summary>
    public void MarkUsed() => UsedAt = DateTime.UtcNow;

    /// <summary>Reduce remaining balance (for partial use); creates a new credit row for remainder.</summary>
    public CustomerCredit ApplyPartial(decimal toApply)
    {
        if (toApply >= Amount)
        {
            MarkUsed();
            return this;
        }

        // Return a new credit row for remaining balance (same expiry)
        var remaining = CustomerCredit.Create(CustomerId, Amount - toApply, SourceType, SourceId, ExpiresAt);
        MarkUsed();
        return remaining;
    }
}
