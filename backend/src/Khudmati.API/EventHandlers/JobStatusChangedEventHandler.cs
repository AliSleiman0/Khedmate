using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class JobStatusChangedEventHandler : INotificationHandler<JobStatusChangedEvent>
{
    private readonly IHubContext<JobHub> _hub;
    private readonly INotificationRepository _notificationRepo;
    private readonly IPushNotificationService _push;

    public JobStatusChangedEventHandler(
        IHubContext<JobHub> hub,
        INotificationRepository notificationRepo,
        IPushNotificationService push)
    {
        _hub = hub;
        _notificationRepo = notificationRepo;
        _push = push;
    }

    public async Task Handle(JobStatusChangedEvent notification, CancellationToken cancellationToken)
    {
        await _hub.Clients
            .Group($"customer-{notification.CustomerId}")
            .SendAsync("JobStatusChanged", new
            {
                jobId = notification.JobId,
                status = notification.To.ToString(),
                updatedAt = DateTime.UtcNow
            }, cancellationToken);

        string? title = null;
        string? body = null;
        string? notifType = null;

        if (notification.To == JobStatus.EnRoute)
        {
            title = "المزود في الطريق 🚗";
            body = "تتبّع موقعه الآن من التطبيق";
            notifType = "job_en_route";
        }
        else if (notification.To == JobStatus.Completed)
        {
            title = "اكتملت الخدمة 🎉";
            body = "يرجى تقييم تجربتك";
            notifType = "job_completed";
        }

        if (title is not null && body is not null && notifType is not null)
        {
            var notif = Notification.Create(notification.CustomerId, "customer", title, body);
            await _notificationRepo.AddAsync(notif, cancellationToken);
            await _notificationRepo.SaveChangesAsync(cancellationToken);

            await _push.SendAsync(
                notification.CustomerId,
                "customer",
                title,
                body,
                new Dictionary<string, string> { ["type"] = notifType, ["jobId"] = notification.JobId.ToString() },
                cancellationToken);
        }
    }
}
