using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Bookings.Infrastructure.Persistence;

public interface IBookingsRepository
{
    Task<Job?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<(IReadOnlyList<Job> Jobs, int Total)> GetByCustomerIdAsync(
        Guid customerId, JobStatus? status, int page, int pageSize, CancellationToken ct = default);
    Task<IReadOnlyList<Job>> GetPendingNonExpiredJobsAsync(CancellationToken ct = default);
    Task<IReadOnlyList<Job>> GetExpiredPendingJobsAsync(CancellationToken ct = default);
    Task<IReadOnlyList<Job>> GetAcceptedJobsByProviderAsync(Guid providerId, CancellationToken ct = default);
    Task AddAsync(Job job, CancellationToken ct = default);
    Task AddPhotoAsync(JobPhoto photo, CancellationToken ct = default);
    Task AddRejectionAsync(JobRejection rejection, CancellationToken ct = default);
    Task<Job?> AcceptJobWithLockAsync(Guid jobId, Guid providerId, CancellationToken ct = default);
    Task<string> GenerateReferenceNumberAsync(CancellationToken ct = default);
    Task AddStatusHistoryAsync(JobStatusHistory history, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);

    Task<(IReadOnlyList<AdminJobSummaryDto> Items, int TotalCount, AdminJobStatsDto Stats)> GetAdminJobsAsync(
        string? search, JobStatus? status, DateTime? from, DateTime? to,
        int page, int pageSize, CancellationToken ct = default);

    // Dispute methods
    Task<Dispute?> GetDisputeByJobIdAsync(Guid jobId, CancellationToken ct = default);
    Task AddDisputeAsync(Dispute dispute, CancellationToken ct = default);
    Task<Dispute?> GetDisputeByIdAsync(Guid disputeId, CancellationToken ct = default);

    // Referral helper
    Task<int> CountPaidJobsByCustomerAsync(Guid customerId, CancellationToken ct = default);

    // Provider completed jobs
    Task<IReadOnlyList<Job>> GetPaidJobsByProviderAsync(Guid providerId, int page, int pageSize, CancellationToken ct = default);
}

public class BookingsRepository : IBookingsRepository
{
    private readonly AppDbContext _context;

    public BookingsRepository(AppDbContext context) => _context = context;

    public async Task<Job?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _context.Set<Job>()
            .Include(j => j.Photos)
            .FirstOrDefaultAsync(j => j.Id == id, ct);

    public async Task<(IReadOnlyList<Job> Jobs, int Total)> GetByCustomerIdAsync(
        Guid customerId, JobStatus? status, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Set<Job>()
            .Include(j => j.Photos)
            .Where(j => j.CustomerId == customerId);

        if (status.HasValue)
            query = query.Where(j => j.Status == status.Value);

        var total = await query.CountAsync(ct);
        var jobs = await query
            .OrderByDescending(j => j.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (jobs, total);
    }

    public async Task<IReadOnlyList<Job>> GetPendingNonExpiredJobsAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        return await _context.Set<Job>()
            .Include(j => j.Photos)
            .Where(j => j.Status == JobStatus.Pending && j.ExpiresAt > now)
            .OrderByDescending(j => j.CreatedAt)
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<Job>> GetExpiredPendingJobsAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        return await _context.Set<Job>()
            .Where(j => j.Status == JobStatus.Pending && j.ExpiresAt <= now)
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<Job>> GetAcceptedJobsByProviderAsync(Guid providerId, CancellationToken ct = default) =>
        await _context.Set<Job>()
            .Include(j => j.Photos)
            .Where(j => j.ProviderId == providerId &&
                        (j.Status == JobStatus.Accepted || j.Status == JobStatus.EnRoute ||
                         j.Status == JobStatus.InProgress || j.Status == JobStatus.Completed ||
                         j.Status == JobStatus.Paid))
            .OrderByDescending(j => j.AcceptedAt)
            .ToListAsync(ct);

    public async Task AddAsync(Job job, CancellationToken ct = default) =>
        await _context.Set<Job>().AddAsync(job, ct);

    public async Task AddPhotoAsync(JobPhoto photo, CancellationToken ct = default) =>
        await _context.Set<JobPhoto>().AddAsync(photo, ct);

    public async Task AddRejectionAsync(JobRejection rejection, CancellationToken ct = default) =>
        await _context.Set<JobRejection>().AddAsync(rejection, ct);

    public async Task<Job?> AcceptJobWithLockAsync(Guid jobId, Guid providerId, CancellationToken ct = default)
    {
        await using var tx = await _context.Database.BeginTransactionAsync(ct);
        try
        {
            // Lock the row to prevent concurrent accepts
            await _context.Database.ExecuteSqlAsync(
                $"SELECT id FROM bookings.jobs WHERE id = {jobId} FOR UPDATE", ct);

            var job = await _context.Set<Job>()
                .Include(j => j.Photos)
                .FirstOrDefaultAsync(j => j.Id == jobId, ct);

            if (job is null
                || job.Status != Domain.Enums.JobStatus.Pending
                || job.ExpiresAt <= DateTime.UtcNow)
            {
                await tx.RollbackAsync(ct);
                return null;
            }

            job.Accept(providerId);
            await _context.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            return job;
        }
        catch
        {
            await tx.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<string> GenerateReferenceNumberAsync(CancellationToken ct = default)
    {
        var date = DateTime.UtcNow.ToString("yyyyMMdd");
        var conn = _context.Database.GetDbConnection();

        using var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT nextval('bookings.daily_job_seq')";

        if (conn.State != System.Data.ConnectionState.Open)
            await _context.Database.OpenConnectionAsync(ct);

        var result = await cmd.ExecuteScalarAsync(ct);
        var seq = Convert.ToInt64(result);

        return $"KH-{date}-{seq:D4}";
    }

    public async Task AddStatusHistoryAsync(JobStatusHistory history, CancellationToken ct = default) =>
        await _context.Set<JobStatusHistory>().AddAsync(history, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);

    public async Task<(IReadOnlyList<AdminJobSummaryDto> Items, int TotalCount, AdminJobStatsDto Stats)> GetAdminJobsAsync(
        string? search, JobStatus? status, DateTime? from, DateTime? to,
        int page, int pageSize, CancellationToken ct = default)
    {
        var jobsQuery =
            from job in _context.Set<Job>()
            join customer in _context.Set<Customer>() on job.CustomerId equals customer.Id into custGroup
            from customer in custGroup.DefaultIfEmpty()
            join provider in _context.Set<Provider>() on job.ProviderId equals (Guid?)provider.Id into provGroup
            from provider in provGroup.DefaultIfEmpty()
            join tx in _context.Set<Transaction>() on job.Id equals tx.JobId into txGroup
            from tx in txGroup.DefaultIfEmpty()
            select new
            {
                job.Id,
                job.ReferenceNumber,
                job.CustomerId,
                CustomerName = customer == null ? "" : customer.FullName,
                job.ProviderId,
                ProviderName = provider == null ? (string?)null : provider.FullName,
                job.CategoryId,
                job.Status,
                job.CreatedAt,
                job.AcceptedAt,
                job.PaidAt,
                Amount = tx == null ? (decimal?)null : tx.GrossAmount
            };

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            jobsQuery = jobsQuery.Where(j =>
                j.ReferenceNumber.ToLower().Contains(searchLower) ||
                j.CustomerName.ToLower().Contains(searchLower) ||
                (j.ProviderName != null && j.ProviderName.ToLower().Contains(searchLower)));
        }

        if (status.HasValue)
            jobsQuery = jobsQuery.Where(j => j.Status == status.Value);

        if (from.HasValue)
            jobsQuery = jobsQuery.Where(j => j.CreatedAt >= from.Value);

        if (to.HasValue)
            jobsQuery = jobsQuery.Where(j => j.CreatedAt <= to.Value);

        var totalCount = await jobsQuery.CountAsync(ct);

        var items = await jobsQuery
            .OrderByDescending(j => j.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var summaries = items.Select(j => new AdminJobSummaryDto(
            j.Id,
            j.ReferenceNumber,
            j.CustomerId,
            j.CustomerName,
            j.ProviderId,
            j.ProviderName,
            j.CategoryId,
            j.Status,
            j.CreatedAt,
            j.AcceptedAt,
            j.PaidAt,
            j.Amount
        )).ToList();

        // Global stats (unfiltered by current search/status/date)
        var allStatuses = await _context.Set<Job>()
            .GroupBy(_ => 1)
            .Select(g => new
            {
                Total = g.Count(),
                Pending = g.Count(j => j.Status == JobStatus.Pending),
                Active = g.Count(j =>
                    j.Status == JobStatus.Accepted ||
                    j.Status == JobStatus.EnRoute ||
                    j.Status == JobStatus.InProgress),
                CompletedOrPaid = g.Count(j =>
                    j.Status == JobStatus.Completed ||
                    j.Status == JobStatus.Paid)
            })
            .FirstOrDefaultAsync(ct);

        var stats = allStatuses is null
            ? new AdminJobStatsDto(0, 0, 0, 0)
            : new AdminJobStatsDto(
                allStatuses.Total,
                allStatuses.Pending,
                allStatuses.Active,
                allStatuses.CompletedOrPaid);

        return (summaries, totalCount, stats);
    }

    // ── Dispute methods ───────────────────────────────────────────────────────

    public async Task<Dispute?> GetDisputeByJobIdAsync(Guid jobId, CancellationToken ct = default) =>
        await _context.Set<Dispute>()
            .Where(d => d.JobId == jobId)
            .OrderByDescending(d => d.CreatedAt)
            .FirstOrDefaultAsync(ct);

    public async Task AddDisputeAsync(Dispute dispute, CancellationToken ct = default) =>
        await _context.Set<Dispute>().AddAsync(dispute, ct);

    public async Task<Dispute?> GetDisputeByIdAsync(Guid disputeId, CancellationToken ct = default) =>
        await _context.Set<Dispute>().FirstOrDefaultAsync(d => d.Id == disputeId, ct);

    public async Task<int> CountPaidJobsByCustomerAsync(Guid customerId, CancellationToken ct = default) =>
        await _context.Set<Job>()
            .CountAsync(j => j.CustomerId == customerId && j.Status == JobStatus.Paid, ct);

    public async Task<IReadOnlyList<Job>> GetPaidJobsByProviderAsync(Guid providerId, int page, int pageSize, CancellationToken ct = default) =>
        await _context.Set<Job>()
            .Include(j => j.Photos)
            .Where(j => j.ProviderId == providerId && j.Status == JobStatus.Paid)
            .OrderByDescending(j => j.PaidAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);
}
