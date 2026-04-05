using Khudmati.Modules.Payments.Domain.Events;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Payments.Application.Commands;

/// <summary>
/// Releases held funds to the provider via Stripe Connect transfer.
/// Called by PaymentReleaseService (background) after the 24h dispute window expires.
/// </summary>
public record ReleasePaymentCommand(Guid TransactionId) : IRequest<Result>;

public class ReleasePaymentCommandHandler : IRequestHandler<ReleasePaymentCommand, Result>
{
    private readonly IPaymentsRepository _repo;
    private readonly IPaymentProvider _paymentProvider;
    private readonly IMediator _mediator;
    private readonly ILogger<ReleasePaymentCommandHandler> _logger;

    public ReleasePaymentCommandHandler(
        IPaymentsRepository repo,
        IPaymentProvider paymentProvider,
        IMediator mediator,
        ILogger<ReleasePaymentCommandHandler> logger)
    {
        _repo = repo;
        _paymentProvider = paymentProvider;
        _mediator = mediator;
        _logger = logger;
    }

    public async Task<Result> Handle(ReleasePaymentCommand request, CancellationToken cancellationToken)
    {
        var transaction = await _repo.GetByIdAsync(request.TransactionId, cancellationToken);

        if (transaction is null)
            return Result.Fail("TRANSACTION_NOT_FOUND");

        if (transaction.Status != "Held")
            return Result.Fail("INVALID_STATUS");

        if (transaction.HoldUntil > DateTime.UtcNow)
            return Result.Fail("HOLD_NOT_EXPIRED");

        // Check provider has a Stripe Connect account
        var stripeAccount = await _repo.GetProviderStripeAccountAsync(
            transaction.ProviderId, cancellationToken);

        if (stripeAccount is null || stripeAccount.OnboardingStatus != "complete")
        {
            _logger.LogWarning(
                "Provider {ProviderId} has no complete Stripe Connect account. " +
                "Skipping release for transaction {TransactionId} — will retry next cycle.",
                transaction.ProviderId, transaction.Id);
            return Result.Fail("PROVIDER_NOT_ONBOARDED");
        }

        // Transfer net amount to provider's Stripe account
        var transfer = await _paymentProvider.TransferToProviderAsync(
            stripeAccount.StripeAccountId,
            transaction.NetAmount,
            transaction.Currency,
            cancellationToken);

        transaction.MarkReleased(transfer.TransferId);
        await _repo.SaveChangesAsync(cancellationToken);

        await _mediator.Publish(new PaymentReleasedEvent(
            transaction.JobId,
            transaction.ProviderId,
            transaction.NetAmount,
            transaction.Currency), cancellationToken);

        return Result.Ok();
    }
}
