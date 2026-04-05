using FluentValidation;
using Khudmati.Modules.Payments.Application.DTOs;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Configuration;

namespace Khudmati.Modules.Payments.Application.Commands;

public record CreatePaymentIntentCommand(
    Guid CustomerId,
    decimal Amount,
    string Currency,
    string CategoryId,
    decimal ReferralDiscountAmount = 0m,
    decimal CreditAppliedAmount = 0m) : IRequest<Result<PaymentIntentDto>>;

public class CreatePaymentIntentCommandValidator : AbstractValidator<CreatePaymentIntentCommand>
{
    public CreatePaymentIntentCommandValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0).LessThanOrEqualTo(10_000)
            .WithMessage("Amount must be between 0 and 10,000.");
        RuleFor(x => x.Currency).NotEmpty().MaximumLength(10);
        RuleFor(x => x.CategoryId).NotEmpty().MaximumLength(50);
    }
}

public class CreatePaymentIntentCommandHandler
    : IRequestHandler<CreatePaymentIntentCommand, Result<PaymentIntentDto>>
{
    private readonly IPaymentsRepository _repo;
    private readonly IPaymentProvider _paymentProvider;
    private readonly IConfiguration _config;

    public CreatePaymentIntentCommandHandler(
        IPaymentsRepository repo,
        IPaymentProvider paymentProvider,
        IConfiguration config)
    {
        _repo = repo;
        _paymentProvider = paymentProvider;
        _config = config;
    }

    public async Task<Result<PaymentIntentDto>> Handle(
        CreatePaymentIntentCommand request, CancellationToken cancellationToken)
    {
        var commissionRate = _config.GetValue<decimal>("CommissionRate", 0.20m);

        // Compute net charge amount after referral discount and credit
        var totalDeductions = request.ReferralDiscountAmount + request.CreditAppliedAmount;
        var chargeAmount = Math.Max(0.50m, request.Amount - totalDeductions); // Stripe minimum is ~0.50

        var intentResult = await _paymentProvider.CreatePaymentIntentAsync(
            chargeAmount, request.Currency, cancellationToken);

        var transaction = Transaction.CreateIntent(
            request.CustomerId,
            request.Amount,     // GrossAmount is the original amount (before deductions)
            request.Currency,
            commissionRate,
            intentResult.PaymentIntentId,
            request.ReferralDiscountAmount > 0 ? request.ReferralDiscountAmount : null,
            request.CreditAppliedAmount > 0 ? request.CreditAppliedAmount : null);

        await _repo.AddAsync(transaction, cancellationToken);
        await _repo.SaveChangesAsync(cancellationToken);

        return Result<PaymentIntentDto>.Ok(new PaymentIntentDto(
            intentResult.PaymentIntentId,
            intentResult.ClientSecret,
            chargeAmount,
            request.Currency,
            request.ReferralDiscountAmount > 0 ? request.ReferralDiscountAmount : null,
            request.CreditAppliedAmount > 0 ? request.CreditAppliedAmount : null,
            request.Amount));
    }
}
