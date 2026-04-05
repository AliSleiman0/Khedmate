using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

/// <summary>
/// Returns a job by ID for a specific provider (validates ownership).
/// Used by provider-only endpoints that need to verify job ownership for any status.
/// </summary>
public record GetJobByIdForProviderQuery(Guid JobId, Guid ProviderId)
    : IRequest<Result<ProviderJobStatusDto>>;

public record ProviderJobStatusDto(Guid JobId, JobStatus Status);

public class GetJobByIdForProviderQueryHandler
    : IRequestHandler<GetJobByIdForProviderQuery, Result<ProviderJobStatusDto>>
{
    private readonly IBookingsRepository _repo;

    public GetJobByIdForProviderQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<ProviderJobStatusDto>> Handle(
        GetJobByIdForProviderQuery request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        if (job is null)
            return Result<ProviderJobStatusDto>.Fail("JOB_NOT_FOUND");

        if (job.ProviderId != request.ProviderId)
            return Result<ProviderJobStatusDto>.Fail("FORBIDDEN");

        return Result<ProviderJobStatusDto>.Ok(new ProviderJobStatusDto(job.Id, job.Status));
    }
}
