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

public record GetAdminDisputesQuery(
    string? Status,
    string? Search,
    int Page,
    int PageSize
) : IRequest<Result<AdminDisputeListResultDto>>;

public class GetAdminDisputesQueryHandler
    : IRequestHandler<GetAdminDisputesQuery, Result<AdminDisputeListResultDto>>
{
    private readonly AppDbContext _context;

    public GetAdminDisputesQueryHandler(AppDbContext context) => _context = context;

    public async Task<Result<AdminDisputeListResultDto>> Handle(
        GetAdminDisputesQuery request, CancellationToken cancellationToken)
    {
        var pageSize = Math.Min(request.PageSize, 50);
        var page = Math.Max(request.Page, 1);

        // Aggregate counts across ALL disputes (not paged)
        var allCounts = await _context.Set<Dispute>()
            .GroupBy(d => d.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var openCount     = allCounts.FirstOrDefault(c => c.Status == "Open")?.Count ?? 0;
        var resolvedCount = allCounts.FirstOrDefault(c => c.Status == "Resolved")?.Count ?? 0;
        var rejectedCount = allCounts.FirstOrDefault(c => c.Status == "Rejected")?.Count ?? 0;

        var query =
            from dispute in _context.Set<Dispute>()
            join job in _context.Set<Job>() on dispute.JobId equals job.Id
            join customer in _context.Set<Customer>() on dispute.CustomerId equals customer.Id into custGroup
            from customer in custGroup.DefaultIfEmpty()
            join provider in _context.Set<Provider>() on dispute.ProviderId equals provider.Id into provGroup
            from provider in provGroup.DefaultIfEmpty()
            join tx in _context.Set<Transaction>() on dispute.JobId equals tx.JobId into txGroup
            from tx in txGroup.DefaultIfEmpty()
            select new
            {
                dispute.Id,
                dispute.JobId,
                job.ReferenceNumber,
                dispute.CustomerId,
                CustomerName = customer == null ? "" : customer.FullName,
                dispute.ProviderId,
                ProviderName = provider == null ? "" : provider.FullName,
                Amount = tx == null ? 0m : tx.GrossAmount,
                dispute.Status,
                dispute.CreatedAt
            };

        // Filter by status
        if (!string.IsNullOrWhiteSpace(request.Status))
            query = query.Where(d => d.Status == request.Status);

        // Filter by search
        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var searchLower = request.Search.ToLower();
            query = query.Where(d =>
                d.ReferenceNumber.ToLower().Contains(searchLower) ||
                d.CustomerName.ToLower().Contains(searchLower) ||
                d.ProviderName.ToLower().Contains(searchLower));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var rows = await query
            .OrderByDescending(d => d.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var items = rows.Select(r => new AdminDisputeSummaryDto(
            r.Id,
            r.JobId,
            r.ReferenceNumber,
            r.CustomerId,
            r.CustomerName,
            r.ProviderId,
            r.ProviderName,
            r.Amount,
            r.Status,
            r.CreatedAt
        )).ToList();

        return Result<AdminDisputeListResultDto>.Ok(new AdminDisputeListResultDto(
            items,
            totalCount,
            page,
            pageSize,
            openCount,
            resolvedCount,
            rejectedCount
        ));
    }
}
