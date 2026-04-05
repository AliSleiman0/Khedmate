using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetAvailableJobsQuery(
    double ProviderLatitude,
    double ProviderLongitude,
    int Page,
    int PageSize
) : IRequest<Result<AvailableJobsResultDto>>;

public record AvailableJobsResultDto(IReadOnlyList<AvailableJobSummaryDto> Items, int TotalCount);

public class GetAvailableJobsQueryHandler : IRequestHandler<GetAvailableJobsQuery, Result<AvailableJobsResultDto>>
{
    private const double RadiusKm = 10.0;

    private static readonly Dictionary<string, string> CategoryNames = new()
    {
        ["plumbing"] = "سباكة",
        ["electrical"] = "كهرباء",
        ["cleaning"] = "تنظيف",
        ["carpentry"] = "نجارة",
        ["painting"] = "دهان",
        ["ac_maintenance"] = "تكييف"
    };

    private readonly IBookingsRepository _repo;

    public GetAvailableJobsQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<AvailableJobsResultDto>> Handle(
        GetAvailableJobsQuery request, CancellationToken cancellationToken)
    {
        var allPending = await _repo.GetPendingNonExpiredJobsAsync(cancellationToken);

        // Filter by radius using Haversine, compute distance
        var jobsInRadius = allPending
            .Select(j => new
            {
                Job = j,
                DistanceKm = Haversine(
                    request.ProviderLatitude, request.ProviderLongitude,
                    (double)j.Latitude, (double)j.Longitude)
            })
            .Where(x => x.DistanceKm <= RadiusKm)
            .OrderByDescending(x => x.Job.CreatedAt)
            .ToList();

        var total = jobsInRadius.Count;
        var paged = jobsInRadius
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(x => new AvailableJobSummaryDto(
                x.Job.Id,
                x.Job.ReferenceNumber,
                x.Job.CategoryId,
                CategoryNames.GetValueOrDefault(x.Job.CategoryId, x.Job.CategoryId),
                Math.Round(x.DistanceKm, 1),
                ExtractDistrict(x.Job.Address),
                Math.Max(0, (int)(x.Job.ExpiresAt - DateTime.UtcNow).TotalSeconds),
                x.Job.CreatedAt,
                x.Job.Photos.Count > 0
            ))
            .ToList();

        return Result<AvailableJobsResultDto>.Ok(new AvailableJobsResultDto(paged, total));
    }

    private static string ExtractDistrict(string address)
    {
        // Return first comma-separated segment as district
        var parts = address.Split('،', ',');
        return parts[0].Trim();
    }

    private static double Haversine(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371;
        var dLat = ToRad(lat2 - lat1);
        var dLon = ToRad(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
              + Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2))
              * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static double ToRad(double deg) => deg * Math.PI / 180;
}
