using FluentValidation;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Customers.Application.Commands;

// ── Constants ──────────────────────────────────────────────────────────────
public static class ReferralConstants
{
    public const decimal ReferrerCreditAmount  = 20m;   // SAR to award to referrer
    public const decimal RefereeDiscountPct    = 15m;   // % off referee's first booking
    public const int     CreditValidityDays    = 365;
}

// ── Command ─────────────────────────────────────────────────────────────────
public record ApplyReferralCodeCommand(Guid CustomerId, string Code) : IRequest<Result<ApplyReferralCodeDto>>;

public record ApplyReferralCodeDto(string ReferrerName, decimal DiscountPct);

// ── Validator ────────────────────────────────────────────────────────────────
public class ApplyReferralCodeCommandValidator : AbstractValidator<ApplyReferralCodeCommand>
{
    public ApplyReferralCodeCommandValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(10);
    }
}

// ── Handler ──────────────────────────────────────────────────────────────────
public class ApplyReferralCodeCommandHandler
    : IRequestHandler<ApplyReferralCodeCommand, Result<ApplyReferralCodeDto>>
{
    private readonly ICustomersRepository _repo;

    public ApplyReferralCodeCommandHandler(ICustomersRepository repo) => _repo = repo;

    public async Task<Result<ApplyReferralCodeDto>> Handle(
        ApplyReferralCodeCommand request, CancellationToken cancellationToken)
    {
        // 1. Normalise code to uppercase
        var code = request.Code.Trim().ToUpperInvariant();

        // 2. Look up the referral code
        var referralCode = await _repo.GetReferralCodeByCodeAsync(code, cancellationToken);
        if (referralCode is null)
            return Result<ApplyReferralCodeDto>.Fail("REFERRAL_CODE_NOT_FOUND");

        // 3. Prevent the referee (current customer) from using a code again
        var alreadyUsed = await _repo.HasReferralUseAsReferreeAsync(request.CustomerId, cancellationToken);
        if (alreadyUsed)
            return Result<ApplyReferralCodeDto>.Fail("REFERRAL_ALREADY_USED");

        // 4. Block self-referral
        if (referralCode.CustomerId == request.CustomerId)
            return Result<ApplyReferralCodeDto>.Fail("REFERRAL_SELF_REFERRAL");

        // Additional self-referral check via phone number
        var referee = await _repo.GetByIdAsync(request.CustomerId, cancellationToken);
        var referrer = await _repo.GetByIdAsync(referralCode.CustomerId, cancellationToken);
        if (referee is null || referrer is null)
            return Result<ApplyReferralCodeDto>.Fail("REFERRAL_CODE_NOT_FOUND");

        if (referee.Phone == referrer.Phone)
            return Result<ApplyReferralCodeDto>.Fail("REFERRAL_SELF_REFERRAL");

        // 5. Create the pending referral use record
        var use = ReferralUse.Create(
            referralCode.CustomerId,
            request.CustomerId,
            ReferralConstants.ReferrerCreditAmount,
            ReferralConstants.RefereeDiscountPct);

        await _repo.AddReferralUseAsync(use, cancellationToken);
        await _repo.SaveChangesAsync(cancellationToken);

        return Result<ApplyReferralCodeDto>.Ok(
            new ApplyReferralCodeDto(referrer.FullName, ReferralConstants.RefereeDiscountPct));
    }
}
