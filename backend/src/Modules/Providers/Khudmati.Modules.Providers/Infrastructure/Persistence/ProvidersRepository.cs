using Khudmati.Modules.Providers.Domain.Entities;

namespace Khudmati.Modules.Providers.Infrastructure.Persistence;

public interface IProvidersRepository
{
    Task<Provider?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Provider?> GetByPhoneAsync(string phone, CancellationToken ct = default);
    Task<Provider?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task<IEnumerable<Provider>> GetOnlineProvidersAsync(CancellationToken ct = default);
    Task AddAsync(Provider provider, CancellationToken ct = default);
    Task UpdateAsync(Provider provider, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);

    // OTP
    Task<ProviderOtpVerification?> GetLatestOtpAsync(Guid accountId, CancellationToken ct = default);
    Task AddOtpAsync(ProviderOtpVerification otp, CancellationToken ct = default);
    Task RemoveOtpAsync(ProviderOtpVerification otp, CancellationToken ct = default);
    Task UpdateOtpAsync(ProviderOtpVerification otp, CancellationToken ct = default);

    // Refresh tokens
    Task<ProviderRefreshToken?> GetRefreshTokenByIdAsync(Guid id, CancellationToken ct = default);
    Task<ProviderRefreshToken?> GetRefreshTokenByAccountIdAsync(Guid accountId, CancellationToken ct = default);
    Task AddRefreshTokenAsync(ProviderRefreshToken token, CancellationToken ct = default);
    Task RemoveRefreshTokenAsync(ProviderRefreshToken token, CancellationToken ct = default);

    // Rate limiting
    Task<int> CountRecentOtpResendAttemptsAsync(string phone, DateTime since, CancellationToken ct = default);
}

public class ProvidersRepository : IProvidersRepository
{
    public Task<Provider?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        Task.FromResult<Provider?>(null);

    public Task<Provider?> GetByPhoneAsync(string phone, CancellationToken ct = default) =>
        Task.FromResult<Provider?>(null);

    public Task<Provider?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        Task.FromResult<Provider?>(null);

    public Task<IEnumerable<Provider>> GetOnlineProvidersAsync(CancellationToken ct = default) =>
        Task.FromResult(Enumerable.Empty<Provider>());

    public Task AddAsync(Provider provider, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task UpdateAsync(Provider provider, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task SaveChangesAsync(CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task<ProviderOtpVerification?> GetLatestOtpAsync(Guid accountId, CancellationToken ct = default) =>
        Task.FromResult<ProviderOtpVerification?>(null);

    public Task AddOtpAsync(ProviderOtpVerification otp, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task RemoveOtpAsync(ProviderOtpVerification otp, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task UpdateOtpAsync(ProviderOtpVerification otp, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task<ProviderRefreshToken?> GetRefreshTokenByIdAsync(Guid id, CancellationToken ct = default) =>
        Task.FromResult<ProviderRefreshToken?>(null);

    public Task<ProviderRefreshToken?> GetRefreshTokenByAccountIdAsync(Guid accountId, CancellationToken ct = default) =>
        Task.FromResult<ProviderRefreshToken?>(null);

    public Task AddRefreshTokenAsync(ProviderRefreshToken token, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task RemoveRefreshTokenAsync(ProviderRefreshToken token, CancellationToken ct = default) =>
        Task.CompletedTask;

    public Task<int> CountRecentOtpResendAttemptsAsync(string phone, DateTime since, CancellationToken ct = default) =>
        Task.FromResult(0);
}
