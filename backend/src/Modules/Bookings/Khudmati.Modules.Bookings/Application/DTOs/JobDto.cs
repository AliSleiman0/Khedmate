using Khudmati.Modules.Bookings.Domain.Enums;

namespace Khudmati.Modules.Bookings.Application.DTOs;

public record JobDto(
    Guid JobId,
    string ReferenceNumber,
    Guid CustomerId,
    Guid? ProviderId,
    string CategoryId,
    string Description,
    decimal Latitude,
    decimal Longitude,
    string Address,
    JobStatus Status,
    IReadOnlyList<string> BeforePhotoUrls,
    IReadOnlyList<string> AfterPhotoUrls,
    DateTime CreatedAt,
    bool HasOpenDispute,
    string? TransactionStatus
);
