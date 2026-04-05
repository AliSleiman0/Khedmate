using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetAdminDisputeDetailQuery(Guid DisputeId) : IRequest<Result<AdminDisputeDetailDto>>;

public class GetAdminDisputeDetailQueryHandler
    : IRequestHandler<GetAdminDisputeDetailQuery, Result<AdminDisputeDetailDto>>
{
    private readonly AppDbContext _context;

    public GetAdminDisputeDetailQueryHandler(AppDbContext context) => _context = context;

    public async Task<Result<AdminDisputeDetailDto>> Handle(
        GetAdminDisputeDetailQuery request, CancellationToken cancellationToken)
    {
        var dispute = await _context.Set<Dispute>()
            .FirstOrDefaultAsync(d => d.Id == request.DisputeId, cancellationToken);

        if (dispute is null)
            return Result<AdminDisputeDetailDto>.Fail("DISPUTE_NOT_FOUND");

        var job = await _context.Set<Job>()
            .Include(j => j.Photos)
            .FirstOrDefaultAsync(j => j.Id == dispute.JobId, cancellationToken);

        if (job is null)
            return Result<AdminDisputeDetailDto>.Fail("DISPUTE_NOT_FOUND");

        var customer = await _context.Set<Customer>()
            .FirstOrDefaultAsync(c => c.Id == dispute.CustomerId, cancellationToken);

        var provider = await _context.Set<Provider>()
            .FirstOrDefaultAsync(p => p.Id == dispute.ProviderId, cancellationToken);

        var transaction = await _context.Set<Transaction>()
            .Where(t => t.JobId == dispute.JobId && t.Status != "Pending")
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        var statusHistory = await _context.Set<JobStatusHistory>()
            .Where(h => h.JobId == dispute.JobId)
            .OrderBy(h => h.ChangedAt)
            .ToListAsync(cancellationToken);

        var photos = job.Photos
            .OrderBy(p => p.UploadedAt)
            .Select(p => p.Url)
            .ToList();

        var historyDtos = statusHistory.Select(h => new AdminDisputeStatusHistoryDto(
            h.PreviousStatus,
            h.NewStatus,
            h.ChangedAt,
            h.ChangedBy
        )).ToList();

        var dto = new AdminDisputeDetailDto(
            dispute.Id,
            job.Id,
            job.ReferenceNumber,
            dispute.CustomerId,
            customer?.FullName ?? "",
            dispute.ProviderId,
            provider?.FullName ?? "",
            job.CategoryId,
            job.Address,
            transaction?.GrossAmount ?? 0m,
            dispute.Status,
            dispute.Complaint,
            dispute.AdminNote,
            dispute.ResolvedAt,
            dispute.ResolvedByAdminId,
            dispute.CreatedAt,
            job.CreatedAt,
            job.PaidAt,
            photos,
            historyDtos
        );

        return Result<AdminDisputeDetailDto>.Ok(dto);
    }
}
