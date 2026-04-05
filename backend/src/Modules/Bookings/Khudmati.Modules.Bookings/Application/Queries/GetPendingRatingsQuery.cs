using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetPendingRatingsQuery(
    Guid UserId,
    string RaterType   // "customer" or "provider"
) : IRequest<Result<PendingRatingsResultDto>>;

public class GetPendingRatingsQueryHandler
    : IRequestHandler<GetPendingRatingsQuery, Result<PendingRatingsResultDto>>
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

    private readonly IRatingRepository _ratingRepo;

    public GetPendingRatingsQueryHandler(IRatingRepository ratingRepo) => _ratingRepo = ratingRepo;

    public async Task<Result<PendingRatingsResultDto>> Handle(
        GetPendingRatingsQuery request, CancellationToken cancellationToken)
    {
        var jobs = await _ratingRepo.GetPendingRatingJobsAsync(
            request.UserId, request.RaterType, cancellationToken);

        var dtos = jobs.Select(job =>
        {
            var paidAt = job.PaidAt!.Value;
            var expiresAt = paidAt.AddHours(48);

            var rateTarget = request.RaterType == "customer"
                ? "المزود"   // provider name placeholder — client can enrich
                : "العميل";  // customer name placeholder

            return new PendingRatingDto(
                job.Id,
                job.ReferenceNumber,
                CategoryNames.GetValueOrDefault(job.CategoryId, job.CategoryId),
                paidAt,
                expiresAt,
                rateTarget);
        }).ToList();

        return Result<PendingRatingsResultDto>.Ok(new PendingRatingsResultDto(dtos));
    }
}
