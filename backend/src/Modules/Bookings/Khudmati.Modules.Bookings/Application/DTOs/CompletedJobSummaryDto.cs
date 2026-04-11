namespace Khudmati.Modules.Bookings.Application.DTOs;

public record CompletedJobSummaryDto(
    Guid JobId,
    string ReferenceNumber,
    string CategoryId,
    string CategoryName,
    string District,
    double NetAmount,
    DateTime CompletedAt
);
