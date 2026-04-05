using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Infrastructure.Persistence;

public interface IProviderLocationRepository
{
    Task<ProviderLocation?> GetByProviderIdAsync(Guid providerId, CancellationToken ct = default);
    Task UpsertAsync(Guid providerId, decimal latitude, decimal longitude, CancellationToken ct = default);
}

public class ProviderLocationRepository : IProviderLocationRepository
{
    private readonly AppDbContext _context;

    public ProviderLocationRepository(AppDbContext context) => _context = context;

    public async Task<ProviderLocation?> GetByProviderIdAsync(Guid providerId, CancellationToken ct = default) =>
        await _context.Set<ProviderLocation>()
            .FirstOrDefaultAsync(l => l.ProviderId == providerId, ct);

    public async Task UpsertAsync(Guid providerId, decimal latitude, decimal longitude, CancellationToken ct = default)
    {
        await _context.Database.ExecuteSqlAsync(
            $"""
            INSERT INTO providers.locations (provider_id, latitude, longitude, updated_at)
            VALUES ({providerId}, {latitude}, {longitude}, now())
            ON CONFLICT (provider_id) DO UPDATE
              SET latitude = EXCLUDED.latitude,
                  longitude = EXCLUDED.longitude,
                  updated_at = now()
            """, ct);
    }
}
