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
}
