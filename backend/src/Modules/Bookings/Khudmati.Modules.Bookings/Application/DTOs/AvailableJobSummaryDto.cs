namespace Khudmati.Modules.Bookings.Application.DTOs;

public record AvailableJobSummaryDto(
    Guid JobId,
    string ReferenceNumber,
    string CategoryId,
    string CategoryName,
    double DistanceKm,
    string District,
    int SecondsRemaining,
    DateTime PostedAt,
    bool HasPhotos
);
