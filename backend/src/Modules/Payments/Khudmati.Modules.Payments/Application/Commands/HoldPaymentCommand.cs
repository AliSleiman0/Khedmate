using Khudmati.Modules.Payments.Domain.Events;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Payments.Application.Commands;

/// <summary>
/// Transitions a Paid transaction to Held, starting the 24-hour dispute window.
/// Called by the API-layer event handler when a job reaches Completed status.
/// </summary>
public record HoldPaymentCommand(Guid JobId) : IRequest<Result>;

public class HoldPaymentCommandHandler : IRequestHandler<HoldPaymentCommand, Result>
{
    private readonly IPaymentsRepository _repo;
    private readonly IMediator _mediator;
    private readonly ILogger<HoldPaymentCommandHandler> _logger;

    public HoldPaymentCommandHandler(
        IPaymentsRepository repo,
        IMediator mediator,
        ILogger<HoldPaymentCommandHandler> logger)
    {
        _repo = repo;
        _mediator = mediator;
        _logger = logger;
    }

    public async Task<Result> Handle(HoldPaymentCommand request, CancellationToken cancellationToken)
    {
        var transaction = await _repo.GetByJobIdAsync(request.JobId, cancellationToken);

        if (transaction is null)
        {
            _logger.LogError(
                "Job {JobId} marked Completed but no payment transaction found. Admin must resolve manually.",
                request.JobId);
            return Result.Ok(); // Do not crash — job completion must succeed regardless
        }

        if (transaction.Status != "Paid")
        {
            _logger.LogWarning(
                "Job {JobId} transaction {TxId} is in status {Status}, cannot hold.",
                request.JobId, transaction.Id, transaction.Status);
            return Result.Ok();
        }

        transaction.MarkHeld();
        await _repo.SaveChangesAsync(cancellationToken);

        await _mediator.Publish(new PaymentHeldEvent(
            transaction.JobId,
            transaction.CustomerId,
            transaction.ProviderId,
            transaction.GrossAmount,
            transaction.HoldUntil!.Value), cancellationToken);

        return Result.Ok();
    }
}
