namespace Khudmati.Modules.Bookings.Application.DTOs;

public record AdminDisputeSummaryDto(
    Guid DisputeId,
    Guid JobId,
    string ReferenceNumber,
    Guid CustomerId,
    string CustomerName,
    Guid ProviderId,
    string ProviderName,
    decimal Amount,
    string Status,
    DateTime CreatedAt
);

public record AdminDisputeStatusHistoryDto(
    string PreviousStatus,
    string NewStatus,
    DateTime ChangedAt,
    Guid ChangedBy
);

public record AdminDisputeDetailDto(
    Guid DisputeId,
    Guid JobId,
    string ReferenceNumber,
    Guid CustomerId,
    string CustomerName,
    Guid ProviderId,
    string ProviderName,
    string CategoryId,
    string Address,
    decimal Amount,
    string Status,
    string Complaint,
    string? AdminNote,
    DateTime? ResolvedAt,
    Guid? ResolvedByAdminId,
    DateTime CreatedAt,
    DateTime JobCreatedAt,
    DateTime? JobCompletedAt,
    IReadOnlyList<string> Photos,
    IReadOnlyList<AdminDisputeStatusHistoryDto> StatusHistory
);

public record AdminDisputeListResultDto(
    IReadOnlyList<AdminDisputeSummaryDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int OpenCount,
    int ResolvedCount,
    int RejectedCount
);

public record OpenDisputeResultDto(Guid DisputeId);
public record ResolveDisputeResultDto(Guid DisputeId, string NewStatus);
