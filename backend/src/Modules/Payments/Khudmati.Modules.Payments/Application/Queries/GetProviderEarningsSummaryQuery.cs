using Khudmati.Modules.Payments.Application.DTOs;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Payments.Application.Queries;

public record GetProviderEarningsSummaryQuery(Guid ProviderId) : IRequest<Result<EarningsSummaryDto>>;

public class GetProviderEarningsSummaryQueryHandler
    : IRequestHandler<GetProviderEarningsSummaryQuery, Result<EarningsSummaryDto>>
{
    private readonly IPaymentsRepository _repo;

    public GetProviderEarningsSummaryQueryHandler(IPaymentsRepository repo) => _repo = repo;

    public async Task<Result<EarningsSummaryDto>> Handle(
        GetProviderEarningsSummaryQuery request, CancellationToken cancellationToken)
    {
        var stripeAccount = await _repo.GetProviderStripeAccountAsync(request.ProviderId, cancellationToken);
        var stripeStatus = stripeAccount switch
        {
            null => "not_started",
            { OnboardingStatus: "complete" } => "complete",
            _ => "pending"
        };

        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var allTransactions = await _repo.GetAllByProviderIdAsync(request.ProviderId, cancellationToken);

        var pendingBalance = allTransactions
            .Where(t => t.Status == "Held")
            .Sum(t => t.NetAmount);

        var availableBalance = allTransactions
            .Where(t => t.Status == "Released")
            .Sum(t => t.NetAmount);

        var totalAllTime = allTransactions
            .Where(t => t.Status is "Released" or "Held")
            .Sum(t => t.NetAmount);

        var totalThisMonth = allTransactions
            .Where(t => t.Status is "Released" or "Held" && t.CreatedAt >= monthStart)
            .Sum(t => t.NetAmount);

        return Result<EarningsSummaryDto>.Ok(new EarningsSummaryDto(
            pendingBalance,
            availableBalance,
            totalAllTime,
            totalThisMonth,
            "usd",
            stripeStatus));
    }
}
