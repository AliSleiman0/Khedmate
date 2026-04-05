namespace Khudmati.Modules.Bookings.Application.DTOs;

public record JobDetailForProviderDto(
    Guid JobId,
    string ReferenceNumber,
    string CategoryId,
    string CategoryName,
    string Description,
    double Latitude,
    double Longitude,
    string District,
    double DistanceKm,
    IReadOnlyList<string> BeforePhotoUrls,
    IReadOnlyList<string> AfterPhotoUrls,
    int SecondsRemaining,
    DateTime PostedAt,
    string Status,
    DateTime? PaidAt = null
);
