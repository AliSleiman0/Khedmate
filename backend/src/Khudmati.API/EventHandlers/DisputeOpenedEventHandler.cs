using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class DisputeOpenedEventHandler : INotificationHandler<DisputeOpenedEvent>
{
    private readonly IHubContext<JobHub> _hub;

    public DisputeOpenedEventHandler(IHubContext<JobHub> hub) => _hub = hub;

    public async Task Handle(DisputeOpenedEvent notification, CancellationToken cancellationToken)
    {
        await _hub.Clients
            .Group($"provider-{notification.ProviderId}")
            .SendAsync(
                "DisputeOpened",
                new
                {
                    disputeId = notification.DisputeId,
                    jobId = notification.JobId,
                    message = "A customer has raised a dispute on your job."
                },
                cancellationToken);
    }
}
