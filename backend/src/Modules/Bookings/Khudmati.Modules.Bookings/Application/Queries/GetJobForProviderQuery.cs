using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetJobForProviderQuery(
    Guid JobId,
    double ProviderLatitude,
    double ProviderLongitude
) : IRequest<Result<JobDetailForProviderDto>>;

public class GetJobForProviderQueryHandler : IRequestHandler<GetJobForProviderQuery, Result<JobDetailForProviderDto>>
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

    public GetJobForProviderQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<JobDetailForProviderDto>> Handle(
        GetJobForProviderQuery request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        if (job is null || (job.Status != JobStatus.Pending && job.Status != JobStatus.Accepted))
            return Result<JobDetailForProviderDto>.Fail("JOB_NO_LONGER_AVAILABLE");

        if (job.Status == JobStatus.Pending && job.ExpiresAt <= DateTime.UtcNow)
            return Result<JobDetailForProviderDto>.Fail("JOB_NO_LONGER_AVAILABLE");

        var distance = Haversine(
            request.ProviderLatitude, request.ProviderLongitude,
            (double)job.Latitude, (double)job.Longitude);

        var secondsRemaining = job.Status == JobStatus.Pending
            ? Math.Max(0, (int)(job.ExpiresAt - DateTime.UtcNow).TotalSeconds)
            : 0;

        var dto = new JobDetailForProviderDto(
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
            secondsRemaining,
            job.CreatedAt,
            job.Status.ToString()
        );

        return Result<JobDetailForProviderDto>.Ok(dto);
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
