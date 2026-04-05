using FluentValidation;
using Khudmati.Modules.Payments.Application.DTOs;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Payments.Application.Commands;

public record ConfirmPaymentCommand(
    Guid CustomerId,
    string PaymentIntentId,
    Guid JobId) : IRequest<Result<TransactionDto>>;

public class ConfirmPaymentCommandValidator : AbstractValidator<ConfirmPaymentCommand>
{
    public ConfirmPaymentCommandValidator()
    {
        RuleFor(x => x.PaymentIntentId).NotEmpty();
        RuleFor(x => x.JobId).NotEmpty();
    }
}

public class ConfirmPaymentCommandHandler
    : IRequestHandler<ConfirmPaymentCommand, Result<TransactionDto>>
{
    private readonly IPaymentsRepository _repo;
    private readonly IPaymentProvider _paymentProvider;

    public ConfirmPaymentCommandHandler(IPaymentsRepository repo, IPaymentProvider paymentProvider)
    {
        _repo = repo;
        _paymentProvider = paymentProvider;
    }

    public async Task<Result<TransactionDto>> Handle(
        ConfirmPaymentCommand request, CancellationToken cancellationToken)
    {
        // Verify job doesn't already have a confirmed payment
        var existing = await _repo.GetByJobIdAsync(request.JobId, cancellationToken);
        if (existing is not null && existing.Status != "Pending")
            return Result<TransactionDto>.Fail("PAYMENT_ALREADY_EXISTS");

        // Find the pending transaction for this payment intent
        var transaction = await _repo.GetByPaymentIntentIdAsync(
            request.PaymentIntentId, cancellationToken);

        if (transaction is null)
            return Result<TransactionDto>.Fail("TRANSACTION_NOT_FOUND");

        if (transaction.CustomerId != request.CustomerId)
            return Result<TransactionDto>.Fail("FORBIDDEN");

        // Verify Stripe says payment succeeded
        var confirmResult = await _paymentProvider.GetPaymentIntentStatusAsync(
            request.PaymentIntentId, cancellationToken);

        if (!confirmResult.Succeeded)
            return Result<TransactionDto>.Fail("PAYMENT_NOT_SUCCEEDED");

        transaction.LinkToJob(request.JobId);
        transaction.MarkPaid();

        await _repo.SaveChangesAsync(cancellationToken);

        return Result<TransactionDto>.Ok(ToDto(transaction));
    }

    private static TransactionDto ToDto(Domain.Entities.Transaction t) =>
        new(t.Id, t.JobId, t.CustomerId, t.ProviderId,
            t.GrossAmount, t.CommissionAmount, t.NetAmount,
            t.Currency, t.Status, t.HoldUntil, t.CreatedAt,
            t.CreditAppliedAmount, t.ReferralDiscountAmount);
}
