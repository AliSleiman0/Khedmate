using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Infrastructure.Persistence;

public interface ISkillTestRepository
{
    // Questions
    Task<IReadOnlyList<SkillTestQuestion>> GetActiveQuestionsByCategoryAsync(string categoryId, CancellationToken ct = default);
    Task<SkillTestQuestion?> GetQuestionByIdAsync(Guid questionId, CancellationToken ct = default);

    // Sessions
    Task<SkillTestSession?> GetSessionByIdAsync(Guid sessionId, CancellationToken ct = default);
    Task<SkillTestSession?> GetLatestSessionAsync(Guid providerId, string categoryId, CancellationToken ct = default);
    Task<SkillTestSession?> GetActiveSessionAsync(Guid providerId, string categoryId, CancellationToken ct = default);
    Task AddSessionAsync(SkillTestSession session, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class SkillTestRepository : ISkillTestRepository
{
    private readonly AppDbContext _context;

    public SkillTestRepository(AppDbContext context) => _context = context;

    // Questions
    public async Task<IReadOnlyList<SkillTestQuestion>> GetActiveQuestionsByCategoryAsync(
        string categoryId, CancellationToken ct = default) =>
        await _context.Set<SkillTestQuestion>()
            .Where(q => q.CategoryId == categoryId && q.IsActive)
            .ToListAsync(ct);

    public async Task<SkillTestQuestion?> GetQuestionByIdAsync(Guid questionId, CancellationToken ct = default) =>
        await _context.Set<SkillTestQuestion>().FirstOrDefaultAsync(q => q.Id == questionId, ct);

    // Sessions
    public async Task<SkillTestSession?> GetSessionByIdAsync(Guid sessionId, CancellationToken ct = default) =>
        await _context.Set<SkillTestSession>().FirstOrDefaultAsync(s => s.Id == sessionId, ct);

    public async Task<SkillTestSession?> GetLatestSessionAsync(
        Guid providerId, string categoryId, CancellationToken ct = default) =>
        await _context.Set<SkillTestSession>()
            .Where(s => s.ProviderId == providerId && s.CategoryId == categoryId)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(ct);

    public async Task<SkillTestSession?> GetActiveSessionAsync(
        Guid providerId, string categoryId, CancellationToken ct = default) =>
        await _context.Set<SkillTestSession>()
            .Where(s => s.ProviderId == providerId && 
                        s.CategoryId == categoryId && 
                        s.Status == SkillTestStatus.InProgress &&
                        s.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(s => s.StartedAt)
            .FirstOrDefaultAsync(ct);

    public async Task AddSessionAsync(SkillTestSession session, CancellationToken ct = default) =>
        await _context.Set<SkillTestSession>().AddAsync(session, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
