using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands;

/// <summary>
/// Consumes up to <paramref name="AmountToConsume"/> of platform credit for a customer,
/// consuming oldest-expiry-first and splitting partially consumed rows.
/// Called from PaymentsController after confirming a successful payment.
/// </summary>
public record ConsumeCustomerCreditsCommand(
    Guid CustomerId,
    decimal AmountToConsume) : IRequest<Result>;

public class ConsumeCustomerCreditsCommandHandler
    : IRequestHandler<ConsumeCustomerCreditsCommand, Result>
{
    private readonly ICustomersRepository _repo;

    public ConsumeCustomerCreditsCommandHandler(ICustomersRepository repo) => _repo = repo;

    public async Task<Result> Handle(
        ConsumeCustomerCreditsCommand request, CancellationToken cancellationToken)
    {
        if (request.AmountToConsume <= 0)
            return Result.Ok();

        var credits = await _repo.GetActiveCreditsAsync(request.CustomerId, cancellationToken);
        var sorted = credits.OrderBy(c => c.ExpiresAt).ToList();

        var remaining = request.AmountToConsume;

        foreach (var credit in sorted)
        {
            if (remaining <= 0) break;

            if (credit.Amount <= remaining)
            {
                // Fully consume this credit row
                remaining -= credit.Amount;
                credit.MarkUsed();
                await _repo.UpdateCreditAsync(credit, cancellationToken);
            }
            else
            {
                // Partially consume: mark old row as used, create new row for remainder
                var newCredit = credit.ApplyPartial(remaining);
                remaining = 0;
                await _repo.UpdateCreditAsync(credit, cancellationToken);
                if (newCredit.Id != credit.Id)
                    await _repo.AddCreditAsync(newCredit, cancellationToken);
            }
        }

        await _repo.SaveChangesAsync(cancellationToken);
        return Result.Ok();
    }
}
