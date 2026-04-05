using Khudmati.Modules.Providers.Domain.Enums;

namespace Khudmati.Modules.Providers.Application.DTOs;

public record ProviderDto(
    Guid Id,
    string FullName,
    string Phone,
    VerificationTier Tier,
    double Rating,
    int JobsCompleted,
    bool IsOnline,
    DateTime CreatedAt
);
