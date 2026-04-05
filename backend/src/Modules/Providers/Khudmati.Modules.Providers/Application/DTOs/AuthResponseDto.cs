namespace Khudmati.Modules.Providers.Application.DTOs;

public record ProviderAuthResponse(string AccessToken, string RefreshToken, ProviderAuthDto Provider);

public record ProviderAuthDto(Guid Id, string FullName, string Phone);
