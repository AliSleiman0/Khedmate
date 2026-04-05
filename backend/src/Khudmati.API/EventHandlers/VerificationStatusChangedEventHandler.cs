using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Modules.Providers.Domain.Events;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class VerificationStatusChangedEventHandler : INotificationHandler<VerificationStatusChangedEvent>
{
    private readonly IHubContext<JobHub> _hub;
    private readonly INotificationRepository _notificationRepo;
    private readonly IPushNotificationService _push;

    public VerificationStatusChangedEventHandler(
        IHubContext<JobHub> hub,
        INotificationRepository notificationRepo,
        IPushNotificationService push)
    {
        _hub = hub;
        _notificationRepo = notificationRepo;
        _push = push;
    }

    public async Task Handle(VerificationStatusChangedEvent notification, CancellationToken cancellationToken)
    {
        await _hub.Clients
            .Group($"provider-{notification.ProviderId}")
            .SendAsync("VerificationStatusChanged", new
            {
                newTier = notification.NewTier.ToString(),
                status = notification.Status,
                message = notification.Message
            }, cancellationToken);

        var isApproved = notification.Status == "Approved";
        var title = isApproved ? "تم التحقق من حسابك ✅" : "مراجعة مطلوبة ❌";
        var body = isApproved
            ? "يمكنك الآن استقبال الطلبات"
            : "يرجى إعادة رفع مستنداتك";
        var notifType = isApproved ? "verification_approved" : "verification_rejected";

        var notif = Notification.Create(notification.ProviderId, "provider", title, body);
        await _notificationRepo.AddAsync(notif, cancellationToken);
        await _notificationRepo.SaveChangesAsync(cancellationToken);

        await _push.SendAsync(
            notification.ProviderId,
            "provider",
            title,
            body,
            new Dictionary<string, string> { ["type"] = notifType },
            cancellationToken);
    }
}
