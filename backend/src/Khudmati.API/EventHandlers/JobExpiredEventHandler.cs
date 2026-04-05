using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class JobExpiredEventHandler : INotificationHandler<JobExpiredEvent>
{
    private readonly IHubContext<JobHub> _hub;

    public JobExpiredEventHandler(IHubContext<JobHub> hub) => _hub = hub;

    public async Task Handle(JobExpiredEvent notification, CancellationToken cancellationToken)
    {
        await _hub.Clients
            .Group($"customer-{notification.CustomerId}")
            .SendAsync("JobExpired", new
            {
                jobId = notification.JobId,
                message = "لم يتم قبول طلبك، يرجى المحاولة مرة أخرى"
            }, cancellationToken);
    }
}
