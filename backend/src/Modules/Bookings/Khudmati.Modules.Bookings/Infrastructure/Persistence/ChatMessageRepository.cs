using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Bookings.Infrastructure.Persistence;

public interface IChatMessageRepository
{
    Task<(IReadOnlyList<ChatMessage> Messages, int TotalCount)> GetByJobIdAsync(
        Guid jobId, int page, int pageSize, CancellationToken ct = default);
    Task AddAsync(ChatMessage message, CancellationToken ct = default);
    Task MarkAsReadAsync(Guid jobId, string readerType, CancellationToken ct = default);
    Task<int> GetUnreadCountAsync(Guid jobId, string readerType, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class ChatMessageRepository : IChatMessageRepository
{
    private readonly AppDbContext _context;

    public ChatMessageRepository(AppDbContext context) => _context = context;

    public async Task<(IReadOnlyList<ChatMessage> Messages, int TotalCount)> GetByJobIdAsync(
        Guid jobId, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Set<ChatMessage>()
            .Where(m => m.JobId == jobId)
            .OrderBy(m => m.SentAt);

        var total = await query.CountAsync(ct);
        var messages = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (messages, total);
    }

    public async Task AddAsync(ChatMessage message, CancellationToken ct = default) =>
        await _context.Set<ChatMessage>().AddAsync(message, ct);

    public async Task MarkAsReadAsync(Guid jobId, string readerType, CancellationToken ct = default)
    {
        // Mark messages sent by the OTHER party as read (readerType reads messages from opposite sender)
        var otherSenderType = readerType == "customer" ? "provider" : "customer";

        var unread = await _context.Set<ChatMessage>()
            .Where(m => m.JobId == jobId
                        && m.SenderType == otherSenderType
                        && m.ReadAt == null)
            .ToListAsync(ct);

        var now = DateTime.UtcNow;
        foreach (var msg in unread)
            msg.MarkRead();
    }

    public async Task<int> GetUnreadCountAsync(Guid jobId, string readerType, CancellationToken ct = default)
    {
        // Count messages sent by the other party that have not been read yet
        var otherSenderType = readerType == "customer" ? "provider" : "customer";

        return await _context.Set<ChatMessage>()
            .CountAsync(m => m.JobId == jobId
                             && m.SenderType == otherSenderType
                             && m.ReadAt == null, ct);
    }

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
