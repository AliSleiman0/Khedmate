using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetActiveJobsByProviderQuery(
    Guid ProviderId,
    double ProviderLatitude,
    double ProviderLongitude
) : IRequest<Result<IReadOnlyList<JobDetailForProviderDto>>>;

public class GetActiveJobsByProviderQueryHandler
    : IRequestHandler<GetActiveJobsByProviderQuery, Result<IReadOnlyList<JobDetailForProviderDto>>>
{
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

    public GetActiveJobsByProviderQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<IReadOnlyList<JobDetailForProviderDto>>> Handle(
        GetActiveJobsByProviderQuery request, CancellationToken cancellationToken)
    {
        var jobs = await _repo.GetAcceptedJobsByProviderAsync(request.ProviderId, cancellationToken);

        var dtos = jobs.Select(job =>
        {
            var distance = Haversine(
                request.ProviderLatitude, request.ProviderLongitude,
                (double)job.Latitude, (double)job.Longitude);

            return new JobDetailForProviderDto(
                job.Id,
                job.ReferenceNumber,
                job.CategoryId,
                CategoryNames.GetValueOrDefault(job.CategoryId, job.CategoryId),
                job.Description,
                (double)job.Latitude,
                (double)job.Longitude,
                job.Address.Split('،', ',')[0].Trim(),
                Math.Round(distance, 1),
                job.Photos.Where(p => p.PhotoType == "before").Select(p => p.Url).ToList(),
                job.Photos.Where(p => p.PhotoType == "after").Select(p => p.Url).ToList(),
                0,
                job.CreatedAt,
                job.Status.ToString(),
                job.PaidAt
            );
        }).ToList();

        return Result<IReadOnlyList<JobDetailForProviderDto>>.Ok(dtos);
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
