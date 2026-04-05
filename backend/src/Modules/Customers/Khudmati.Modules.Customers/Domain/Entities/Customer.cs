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
}
