using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Bookings.Infrastructure.Persistence;

public interface IRatingRepository
{
    Task AddAsync(Rating rating, CancellationToken ct = default);
    Task<Rating?> GetByJobAndRaterTypeAsync(Guid jobId, string raterType, CancellationToken ct = default);
    Task<IReadOnlyList<Job>> GetPendingRatingJobsAsync(Guid userId, string raterType, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class RatingRepository : IRatingRepository
{
    private readonly AppDbContext _context;

    public RatingRepository(AppDbContext context) => _context = context;

    public async Task AddAsync(Rating rating, CancellationToken ct = default) =>
        await _context.Set<Rating>().AddAsync(rating, ct);

    public async Task<Rating?> GetByJobAndRaterTypeAsync(
        Guid jobId, string raterType, CancellationToken ct = default) =>
        await _context.Set<Rating>()
            .FirstOrDefaultAsync(r => r.JobId == jobId && r.RaterType == raterType, ct);

    public async Task<IReadOnlyList<Job>> GetPendingRatingJobsAsync(
        Guid userId, string raterType, CancellationToken ct = default)
    {
        var cutoff = DateTime.UtcNow.AddHours(-48);

        // Jobs already rated by this user in this direction
        var ratedJobIds = await _context.Set<Rating>()
            .Where(r => r.RaterType == raterType && r.RaterId == userId)
            .Select(r => r.JobId)
            .ToListAsync(ct);

        if (raterType == "customer")
        {
            return await _context.Set<Job>()
                .Where(j => j.CustomerId == userId
                         && j.Status == JobStatus.Paid
                         && j.PaidAt != null
                         && j.PaidAt > cutoff
                         && !ratedJobIds.Contains(j.Id))
                .ToListAsync(ct);
        }
        else
        {
            return await _context.Set<Job>()
                .Where(j => j.ProviderId == userId
                         && j.Status == JobStatus.Paid
                         && j.PaidAt != null
                         && j.PaidAt > cutoff
                         && !ratedJobIds.Contains(j.Id))
                .ToListAsync(ct);
        }
    }

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
