using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetAdminJobDetailQuery(Guid JobId) : IRequest<Result<AdminJobDetailDto>>;

public class GetAdminJobDetailQueryHandler : IRequestHandler<GetAdminJobDetailQuery, Result<AdminJobDetailDto>>
{
    private readonly AppDbContext _context;

    public GetAdminJobDetailQueryHandler(AppDbContext context) => _context = context;

    public async Task<Result<AdminJobDetailDto>> Handle(
        GetAdminJobDetailQuery request, CancellationToken cancellationToken)
    {
        var job = await _context.Set<Job>()
            .Include(j => j.Photos)
            .FirstOrDefaultAsync(j => j.Id == request.JobId, cancellationToken);

        if (job is null)
            return Result<AdminJobDetailDto>.Fail("JOB_NOT_FOUND");

        var customer = await _context.Set<Customer>()
            .FirstOrDefaultAsync(c => c.Id == job.CustomerId, cancellationToken);

        Provider? provider = null;
        if (job.ProviderId.HasValue)
        {
            provider = await _context.Set<Provider>()
                .FirstOrDefaultAsync(p => p.Id == job.ProviderId.Value, cancellationToken);
        }

        var statusHistory = await _context.Set<JobStatusHistory>()
            .Where(h => h.JobId == request.JobId)
            .OrderBy(h => h.ChangedAt)
            .ToListAsync(cancellationToken);

        var rating = await _context.Set<Rating>()
            .FirstOrDefaultAsync(r => r.JobId == request.JobId && r.RaterType == "customer", cancellationToken);

        var transaction = await _context.Set<Transaction>()
            .FirstOrDefaultAsync(t => t.JobId == request.JobId, cancellationToken);

        var photoUrls = job.Photos
            .OrderBy(p => p.UploadedAt)
            .Select(p => p.Url)
            .ToList();

        var historyDtos = statusHistory.Select(h => new AdminJobStatusHistoryDto(
            h.PreviousStatus,
            h.NewStatus,
            h.ChangedAt,
            h.ChangedBy
        )).ToList();

        AdminJobRatingDto? ratingDto = rating is null ? null : new AdminJobRatingDto(
            rating.IsPositive,
            rating.Tags,
            rating.SubmittedAt,
            rating.RaterType
        );

        var dto = new AdminJobDetailDto(
            job.Id,
            job.ReferenceNumber,
            job.CustomerId,
            customer?.FullName ?? "",
            job.ProviderId,
            provider?.FullName,
            job.CategoryId,
            job.Description,
            job.Latitude,
            job.Longitude,
            job.Address,
            job.Status,
            job.CreatedAt,
            job.AcceptedAt,
            job.PaidAt,
            transaction?.GrossAmount,
            photoUrls,
            historyDtos,
            ratingDto
        );

        return Result<AdminJobDetailDto>.Ok(dto);
    }
}
