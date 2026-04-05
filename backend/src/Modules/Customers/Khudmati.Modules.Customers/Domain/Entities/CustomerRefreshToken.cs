namespace Khudmati.Modules.Customers.Domain.Entities;

public class CustomerRefreshToken
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid AccountId { get; private set; }
    public string TokenHash { get; private set; } = string.Empty;
    public DateTime ExpiresAt { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;

    private CustomerRefreshToken() { }

    public static CustomerRefreshToken Create(Guid accountId, string tokenHash, DateTime expiresAt) =>
        new() { AccountId = accountId, TokenHash = tokenHash, ExpiresAt = expiresAt };

    public static CustomerRefreshToken Create(Guid id, Guid accountId, string tokenHash, DateTime expiresAt) =>
        new() { Id = id, AccountId = accountId, TokenHash = tokenHash, ExpiresAt = expiresAt };
}
