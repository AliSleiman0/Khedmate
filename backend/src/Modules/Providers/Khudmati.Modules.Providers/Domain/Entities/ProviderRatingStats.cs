namespace Khudmati.Modules.Providers.Domain.Entities;

public class ProviderRatingStats
{
    public Guid ProviderId { get; private set; }
    public int TotalRatings { get; private set; }
    public int PositiveCount { get; private set; }
    public int NegativeCount { get; private set; }
    public decimal PositiveRate { get; private set; }
    public string[] TopTags { get; private set; } = Array.Empty<string>();
    public DateTime UpdatedAt { get; private set; }

    private ProviderRatingStats() { }
}
