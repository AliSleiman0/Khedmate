using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Providers.Domain.Entities;

public class Provider : AuditableEntity
{
    public string FullName { get; private set; } = string.Empty;
    public string Phone { get; private set; } = string.Empty;
    public string? Email { get; private set; }
    public string PasswordHash { get; private set; } = string.Empty;
    public bool IsVerified { get; private set; } = false;
    public string[] ServiceCategories { get; private set; } = Array.Empty<string>();
    public VerificationTier Tier { get; private set; } = VerificationTier.Unverified;
    public double Rating { get; private set; } = 0;
    public int JobsCompleted { get; private set; } = 0;
    public bool IsOnline { get; private set; } = false;

    private Provider() { }

    public static Provider Create(string fullName, string phone, string? email, string passwordHash, string[] serviceCategories) =>
        new() { FullName = fullName, Phone = phone, Email = email, PasswordHash = passwordHash, ServiceCategories = serviceCategories };

    public void SetVerified()
    {
        IsVerified = true;
        SetUpdated();
    }

    public void UpgradeTier(VerificationTier newTier)
    {
        if (newTier <= Tier)
            throw new InvalidOperationException("Cannot downgrade verification tier.");
        Tier = newTier;
        SetUpdated();
    }

    public void UpdateRating(double newRating)
    {
        if (newRating < 0 || newRating > 5)
            throw new ArgumentOutOfRangeException(nameof(newRating), "Rating must be between 0 and 5.");
        Rating = newRating;
        SetUpdated();
    }

    public void IncrementJobsCompleted()
    {
        JobsCompleted++;
        SetUpdated();
    }

    public void SetOnline(bool online)
    {
        IsOnline = online;
        SetUpdated();
    }

    public void UpdateFullName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName) || fullName.Length < 2)
            throw new ArgumentException("Full name must be at least 2 characters.", nameof(fullName));
        FullName = fullName.Trim();
        SetUpdated();
    }

    /// <summary>
    /// Apple 5.1.1(v) / Google Data Safety: user-initiated account deletion.
    /// Anonymises PII in place so jobs / ratings / payout history retain
    /// foreign-key integrity while the account itself becomes unusable.
    /// Refresh tokens, OTPs, and location rows are deleted out-of-band; the
    /// Phone placeholder (`DEL_<id>`) preserves the unique index.
    /// </summary>
    public void SoftDeletePii()
    {
        FullName = "DELETED";
        Email = null;
        Phone = "DEL_" + Id.ToString("N").Substring(0, 20);
        PasswordHash = string.Empty;
        ServiceCategories = Array.Empty<string>();
        IsOnline = false;
        SetUpdated();
    }
}
