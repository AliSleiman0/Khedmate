using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Domain.Events;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class PaymentReleasedEventHandler : INotificationHandler<PaymentReleasedEvent>
{
    private readonly IHubContext<JobHub> _hub;
    private readonly IMediator _mediator;
    private readonly INotificationRepository _notificationRepo;
    private readonly IPushNotificationService _push;

    public PaymentReleasedEventHandler(
        IHubContext<JobHub> hub,
        IMediator mediator,
        INotificationRepository notificationRepo,
        IPushNotificationService push)
    {
        _hub = hub;
        _mediator = mediator;
        _notificationRepo = notificationRepo;
        _push = push;
    }

    public async Task Handle(PaymentReleasedEvent notification, CancellationToken cancellationToken)
    {
        // Notify provider via SignalR
        await _hub.Clients
            .Group($"provider-{notification.ProviderId}")
            .SendAsync("PaymentReleased", new
            {
                jobId = notification.JobId,
                netAmount = notification.NetAmount,
                currency = notification.Currency
            }, cancellationToken);

        var title = "تم تحويل أرباحك 💰";
        var body = $"استلمت {notification.NetAmount:F2} {notification.Currency} في حسابك";
        var notif = Notification.Create(notification.ProviderId, "provider", title, body);
        await _notificationRepo.AddAsync(notif, cancellationToken);
        await _notificationRepo.SaveChangesAsync(cancellationToken);

        await _push.SendAsync(
            notification.ProviderId,
            "provider",
            title,
            body,
            new Dictionary<string, string> { ["type"] = "payment_released", ["jobId"] = notification.JobId.ToString() },
            cancellationToken);

        // Transition job from Completed → Paid
        await _mediator.Send(new MarkJobPaidCommand(notification.JobId), cancellationToken);
    }
}
