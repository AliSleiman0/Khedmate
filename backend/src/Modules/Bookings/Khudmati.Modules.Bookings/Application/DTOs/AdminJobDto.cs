using Khudmati.Modules.Bookings.Domain.Enums;

namespace Khudmati.Modules.Bookings.Application.DTOs;

public record AdminJobSummaryDto(
    Guid JobId,
    string ReferenceNumber,
    Guid CustomerId,
    string CustomerName,
    Guid? ProviderId,
    string? ProviderName,
    string CategoryId,
    JobStatus Status,
    DateTime CreatedAt,
    DateTime? AcceptedAt,
    DateTime? PaidAt,
    decimal? Amount
);

public record AdminJobStatusHistoryDto(
    string PreviousStatus,
    string NewStatus,
    DateTime ChangedAt,
    Guid ChangedBy
);

public record AdminJobRatingDto(
    bool IsPositive,
    string[] Tags,
    DateTime SubmittedAt,
    string RaterType
);

public record AdminJobDetailDto(
    Guid JobId,
    string ReferenceNumber,
    Guid CustomerId,
    string CustomerName,
    Guid? ProviderId,
    string? ProviderName,
    string CategoryId,
    string Description,
    decimal Latitude,
    decimal Longitude,
    string Address,
    JobStatus Status,
    DateTime CreatedAt,
    DateTime? AcceptedAt,
    DateTime? PaidAt,
    decimal? Amount,
    IReadOnlyList<string> PhotoUrls,
    IReadOnlyList<AdminJobStatusHistoryDto> StatusHistory,
    AdminJobRatingDto? Rating
);

public record AdminJobStatsDto(
    int Total,
    int Pending,
    int Active,
    int CompletedOrPaid
);

public record AdminJobListResultDto(
    IReadOnlyList<AdminJobSummaryDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    AdminJobStatsDto Stats
);
