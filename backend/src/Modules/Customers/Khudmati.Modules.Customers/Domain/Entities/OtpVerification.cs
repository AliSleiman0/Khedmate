namespace Khudmati.Modules.Customers.Domain.Entities;

public class OtpVerification
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid AccountId { get; private set; }
    public string OtpHash { get; private set; } = string.Empty;
    public DateTime ExpiresAt { get; private set; }
    public int Attempts { get; private set; } = 0;
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;

    private OtpVerification() { }

    public static OtpVerification Create(Guid accountId, string otpHash, DateTime expiresAt) =>
        new() { AccountId = accountId, OtpHash = otpHash, ExpiresAt = expiresAt };

    public void IncrementAttempts() => Attempts++;
}
