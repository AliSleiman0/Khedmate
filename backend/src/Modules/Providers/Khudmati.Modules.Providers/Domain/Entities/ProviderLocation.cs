namespace Khudmati.Modules.Providers.Domain.Entities;

public class ProviderLocation
{
    public Guid ProviderId { get; private set; }
    public decimal Latitude { get; private set; }
    public decimal Longitude { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    private ProviderLocation() { }

    public static ProviderLocation Create(Guid providerId, decimal latitude, decimal longitude) =>
        new() { ProviderId = providerId, Latitude = latitude, Longitude = longitude, UpdatedAt = DateTime.UtcNow };

    public void Update(decimal latitude, decimal longitude)
    {
        Latitude = latitude;
        Longitude = longitude;
        UpdatedAt = DateTime.UtcNow;
    }
}
