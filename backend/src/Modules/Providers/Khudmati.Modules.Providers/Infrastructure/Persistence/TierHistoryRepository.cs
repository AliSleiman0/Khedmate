using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Infrastructure.Persistence;

public interface ITierHistoryRepository
{
    Task<IReadOnlyList<TierHistory>> GetByProviderIdAsync(Guid providerId, CancellationToken ct = default);
    Task AddAsync(TierHistory history, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class TierHistoryRepository : ITierHistoryRepository
{
    private readonly AppDbContext _context;

    public TierHistoryRepository(AppDbContext context) => _context = context;

    public async Task<IReadOnlyList<TierHistory>> GetByProviderIdAsync(Guid providerId, CancellationToken ct = default) =>
        await _context.Set<TierHistory>()
            .Where(h => h.ProviderId == providerId)
            .OrderByDescending(h => h.ChangedAt)
            .ToListAsync(ct);

    public async Task AddAsync(TierHistory history, CancellationToken ct = default) =>
        await _context.Set<TierHistory>().AddAsync(history, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
