namespace Khudmati.API.Domain;

public class PlatformConfig
{
    public int Id { get; private set; }
    public int CommissionRate { get; private set; } = 15;
    public int JobTimeoutMinutes { get; private set; } = 2;
    public int MaxProvidersPerArea { get; private set; } = 10;
    public int MinRatingToRemain { get; private set; } = 50;
    public int AutoRefundThresholdDays { get; private set; } = 1;
    public DateTime UpdatedAt { get; private set; } = DateTime.UtcNow;
    public Guid? UpdatedByAdminId { get; private set; }

    private PlatformConfig() { }

    public static PlatformConfig CreateDefaults() => new();

    public void Update(int commissionRate, int jobTimeoutMinutes, int maxProvidersPerArea,
                       int minRatingToRemain, int autoRefundThresholdDays, Guid adminId)
    {
        CommissionRate = commissionRate;
        JobTimeoutMinutes = jobTimeoutMinutes;
        MaxProvidersPerArea = maxProvidersPerArea;
        MinRatingToRemain = minRatingToRemain;
        AutoRefundThresholdDays = autoRefundThresholdDays;
        UpdatedAt = DateTime.UtcNow;
        UpdatedByAdminId = adminId;
    }
}
