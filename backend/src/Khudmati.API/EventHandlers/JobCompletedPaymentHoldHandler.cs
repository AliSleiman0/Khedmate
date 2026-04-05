using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Payments.Application.Commands;
using MediatR;
using Microsoft.Extensions.Configuration;

namespace Khudmati.API.EventHandlers;

/// <summary>
/// When a job reaches Completed status, starts the 24-hour payment hold window.
/// When PaymentBypass is enabled (demo mode), skips Stripe and directly marks the job Paid.
/// </summary>
public class JobCompletedPaymentHoldHandler : INotificationHandler<JobStatusChangedEvent>
{
    private readonly IMediator _mediator;
    private readonly bool _paymentBypass;

    public JobCompletedPaymentHoldHandler(IMediator mediator, IConfiguration configuration)
    {
        _mediator = mediator;
        _paymentBypass = configuration.GetValue<bool>("PaymentBypass");
    }

    public async Task Handle(JobStatusChangedEvent notification, CancellationToken cancellationToken)
    {
        if (notification.To != JobStatus.Completed) return;

        if (_paymentBypass)
        {
            await _mediator.Send(new MarkJobPaidCommand(notification.JobId), cancellationToken);
            return;
        }

        await _mediator.Send(new HoldPaymentCommand(notification.JobId), cancellationToken);
    }
}
