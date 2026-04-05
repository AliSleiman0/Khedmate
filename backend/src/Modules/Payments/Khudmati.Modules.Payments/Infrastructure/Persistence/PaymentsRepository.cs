using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Payments.Infrastructure.Persistence;

public interface IPaymentsRepository
{
    Task<Transaction?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Transaction?> GetByJobIdAsync(Guid jobId, CancellationToken ct = default);
    Task<Transaction?> GetByJobIdPaidAsync(Guid jobId, CancellationToken ct = default);
    Task<Transaction?> GetByPaymentIntentIdAsync(string paymentIntentId, CancellationToken ct = default);
    Task<IReadOnlyList<Transaction>> GetHeldReadyToReleaseAsync(CancellationToken ct = default);
    Task<(IReadOnlyList<Transaction> Items, int Total)> GetByCustomerIdPagedAsync(
        Guid customerId, int page, int pageSize, CancellationToken ct = default);
    Task<(IReadOnlyList<Transaction> Items, int Total)> GetByProviderIdPagedAsync(
        Guid providerId, int page, int pageSize, CancellationToken ct = default);
    Task<IReadOnlyList<Transaction>> GetAllByProviderIdAsync(Guid providerId, CancellationToken ct = default);
    Task AddAsync(Transaction transaction, CancellationToken ct = default);

    // ProviderStripeAccount
    Task<ProviderStripeAccount?> GetProviderStripeAccountAsync(Guid providerId, CancellationToken ct = default);
    Task AddProviderStripeAccountAsync(ProviderStripeAccount account, CancellationToken ct = default);

    Task SaveChangesAsync(CancellationToken ct = default);
}

public class PaymentsRepository : IPaymentsRepository
{
    private readonly AppDbContext _context;

    public PaymentsRepository(AppDbContext context) => _context = context;

    public async Task<Transaction?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _context.Set<Transaction>().FirstOrDefaultAsync(t => t.Id == id, ct);

    public async Task<Transaction?> GetByJobIdAsync(Guid jobId, CancellationToken ct = default) =>
        await _context.Set<Transaction>()
            .Where(t => t.JobId == jobId && t.Status != "Pending")
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(ct);

    public async Task<Transaction?> GetByJobIdPaidAsync(Guid jobId, CancellationToken ct = default) =>
        await _context.Set<Transaction>()
            .FirstOrDefaultAsync(t => t.JobId == jobId && t.Status == "Paid", ct);

    public async Task<Transaction?> GetByPaymentIntentIdAsync(string paymentIntentId, CancellationToken ct = default) =>
        await _context.Set<Transaction>()
            .FirstOrDefaultAsync(t => t.StripePaymentIntentId == paymentIntentId, ct);

    public async Task<IReadOnlyList<Transaction>> GetHeldReadyToReleaseAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        return await _context.Set<Transaction>()
            .Where(t => t.Status == "Held" && t.HoldUntil != null && t.HoldUntil <= now)
            .ToListAsync(ct);
    }

    public async Task<(IReadOnlyList<Transaction> Items, int Total)> GetByCustomerIdPagedAsync(
        Guid customerId, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Set<Transaction>()
            .Where(t => t.CustomerId == customerId && t.Status != "Pending")
            .OrderByDescending(t => t.CreatedAt);

        var total = await query.CountAsync(ct);
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        return (items, total);
    }

    public async Task<(IReadOnlyList<Transaction> Items, int Total)> GetByProviderIdPagedAsync(
        Guid providerId, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Set<Transaction>()
            .Where(t => t.ProviderId == providerId && t.Status != "Pending")
            .OrderByDescending(t => t.CreatedAt);

        var total = await query.CountAsync(ct);
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        return (items, total);
    }

    public async Task<IReadOnlyList<Transaction>> GetAllByProviderIdAsync(Guid providerId, CancellationToken ct = default) =>
        await _context.Set<Transaction>()
            .Where(t => t.ProviderId == providerId)
            .ToListAsync(ct);

    public async Task AddAsync(Transaction transaction, CancellationToken ct = default) =>
        await _context.Set<Transaction>().AddAsync(transaction, ct);

    public async Task<ProviderStripeAccount?> GetProviderStripeAccountAsync(Guid providerId, CancellationToken ct = default) =>
        await _context.Set<ProviderStripeAccount>()
            .FirstOrDefaultAsync(a => a.ProviderId == providerId, ct);

    public async Task AddProviderStripeAccountAsync(ProviderStripeAccount account, CancellationToken ct = default) =>
        await _context.Set<ProviderStripeAccount>().AddAsync(account, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
