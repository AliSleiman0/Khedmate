using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Domain.Events;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class PaymentHeldEventHandler : INotificationHandler<PaymentHeldEvent>
{
    private readonly IHubContext<JobHub> _hub;
    private readonly INotificationRepository _notificationRepo;
    private readonly IPushNotificationService _push;

    public PaymentHeldEventHandler(
        IHubContext<JobHub> hub,
        INotificationRepository notificationRepo,
        IPushNotificationService push)
    {
        _hub = hub;
        _notificationRepo = notificationRepo;
        _push = push;
    }

    public async Task Handle(PaymentHeldEvent notification, CancellationToken cancellationToken)
    {
        await _hub.Clients
            .Group($"customer-{notification.CustomerId}")
            .SendAsync("PaymentHeld", new
            {
                jobId = notification.JobId,
                amount = notification.GrossAmount,
                releaseDate = notification.HoldUntil
            }, cancellationToken);

        var title = "تم الدفع بنجاح 💳";
        var body = $"مبلغ {notification.GrossAmount:F2} محجوز لحين التأكيد";
        var notif = Notification.Create(notification.CustomerId, "customer", title, body);
        await _notificationRepo.AddAsync(notif, cancellationToken);
        await _notificationRepo.SaveChangesAsync(cancellationToken);

        await _push.SendAsync(
            notification.CustomerId,
            "customer",
            title,
            body,
            new Dictionary<string, string> { ["type"] = "payment_held", ["jobId"] = notification.JobId.ToString() },
            cancellationToken);
    }
}
