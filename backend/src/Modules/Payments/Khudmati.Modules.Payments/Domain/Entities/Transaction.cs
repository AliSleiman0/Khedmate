using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Payments.Domain.Entities;

public class Transaction : AuditableEntity
{
    public Guid JobId { get; private set; }
    public Guid CustomerId { get; private set; }
    public Guid ProviderId { get; private set; }
    public string? StripePaymentIntentId { get; private set; }
    public decimal GrossAmount { get; private set; }
    public decimal CommissionRate { get; private set; }   // e.g. 0.2000 = 20%
    public decimal CommissionAmount { get; private set; }
    public decimal NetAmount { get; private set; }        // GrossAmount - CommissionAmount
    public string Currency { get; private set; } = "usd";
    public string Status { get; private set; } = "Pending";
    // Status values: Pending, Paid, Held, Released, Disputed, Refunded
    public DateTime? HoldUntil { get; private set; }     // set when status → Held
    public string? StripeTransferId { get; private set; } // set when status → Released

    // Referral / credit deductions (V1: recorded at intent time)
    public decimal? ReferralDiscountAmount { get; private set; }
    public decimal? CreditAppliedAmount { get; private set; }

    private Transaction() { }

    public static Transaction Create(
        Guid jobId,
        Guid customerId,
        Guid providerId,
        decimal grossAmount,
        string currency,
        decimal commissionRate,
        string? stripePaymentIntentId = null)
    {
        var commission = Math.Round(grossAmount * commissionRate, 2);
        return new Transaction
        {
            JobId = jobId,
            CustomerId = customerId,
            ProviderId = providerId,
            StripePaymentIntentId = stripePaymentIntentId,
            GrossAmount = grossAmount,
            CommissionRate = commissionRate,
            CommissionAmount = commission,
            NetAmount = grossAmount - commission,
            Currency = currency,
            Status = "Pending"
        };
    }

    /// <summary>Creates a transaction for intent-only (before job is known).</summary>
    public static Transaction CreateIntent(
        Guid customerId,
        decimal grossAmount,
        string currency,
        decimal commissionRate,
        string stripePaymentIntentId,
        decimal? referralDiscountAmount = null,
        decimal? creditAppliedAmount = null)
    {
        var commission = Math.Round(grossAmount * commissionRate, 2);
        return new Transaction
        {
            JobId = Guid.Empty,        // will be linked later via LinkToJob
            CustomerId = customerId,
            ProviderId = Guid.Empty,   // will be linked later
            StripePaymentIntentId = stripePaymentIntentId,
            GrossAmount = grossAmount,
            CommissionRate = commissionRate,
            CommissionAmount = commission,
            NetAmount = grossAmount - commission,
            Currency = currency,
            Status = "Pending",
            ReferralDiscountAmount = referralDiscountAmount,
            CreditAppliedAmount = creditAppliedAmount
        };
    }

    public void LinkToJob(Guid jobId)
    {
        JobId = jobId;
        SetUpdated();
    }

    /// <summary>Called when a provider accepts the job — sets the final provider for payout.</summary>
    public void AssignProvider(Guid providerId)
    {
        ProviderId = providerId;
        SetUpdated();
    }

    public void MarkPaid()
    {
        if (Status != "Pending")
            throw new InvalidOperationException("Only Pending transactions can be marked Paid.");
        Status = "Paid";
        SetUpdated();
    }

    public void MarkHeld()
    {
        if (Status != "Paid")
            throw new InvalidOperationException("Only Paid transactions can be held.");
        Status = "Held";
        HoldUntil = DateTime.UtcNow.AddHours(24);
        SetUpdated();
    }

    public void MarkReleased(string stripeTransferId)
    {
        if (Status != "Held")
            throw new InvalidOperationException("Only Held transactions can be released.");
        Status = "Released";
        StripeTransferId = stripeTransferId;
        SetUpdated();
    }

    public void MarkDisputed()
    {
        if (Status != "Held")
            throw new InvalidOperationException("Only Held transactions can be disputed.");
        Status = "Disputed";
        SetUpdated();
    }

    public void MarkRefunded()
    {
        Status = "Refunded";
        SetUpdated();
    }
}
