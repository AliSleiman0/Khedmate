using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetJobStatusQuery(Guid JobId, Guid RequestingUserId, string Audience)
    : IRequest<Result<JobStatusDto>>;

public record JobStatusDto(
    Guid JobId,
    string Status,
    string ReferenceNumber,
    string Category,
    string ProviderName,
    double CustomerLatitude,
    double CustomerLongitude,
    DateTime UpdatedAt,
    Guid? ProviderId);

public class GetJobStatusQueryHandler : IRequestHandler<GetJobStatusQuery, Result<JobStatusDto>>
{
    private static readonly Dictionary<string, string> CategoryNames = new()
    {
        ["plumbing"]    = "سباكة",
        ["electrical"]  = "كهرباء",
        ["cleaning"]    = "تنظيف",
        ["carpentry"]   = "نجارة",
        ["painting"]    = "دهان",
        ["ac_maintenance"] = "تكييف"
    };

    private readonly IBookingsRepository _repo;

    public GetJobStatusQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<JobStatusDto>> Handle(
        GetJobStatusQuery request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        if (job is null)
            return Result<JobStatusDto>.Fail("JOB_NOT_FOUND");

        // Only the customer or the assigned provider may view
        var isCustomer = request.Audience == "customer" && job.CustomerId == request.RequestingUserId;
        var isProvider = request.Audience == "provider" && job.ProviderId == request.RequestingUserId;

        if (!isCustomer && !isProvider)
            return Result<JobStatusDto>.Fail("JOB_NOT_FOUND");

        var categoryName = CategoryNames.GetValueOrDefault(job.CategoryId, job.CategoryId);

        return Result<JobStatusDto>.Ok(new JobStatusDto(
            job.Id,
            job.Status.ToString(),
            job.ReferenceNumber,
            categoryName,
            string.Empty, // provider name resolved at API layer
            (double)job.Latitude,
            (double)job.Longitude,
            job.UpdatedAt ?? job.CreatedAt,
            job.ProviderId));
    }
}
