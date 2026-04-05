using FluentValidation;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Application;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record ResolveDisputeCommand(
    Guid DisputeId,
    string Action,     // "approve_refund" | "reject"
    string AdminNote,
    Guid AdminId
) : IRequest<Result<ResolveDisputeResultDto>>;

public class ResolveDisputeCommandValidator : AbstractValidator<ResolveDisputeCommand>
{
    private static readonly HashSet<string> ValidActions = ["approve_refund", "reject"];

    public ResolveDisputeCommandValidator()
    {
        RuleFor(x => x.Action)
            .Must(a => ValidActions.Contains(a))
            .WithMessage("Action must be 'approve_refund' or 'reject'.");

        RuleFor(x => x.AdminNote)
            .NotEmpty()
            .MinimumLength(10).WithMessage("Admin note must be at least 10 characters.")
            .MaximumLength(500).WithMessage("Admin note must not exceed 500 characters.");
    }
}

public class ResolveDisputeCommandHandler
    : IRequestHandler<ResolveDisputeCommand, Result<ResolveDisputeResultDto>>
{
    private readonly IBookingsRepository _bookingsRepo;
    private readonly IPaymentsRepository _paymentsRepo;
    private readonly IPaymentProvider _paymentProvider;
    private readonly IMediator _mediator;
    private readonly ILogger<ResolveDisputeCommandHandler> _logger;

    public ResolveDisputeCommandHandler(
        IBookingsRepository bookingsRepo,
        IPaymentsRepository paymentsRepo,
        IPaymentProvider paymentProvider,
        IMediator mediator,
        ILogger<ResolveDisputeCommandHandler> logger)
    {
        _bookingsRepo = bookingsRepo;
        _paymentsRepo = paymentsRepo;
        _paymentProvider = paymentProvider;
        _mediator = mediator;
        _logger = logger;
    }

    public async Task<Result<ResolveDisputeResultDto>> Handle(
        ResolveDisputeCommand request, CancellationToken cancellationToken)
    {
        var dispute = await _bookingsRepo.GetDisputeByIdAsync(request.DisputeId, cancellationToken);
        if (dispute is null)
            return Result<ResolveDisputeResultDto>.Fail("DISPUTE_NOT_FOUND");

        if (dispute.Status != "Open")
            return Result<ResolveDisputeResultDto>.Fail("DISPUTE_ALREADY_RESOLVED");

        var transaction = await _paymentsRepo.GetByJobIdAsync(dispute.JobId, cancellationToken);
        if (transaction is null)
            return Result<ResolveDisputeResultDto>.Fail("TRANSACTION_NOT_FOUND");

        string newStatus;

        if (request.Action == "approve_refund")
        {
            try
            {
                var refundOk = await _paymentProvider.RefundAsync(
                    transaction.StripePaymentIntentId!,
                    transaction.GrossAmount,
                    transaction.Currency,
                    cancellationToken);

                if (!refundOk)
                    return Result<ResolveDisputeResultDto>.Fail("STRIPE_REFUND_FAILED");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Stripe refund failed for dispute {DisputeId}", request.DisputeId);
                return Result<ResolveDisputeResultDto>.Fail("STRIPE_REFUND_FAILED");
            }

            transaction.MarkRefunded();
            newStatus = "Resolved";
        }
        else // reject
        {
            var stripeAccount = await _paymentsRepo.GetProviderStripeAccountAsync(
                dispute.ProviderId, cancellationToken);

            if (stripeAccount is null)
                return Result<ResolveDisputeResultDto>.Fail("PROVIDER_STRIPE_ACCOUNT_NOT_FOUND");

            var transfer = await _paymentProvider.TransferToProviderAsync(
                stripeAccount.StripeAccountId,
                transaction.NetAmount,
                transaction.Currency,
                cancellationToken);

            transaction.MarkReleased(transfer.TransferId);
            newStatus = "Rejected";
        }

        dispute.Resolve(newStatus, request.AdminNote, request.AdminId);

        await _bookingsRepo.SaveChangesAsync(cancellationToken);
        await _paymentsRepo.SaveChangesAsync(cancellationToken);

        await _mediator.Publish(
            new DisputeResolvedEvent(
                dispute.Id,
                dispute.JobId,
                dispute.CustomerId,
                dispute.ProviderId,
                request.Action,
                transaction.GrossAmount,
                transaction.Currency),
            cancellationToken);

        return Result<ResolveDisputeResultDto>.Ok(new ResolveDisputeResultDto(dispute.Id, newStatus));
    }
}
