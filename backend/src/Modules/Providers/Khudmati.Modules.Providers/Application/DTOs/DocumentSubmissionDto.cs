using Khudmati.Modules.Providers.Domain.Enums;

namespace Khudmati.Modules.Providers.Application.DTOs;

public record DocumentSubmissionDto(
    Guid Id,
    Guid ProviderId,
    DocumentType DocumentType,
    string FrontImageUrl,
    string? BackImageUrl,
    DocumentStatus Status,
    string? RejectionReason,
    DateTime SubmittedAt,
    DateTime? ReviewedAt
);

public record DocumentSubmissionResultDto(
    Guid SubmissionId,
    string Status
);
