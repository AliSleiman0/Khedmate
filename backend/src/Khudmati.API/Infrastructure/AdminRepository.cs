using Khudmati.API.Domain;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Infrastructure;

public interface IAdminRepository
{
    Task<AdminAccount?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task<AdminAccount?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task AddAsync(AdminAccount admin, CancellationToken ct = default);
    Task<bool> AnyAdminExistsAsync(CancellationToken ct = default);

    Task<AdminRefreshToken?> GetRefreshTokenByIdAsync(Guid id, CancellationToken ct = default);
    Task<AdminRefreshToken?> GetRefreshTokenByAccountIdAsync(Guid accountId, CancellationToken ct = default);
    Task AddRefreshTokenAsync(AdminRefreshToken token, CancellationToken ct = default);
    Task RemoveRefreshTokenAsync(AdminRefreshToken token, CancellationToken ct = default);

    Task SaveChangesAsync(CancellationToken ct = default);
}

public class AdminRepository : IAdminRepository
{
    private readonly AppDbContext _db;

    public AdminRepository(AppDbContext db)
    {
        _db = db;
    }

    public Task<AdminAccount?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        _db.Set<AdminAccount>().FirstOrDefaultAsync(a => a.Email == email, ct);

    public Task<AdminAccount?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _db.Set<AdminAccount>().FirstOrDefaultAsync(a => a.Id == id, ct);

    public async Task AddAsync(AdminAccount admin, CancellationToken ct = default) =>
        await _db.Set<AdminAccount>().AddAsync(admin, ct);

    public Task<bool> AnyAdminExistsAsync(CancellationToken ct = default) =>
        _db.Set<AdminAccount>().AnyAsync(ct);

    public Task<AdminRefreshToken?> GetRefreshTokenByIdAsync(Guid id, CancellationToken ct = default) =>
        _db.Set<AdminRefreshToken>().FirstOrDefaultAsync(t => t.Id == id, ct);

    public Task<AdminRefreshToken?> GetRefreshTokenByAccountIdAsync(Guid accountId, CancellationToken ct = default) =>
        _db.Set<AdminRefreshToken>().FirstOrDefaultAsync(t => t.AccountId == accountId, ct);

    public async Task AddRefreshTokenAsync(AdminRefreshToken token, CancellationToken ct = default) =>
        await _db.Set<AdminRefreshToken>().AddAsync(token, ct);

    public Task RemoveRefreshTokenAsync(AdminRefreshToken token, CancellationToken ct = default)
    {
        _db.Set<AdminRefreshToken>().Remove(token);
        return Task.CompletedTask;
    }

    public Task SaveChangesAsync(CancellationToken ct = default) =>
        _db.SaveChangesAsync(ct);
}
