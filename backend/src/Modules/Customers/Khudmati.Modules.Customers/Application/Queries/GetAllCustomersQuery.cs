using Khudmati.Modules.Customers.Application.DTOs;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Customers.Application.Queries;

public record GetAllCustomersQuery(
    string? Search = null,
    bool? IsActive = null,
    int Page = 1,
    int PageSize = 20
) : IRequest<Result<(List<CustomerDto> Customers, int Total)>>;

public class GetAllCustomersQueryHandler
    : IRequestHandler<GetAllCustomersQuery, Result<(List<CustomerDto> Customers, int Total)>>
{
    private readonly AppDbContext _context;

    public GetAllCustomersQueryHandler(AppDbContext context) => _context = context;

    public async Task<Result<(List<CustomerDto> Customers, int Total)>> Handle(
        GetAllCustomersQuery request, CancellationToken cancellationToken)
    {
        var pageSize = Math.Min(request.PageSize, 50);
        var page = Math.Max(request.Page, 1);

        var query = _context.Set<Customer>().AsQueryable();

        if (request.IsActive.HasValue)
            query = query.Where(c => c.IsActive == request.IsActive.Value);

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(c =>
                c.FullName.ToLower().Contains(search) ||
                c.Phone.Contains(search) ||
                (c.Email != null && c.Email.ToLower().Contains(search)));
        }

        var total = await query.CountAsync(cancellationToken);

        var customers = await query
            .OrderByDescending(c => c.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new CustomerDto(c.Id, c.FullName, c.Phone, c.Email, c.IsActive, c.CreatedAt))
            .ToListAsync(cancellationToken);

        return Result<(List<CustomerDto>, int)>.Ok((customers, total));
    }
}
