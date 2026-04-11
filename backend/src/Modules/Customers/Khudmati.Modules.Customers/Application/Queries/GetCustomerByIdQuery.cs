using Khudmati.Modules.Customers.Application.DTOs;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Customers.Application.Queries;

public record GetCustomerByIdQuery(Guid CustomerId) : IRequest<Result<CustomerDto>>;

public class GetCustomerByIdQueryHandler
    : IRequestHandler<GetCustomerByIdQuery, Result<CustomerDto>>
{
    private readonly AppDbContext _context;

    public GetCustomerByIdQueryHandler(AppDbContext context) => _context = context;

    public async Task<Result<CustomerDto>> Handle(
        GetCustomerByIdQuery request, CancellationToken cancellationToken)
    {
        var customer = await _context.Set<Customer>()
            .Where(c => c.Id == request.CustomerId)
            .Select(c => new CustomerDto(c.Id, c.FullName, c.Phone, c.Email, c.IsActive, c.CreatedAt))
            .FirstOrDefaultAsync(cancellationToken);

        if (customer is null)
            return Result<CustomerDto>.Fail("CUSTOMER_NOT_FOUND");

        return Result<CustomerDto>.Ok(customer);
    }
}
