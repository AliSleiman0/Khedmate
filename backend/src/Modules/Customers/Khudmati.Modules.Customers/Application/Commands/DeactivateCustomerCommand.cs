using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Customers.Application.Commands;

public record DeactivateCustomerCommand(Guid CustomerId) : IRequest<Result<bool>>;

public class DeactivateCustomerCommandHandler
    : IRequestHandler<DeactivateCustomerCommand, Result<bool>>
{
    private readonly AppDbContext _context;

    public DeactivateCustomerCommandHandler(AppDbContext context) => _context = context;

    public async Task<Result<bool>> Handle(
        DeactivateCustomerCommand request, CancellationToken cancellationToken)
    {
        var customer = await _context.Set<Customer>()
            .FirstOrDefaultAsync(c => c.Id == request.CustomerId, cancellationToken);

        if (customer is null)
            return Result<bool>.Fail("CUSTOMER_NOT_FOUND");

        if (!customer.IsActive)
            return Result<bool>.Fail("CUSTOMER_ALREADY_INACTIVE");

        customer.Deactivate();
        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Ok(true);
    }
}
