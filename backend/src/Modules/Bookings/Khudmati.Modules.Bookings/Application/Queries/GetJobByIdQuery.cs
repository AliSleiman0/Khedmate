using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetJobByIdQuery(Guid JobId, Guid CustomerId) : IRequest<Result<JobDto>>;

public class GetJobByIdQueryHandler : IRequestHandler<GetJobByIdQuery, Result<JobDto>>
{
    private readonly IBookingsRepository _repo;
    private readonly AppDbContext _context;

    public GetJobByIdQueryHandler(IBookingsRepository repo, AppDbContext context)
    {
        _repo = repo;
        _context = context;
    }

    public async Task<Result<JobDto>> Handle(GetJobByIdQuery request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        // Return 404 even if job exists but belongs to another customer — don't leak existence
        if (job is null || job.CustomerId != request.CustomerId)
            return Result<JobDto>.Fail("JOB_NOT_FOUND");

        // Check for open dispute
        var hasOpenDispute = await _context.Set<Dispute>()
            .AnyAsync(d => d.JobId == job.Id && d.Status == "Open", cancellationToken);

        // Get transaction status
        var transaction = await _context.Set<Transaction>()
            .Where(t => t.JobId == job.Id && t.Status != "Pending")
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        var dto = new JobDto(
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
            hasOpenDispute,
            transaction?.Status
        );

        return Result<JobDto>.Ok(dto);
    }
}
