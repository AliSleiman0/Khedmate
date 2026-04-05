namespace Khudmati.Modules.Customers.Domain.Entities;

public class ReferralCode
{
    public Guid Id { get; private set; }
    public Guid CustomerId { get; private set; }
    public string Code { get; private set; } = string.Empty;
    public DateTime CreatedAt { get; private set; }

    private ReferralCode() { }

    public static ReferralCode Create(Guid customerId, string code) =>
        new() { Id = Guid.NewGuid(), CustomerId = customerId, Code = code, CreatedAt = DateTime.UtcNow };
}
