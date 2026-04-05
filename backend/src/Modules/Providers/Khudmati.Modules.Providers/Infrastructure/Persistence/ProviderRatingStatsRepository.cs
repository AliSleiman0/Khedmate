using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Infrastructure.Persistence;

public interface IProviderRatingStatsRepository
{
    Task<ProviderRatingStats?> GetByProviderIdAsync(Guid providerId, CancellationToken ct = default);
    Task UpsertRatingAsync(Guid providerId, bool isPositive, string[] tags, CancellationToken ct = default);
}

public class ProviderRatingStatsRepository : IProviderRatingStatsRepository
{
    private readonly AppDbContext _context;

    public ProviderRatingStatsRepository(AppDbContext context) => _context = context;

    public async Task<ProviderRatingStats?> GetByProviderIdAsync(
        Guid providerId, CancellationToken ct = default) =>
        await _context.Set<ProviderRatingStats>()
            .FirstOrDefaultAsync(s => s.ProviderId == providerId, ct);

    public async Task UpsertRatingAsync(
        Guid providerId, bool isPositive, string[] tags, CancellationToken ct = default)
    {
        var positiveInc = isPositive ? 1 : 0;
        var negativeInc = isPositive ? 0 : 1;

        // Atomic upsert of counts and positive rate
        await _context.Database.ExecuteSqlAsync($@"
            INSERT INTO providers.rating_stats
                (provider_id, total_ratings, positive_count, negative_count, positive_rate, top_tags, updated_at)
            VALUES
                ({providerId}, 1, {positiveInc}, {negativeInc},
                 {(decimal)positiveInc * 100}, '{{}}', now())
            ON CONFLICT (provider_id) DO UPDATE SET
                total_ratings  = providers.rating_stats.total_ratings + 1,
                positive_count = providers.rating_stats.positive_count + {positiveInc},
                negative_count = providers.rating_stats.negative_count + {negativeInc},
                positive_rate  = ROUND(
                    (providers.rating_stats.positive_count + {positiveInc})::decimal
                    / (providers.rating_stats.total_ratings + 1) * 100, 2),
                updated_at     = now()", ct);

        // Update top_tags every 10 ratings (avoid doing it on every insert)
        var stats = await _context.Set<ProviderRatingStats>()
            .FirstOrDefaultAsync(s => s.ProviderId == providerId, ct);

        if (stats is not null && stats.TotalRatings % 10 == 0)
            await RefreshTopTagsAsync(providerId, ct);
    }

    private async Task RefreshTopTagsAsync(Guid providerId, CancellationToken ct)
    {
        // Compute top 3 tags from all customer→provider ratings for this provider
        await _context.Database.ExecuteSqlAsync($@"
            UPDATE providers.rating_stats
            SET top_tags = (
                SELECT ARRAY(
                    SELECT tag
                    FROM (
                        SELECT UNNEST(tags) AS tag, COUNT(*) AS cnt
                        FROM bookings.ratings
                        WHERE ratee_id = {providerId} AND rater_type = 'customer'
                        GROUP BY tag
                        ORDER BY cnt DESC
                        LIMIT 3
                    ) t
                )
            ),
            updated_at = now()
            WHERE provider_id = {providerId}", ct);
    }
}
