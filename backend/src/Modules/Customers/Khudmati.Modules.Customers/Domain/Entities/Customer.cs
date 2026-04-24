using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Customers.Domain.Entities;

public class Customer : AuditableEntity
{
    public string FullName { get; private set; } = string.Empty;
    public string Phone { get; private set; } = string.Empty;
    public string? Email { get; private set; }
    public string PasswordHash { get; private set; } = string.Empty;
    public bool IsVerified { get; private set; } = false;
    public bool IsActive { get; private set; } = true;

    private Customer() { }

    public static Customer Create(string fullName, string phone, string? email, string passwordHash) =>
        new() { FullName = fullName, Phone = phone, Email = email, PasswordHash = passwordHash };

    public void SetVerified()
    {
        IsVerified = true;
        SetUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        SetUpdated();
    }

    public void UpdatePassword(string newPasswordHash)
    {
        PasswordHash = newPasswordHash;
        SetUpdated();
    }

    /// <summary>
    /// Apple 5.1.1(v) / Google Data Safety: user-initiated account deletion.
    /// Anonymises PII in place so financial / audit rows (bookings, ratings,
    /// referrals) retain foreign-key integrity while the account itself becomes
    /// unusable. Deletes refresh tokens and OTPs out-of-band — the Phone
    /// placeholder (`DEL_<id>`) preserves the unique index.
    /// </summary>
    public void SoftDeletePii()
    {
        FullName = "DELETED";
        Email = null;
        Phone = "DEL_" + Id.ToString("N").Substring(0, 20);
        PasswordHash = string.Empty;
        IsActive = false;
        SetUpdated();
    }
}
