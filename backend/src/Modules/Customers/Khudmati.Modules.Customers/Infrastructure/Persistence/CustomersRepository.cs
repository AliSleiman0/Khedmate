using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Customers.Infrastructure.Persistence;

public interface ICustomersRepository
{
    Task<Customer?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Customer?> GetByPhoneAsync(string phone, CancellationToken ct = default);
    Task<Customer?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task AddAsync(Customer customer, CancellationToken ct = default);
    Task UpdateAsync(Customer customer, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);

    // OTP
    Task<OtpVerification?> GetLatestOtpAsync(Guid accountId, CancellationToken ct = default);
    Task AddOtpAsync(OtpVerification otp, CancellationToken ct = default);
    Task RemoveOtpAsync(OtpVerification otp, CancellationToken ct = default);
    Task UpdateOtpAsync(OtpVerification otp, CancellationToken ct = default);

    // Refresh tokens
    Task<CustomerRefreshToken?> GetRefreshTokenByIdAsync(Guid id, CancellationToken ct = default);
    Task<CustomerRefreshToken?> GetRefreshTokenByAccountIdAsync(Guid accountId, CancellationToken ct = default);
    Task AddRefreshTokenAsync(CustomerRefreshToken token, CancellationToken ct = default);
    Task RemoveRefreshTokenAsync(CustomerRefreshToken token, CancellationToken ct = default);

    // Rate limiting
    Task<int> CountRecentOtpResendAttemptsAsync(string phone, DateTime since, CancellationToken ct = default);

    // Referral codes
    Task<ReferralCode?> GetReferralCodeByCustomerIdAsync(Guid customerId, CancellationToken ct = default);
    Task<ReferralCode?> GetReferralCodeByCodeAsync(string code, CancellationToken ct = default);
    Task AddReferralCodeAsync(ReferralCode code, CancellationToken ct = default);

    // Referral uses
    Task<ReferralUse?> GetPendingReferralUseByReferredCustomerAsync(Guid referredCustomerId, CancellationToken ct = default);
    Task<bool> HasReferralUseAsReferreeAsync(Guid referredCustomerId, CancellationToken ct = default);
    Task AddReferralUseAsync(ReferralUse use, CancellationToken ct = default);
    Task UpdateReferralUseAsync(ReferralUse use, CancellationToken ct = default);
    Task<int> CountCompletedReferralsByReferrerAsync(Guid referrerCustomerId, CancellationToken ct = default);

    // Customer credits
    Task<IReadOnlyList<CustomerCredit>> GetActiveCreditsAsync(Guid customerId, CancellationToken ct = default);
    Task<decimal> GetTotalActiveCreditBalanceAsync(Guid customerId, CancellationToken ct = default);
    Task AddCreditAsync(CustomerCredit credit, CancellationToken ct = default);
    Task UpdateCreditAsync(CustomerCredit credit, CancellationToken ct = default);
}

public class CustomersRepository : ICustomersRepository
{
    private readonly AppDbContext _context;

    public CustomersRepository(AppDbContext context) => _context = context;

    // ── Customers ─────────────────────────────────────────────────────────────

    public async Task<Customer?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _context.Set<Customer>().FirstOrDefaultAsync(c => c.Id == id, ct);

    public async Task<Customer?> GetByPhoneAsync(string phone, CancellationToken ct = default) =>
        await _context.Set<Customer>().FirstOrDefaultAsync(c => c.Phone == phone, ct);

    public async Task<Customer?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        await _context.Set<Customer>().FirstOrDefaultAsync(c => c.Email == email, ct);

    public async Task AddAsync(Customer customer, CancellationToken ct = default) =>
        await _context.Set<Customer>().AddAsync(customer, ct);

    public Task UpdateAsync(Customer customer, CancellationToken ct = default)
    {
        _context.Set<Customer>().Update(customer);
        return Task.CompletedTask;
    }

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);

    // ── OTP ───────────────────────────────────────────────────────────────────

    public async Task<OtpVerification?> GetLatestOtpAsync(Guid accountId, CancellationToken ct = default) =>
        await _context.Set<OtpVerification>()
            .Where(o => o.AccountId == accountId)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync(ct);

    public async Task AddOtpAsync(OtpVerification otp, CancellationToken ct = default) =>
        await _context.Set<OtpVerification>().AddAsync(otp, ct);

    public Task RemoveOtpAsync(OtpVerification otp, CancellationToken ct = default)
    {
        _context.Set<OtpVerification>().Remove(otp);
        return Task.CompletedTask;
    }

    public Task UpdateOtpAsync(OtpVerification otp, CancellationToken ct = default)
    {
        _context.Set<OtpVerification>().Update(otp);
        return Task.CompletedTask;
    }

    // ── Refresh tokens ────────────────────────────────────────────────────────

    public async Task<CustomerRefreshToken?> GetRefreshTokenByIdAsync(Guid id, CancellationToken ct = default) =>
        await _context.Set<CustomerRefreshToken>().FirstOrDefaultAsync(t => t.Id == id, ct);

    public async Task<CustomerRefreshToken?> GetRefreshTokenByAccountIdAsync(Guid accountId, CancellationToken ct = default) =>
        await _context.Set<CustomerRefreshToken>()
            .FirstOrDefaultAsync(t => t.AccountId == accountId, ct);

    public async Task AddRefreshTokenAsync(CustomerRefreshToken token, CancellationToken ct = default) =>
        await _context.Set<CustomerRefreshToken>().AddAsync(token, ct);

    public Task RemoveRefreshTokenAsync(CustomerRefreshToken token, CancellationToken ct = default)
    {
        _context.Set<CustomerRefreshToken>().Remove(token);
        return Task.CompletedTask;
    }

    // ── Rate limiting ─────────────────────────────────────────────────────────

    public async Task<int> CountRecentOtpResendAttemptsAsync(string phone, DateTime since, CancellationToken ct = default)
    {
        // Count OTP records created for this phone number since the given timestamp.
        // Joins through OtpVerification → Customer to match by phone.
        return await (
            from otp in _context.Set<OtpVerification>()
            join customer in _context.Set<Customer>() on otp.AccountId equals customer.Id
            where customer.Phone == phone && otp.CreatedAt >= since
            select otp.Id
        ).CountAsync(ct);
    }

    // ── Referral codes ────────────────────────────────────────────────────────

    public async Task<ReferralCode?> GetReferralCodeByCustomerIdAsync(Guid customerId, CancellationToken ct = default) =>
        await _context.Set<ReferralCode>()
            .FirstOrDefaultAsync(r => r.CustomerId == customerId, ct);

    public async Task<ReferralCode?> GetReferralCodeByCodeAsync(string code, CancellationToken ct = default) =>
        await _context.Set<ReferralCode>()
            .FirstOrDefaultAsync(r => r.Code == code, ct);

    public async Task AddReferralCodeAsync(ReferralCode code, CancellationToken ct = default) =>
        await _context.Set<ReferralCode>().AddAsync(code, ct);

    // ── Referral uses ─────────────────────────────────────────────────────────

    public async Task<ReferralUse?> GetPendingReferralUseByReferredCustomerAsync(
        Guid referredCustomerId, CancellationToken ct = default) =>
        await _context.Set<ReferralUse>()
            .FirstOrDefaultAsync(
                r => r.ReferredCustomerId == referredCustomerId && r.Status == "Pending", ct);

    public async Task<bool> HasReferralUseAsReferreeAsync(
        Guid referredCustomerId, CancellationToken ct = default) =>
        await _context.Set<ReferralUse>()
            .AnyAsync(r => r.ReferredCustomerId == referredCustomerId, ct);

    public async Task AddReferralUseAsync(ReferralUse use, CancellationToken ct = default) =>
        await _context.Set<ReferralUse>().AddAsync(use, ct);

    public Task UpdateReferralUseAsync(ReferralUse use, CancellationToken ct = default)
    {
        _context.Set<ReferralUse>().Update(use);
        return Task.CompletedTask;
    }

    public async Task<int> CountCompletedReferralsByReferrerAsync(
        Guid referrerCustomerId, CancellationToken ct = default) =>
        await _context.Set<ReferralUse>()
            .CountAsync(r => r.ReferrerCustomerId == referrerCustomerId && r.Status == "Completed", ct);

    // ── Customer credits ──────────────────────────────────────────────────────

    public async Task<IReadOnlyList<CustomerCredit>> GetActiveCreditsAsync(
        Guid customerId, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        return await _context.Set<CustomerCredit>()
            .Where(c => c.CustomerId == customerId
                        && c.ExpiresAt > now
                        && c.UsedAt == null)
            .OrderBy(c => c.ExpiresAt)
            .ToListAsync(ct);
    }

    public async Task<decimal> GetTotalActiveCreditBalanceAsync(
        Guid customerId, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        return await _context.Set<CustomerCredit>()
            .Where(c => c.CustomerId == customerId
                        && c.ExpiresAt > now
                        && c.UsedAt == null)
            .SumAsync(c => c.Amount, ct);
    }

    public async Task AddCreditAsync(CustomerCredit credit, CancellationToken ct = default) =>
        await _context.Set<CustomerCredit>().AddAsync(credit, ct);

    public Task UpdateCreditAsync(CustomerCredit credit, CancellationToken ct = default)
    {
        _context.Set<CustomerCredit>().Update(credit);
        return Task.CompletedTask;
    }
}
