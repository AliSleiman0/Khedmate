using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetCustomerJobsQuery(
    Guid CustomerId,
    JobStatus? Status,
    int Page,
    int PageSize
) : IRequest<Result<JobListDto>>;

public class GetCustomerJobsQueryHandler : IRequestHandler<GetCustomerJobsQuery, Result<JobListDto>>
{
    private readonly IBookingsRepository _repo;

    public GetCustomerJobsQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<JobListDto>> Handle(GetCustomerJobsQuery request, CancellationToken cancellationToken)
    {
        var (jobs, total) = await _repo.GetByCustomerIdAsync(
            request.CustomerId,
            request.Status,
            request.Page,
            request.PageSize,
            cancellationToken);

        var dtos = jobs.Select(job => new JobDto(
            job.Id,
            job.ReferenceNumber,
            job.CustomerId,
            job.ProviderId,
            job.CategoryId,
            job.Description,
            job.Latitude,
            job.Longitude,
            job.Address,
            job.Status,
            job.Photos.Where(p => p.PhotoType == "before").Select(p => p.Url).ToList(),
            job.Photos.Where(p => p.PhotoType == "after").Select(p => p.Url).ToList(),
            job.CreatedAt,
            HasOpenDispute: false,
            TransactionStatus: null
        )).ToList();

        return Result<JobListDto>.Ok(new JobListDto(dtos, total, request.Page, request.PageSize));
    }
}
