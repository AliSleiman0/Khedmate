using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class DisputeResolvedEventHandler : INotificationHandler<DisputeResolvedEvent>
{
    private readonly IHubContext<JobHub> _hub;

    public DisputeResolvedEventHandler(IHubContext<JobHub> hub) => _hub = hub;

    public async Task Handle(DisputeResolvedEvent notification, CancellationToken cancellationToken)
    {
        if (notification.Action == "approve_refund")
        {
            // Notify customer
            await _hub.Clients
                .Group($"customer-{notification.CustomerId}")
                .SendAsync(
                    "DisputeResolved",
                    new
                    {
                        disputeId = notification.DisputeId,
                        outcome = "refunded",
                        message = "Your dispute has been approved. A refund has been issued to your card."
                    },
                    cancellationToken);

            // Notify provider
            await _hub.Clients
                .Group($"provider-{notification.ProviderId}")
                .SendAsync(
                    "DisputeResolved",
                    new
                    {
                        disputeId = notification.DisputeId,
                        outcome = "refunded",
                        message = "The customer's dispute was approved. Your payment will not be released."
                    },
                    cancellationToken);
        }
        else // reject
        {
            // Notify customer
            await _hub.Clients
                .Group($"customer-{notification.CustomerId}")
                .SendAsync(
                    "DisputeResolved",
                    new
                    {
                        disputeId = notification.DisputeId,
                        outcome = "rejected",
                        message = "Your dispute was reviewed and rejected. No refund will be issued."
                    },
                    cancellationToken);

            // Notify provider
            await _hub.Clients
                .Group($"provider-{notification.ProviderId}")
                .SendAsync(
                    "DisputeResolved",
                    new
                    {
                        disputeId = notification.DisputeId,
                        outcome = "payment_released",
                        message = "The dispute was rejected. Your payment has been released."
                    },
                    cancellationToken);
        }
    }
}
