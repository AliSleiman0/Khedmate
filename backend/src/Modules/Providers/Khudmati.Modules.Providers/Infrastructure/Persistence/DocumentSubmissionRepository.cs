using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Infrastructure.Persistence;

public interface IDocumentSubmissionRepository
{
    Task<DocumentSubmission?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<DocumentSubmission?> GetPendingByProviderIdAsync(Guid providerId, CancellationToken ct = default);
    Task<IReadOnlyList<DocumentSubmission>> GetPendingSubmissionsAsync(int page, int pageSize, CancellationToken ct = default);
    Task AddAsync(DocumentSubmission submission, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class DocumentSubmissionRepository : IDocumentSubmissionRepository
{
    private readonly AppDbContext _context;

    public DocumentSubmissionRepository(AppDbContext context) => _context = context;

    public async Task<DocumentSubmission?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _context.Set<DocumentSubmission>().FirstOrDefaultAsync(d => d.Id == id, ct);

    public async Task<DocumentSubmission?> GetPendingByProviderIdAsync(Guid providerId, CancellationToken ct = default) =>
        await _context.Set<DocumentSubmission>()
            .Where(d => d.ProviderId == providerId && d.Status == DocumentStatus.PendingReview)
            .OrderByDescending(d => d.SubmittedAt)
            .FirstOrDefaultAsync(ct);

    public async Task<IReadOnlyList<DocumentSubmission>> GetPendingSubmissionsAsync(
        int page, int pageSize, CancellationToken ct = default) =>
        await _context.Set<DocumentSubmission>()
            .Where(d => d.Status == DocumentStatus.PendingReview)
            .OrderBy(d => d.SubmittedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

    public async Task AddAsync(DocumentSubmission submission, CancellationToken ct = default) =>
        await _context.Set<DocumentSubmission>().AddAsync(submission, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
