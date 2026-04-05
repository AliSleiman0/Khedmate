namespace Khudmati.Modules.Bookings.Application.DTOs;

public record CreateJobRequest(
    string CategoryId,
    string Description,
    double Latitude,
    double Longitude,
    string Address,
    IReadOnlyList<string>? PhotoUrls
);

public record RaiseDisputeRequest(string Complaint);
