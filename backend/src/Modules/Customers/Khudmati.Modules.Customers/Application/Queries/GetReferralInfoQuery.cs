using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Queries;

// ── Query ────────────────────────────────────────────────────────────────────
public record GetReferralInfoQuery(Guid CustomerId) : IRequest<Result<ReferralInfoDto>>;

public record ReferralInfoDto(
    string Code,
    string ShareUrl,
    decimal CreditBalance,
    string Currency,
    int ReferralsCompleted);

// ── Handler ──────────────────────────────────────────────────────────────────
public class GetReferralInfoQueryHandler
    : IRequestHandler<GetReferralInfoQuery, Result<ReferralInfoDto>>
{
    private const string ShareBaseUrl = "https://khudmati.app/join?ref=";

    private readonly ICustomersRepository _repo;

    public GetReferralInfoQueryHandler(ICustomersRepository repo) => _repo = repo;

    public async Task<Result<ReferralInfoDto>> Handle(
        GetReferralInfoQuery request, CancellationToken cancellationToken)
    {
        var referralCode = await _repo.GetReferralCodeByCustomerIdAsync(request.CustomerId, cancellationToken);
        if (referralCode is null)
            return Result<ReferralInfoDto>.Fail("REFERRAL_CODE_NOT_FOUND");

        var creditBalance = await _repo.GetTotalActiveCreditBalanceAsync(request.CustomerId, cancellationToken);
        var completed = await _repo.CountCompletedReferralsByReferrerAsync(request.CustomerId, cancellationToken);

        return Result<ReferralInfoDto>.Ok(new ReferralInfoDto(
            referralCode.Code,
            ShareBaseUrl + referralCode.Code,
            creditBalance,
            "SAR",
            completed));
    }
}
