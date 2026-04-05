using Khudmati.Modules.Customers.Application.Commands;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Queries;

// ── Query ────────────────────────────────────────────────────────────────────
public record GetCheckoutDiscountsQuery(
    Guid CustomerId,
    decimal OriginalAmount) : IRequest<Result<CheckoutDiscountsDto>>;

public record CheckoutDiscountsDto(
    decimal ReferralDiscountAmount,
    decimal CreditToApply,
    decimal NetAmount);

// ── Handler ──────────────────────────────────────────────────────────────────
public class GetCheckoutDiscountsQueryHandler
    : IRequestHandler<GetCheckoutDiscountsQuery, Result<CheckoutDiscountsDto>>
{
    private readonly ICustomersRepository _repo;

    public GetCheckoutDiscountsQueryHandler(ICustomersRepository repo) => _repo = repo;

    public async Task<Result<CheckoutDiscountsDto>> Handle(
        GetCheckoutDiscountsQuery request, CancellationToken cancellationToken)
    {
        decimal discountAmount = 0m;
        decimal creditToApply = 0m;
        var remaining = request.OriginalAmount;

        // 1. Check for pending referee discount (first booking discount)
        var referralUse = await _repo.GetPendingReferralUseByReferredCustomerAsync(
            request.CustomerId, cancellationToken);
        if (referralUse is not null)
        {
            discountAmount = Math.Round(remaining * referralUse.RefereeDiscountPct / 100m, 2);
            remaining -= discountAmount;
        }

        // 2. Check available platform credit (oldest-expiry-first)
        var totalCredit = await _repo.GetTotalActiveCreditBalanceAsync(request.CustomerId, cancellationToken);
        creditToApply = Math.Min(totalCredit, remaining);
        creditToApply = Math.Round(creditToApply, 2);
        remaining -= creditToApply;

        var netAmount = Math.Max(0.50m, remaining); // Stripe minimum
        return Result<CheckoutDiscountsDto>.Ok(new CheckoutDiscountsDto(discountAmount, creditToApply, netAmount));
    }
}
