using Khudmati.Modules.Providers.Domain.Enums;

namespace Khudmati.Modules.Providers.Application.DTOs;

public record ProviderAdminDto(
    Guid Id,
    string FullName,
    string Phone,
    string? Email,
    VerificationTier Tier,
    string[] ServiceCategories,
    double Rating,
    int JobsCompleted,
    DateTime CreatedAt
);

public record ProviderVerificationQueueDto(
    Guid ProviderId,
    string FullName,
    string Phone,
    DocumentType DocumentType,
    DateTime SubmittedAt,
    Guid SubmissionId
);
