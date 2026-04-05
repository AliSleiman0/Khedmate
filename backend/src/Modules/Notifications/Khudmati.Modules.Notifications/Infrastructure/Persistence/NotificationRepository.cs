using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Notifications.Infrastructure.Persistence;

public interface INotificationRepository
{
    Task AddAsync(Notification notification, CancellationToken ct = default);
    Task<(IReadOnlyList<Notification> Items, int TotalCount)> GetByRecipientAsync(
        Guid recipientId, string recipientType, int page, int pageSize, CancellationToken ct = default);
    Task<Notification?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class NotificationRepository : INotificationRepository
{
    private readonly AppDbContext _context;

    public NotificationRepository(AppDbContext context) => _context = context;

    public async Task AddAsync(Notification notification, CancellationToken ct = default)
    {
        await _context.Set<Notification>().AddAsync(notification, ct);
    }

    public async Task<(IReadOnlyList<Notification> Items, int TotalCount)> GetByRecipientAsync(
        Guid recipientId, string recipientType, int page, int pageSize, CancellationToken ct = default)
    {
        const int maxNotifications = 100;
        var capped = Math.Min(pageSize, 50);

        var query = _context.Set<Notification>()
            .Where(n => n.RecipientId == recipientId && n.RecipientType == recipientType)
            .OrderByDescending(n => n.CreatedAt)
            .Take(maxNotifications);

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .Skip((page - 1) * capped)
            .Take(capped)
            .ToListAsync(ct);

        return (items, totalCount);
    }

    public Task<Notification?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Set<Notification>().FirstOrDefaultAsync(n => n.Id == id, ct);

    public Task SaveChangesAsync(CancellationToken ct = default) =>
        _context.SaveChangesAsync(ct);
}
