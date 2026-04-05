using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Application.Commands;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class JobAcceptedEventHandler : INotificationHandler<JobAcceptedEvent>
{
    private readonly IHubContext<JobHub> _hub;
    private readonly IProvidersRepository _providersRepo;
    private readonly IMediator _mediator;
    private readonly INotificationRepository _notificationRepo;
    private readonly IPushNotificationService _push;

    public JobAcceptedEventHandler(
        IHubContext<JobHub> hub,
        IProvidersRepository providersRepo,
        IMediator mediator,
        INotificationRepository notificationRepo,
        IPushNotificationService push)
    {
        _hub = hub;
        _providersRepo = providersRepo;
        _mediator = mediator;
        _notificationRepo = notificationRepo;
        _push = push;
    }

    public async Task Handle(JobAcceptedEvent notification, CancellationToken cancellationToken)
    {
        var provider = await _providersRepo.GetByIdAsync(notification.ProviderId, cancellationToken);

        await _hub.Clients
            .Group($"customer-{notification.CustomerId}")
            .SendAsync("JobAccepted", new
            {
                jobId = notification.JobId,
                providerName = provider?.FullName ?? "مزود الخدمة",
                providerPhone = provider?.Phone ?? "",
                providerRating = provider?.Rating ?? 0.0
            }, cancellationToken);

        // Persist notification
        const string title = "طلبك قُبل ✅";
        const string body = "مزود الخدمة في طريقه إليك قريباً";
        var notif = Notification.Create(notification.CustomerId, "customer", title, body);
        await _notificationRepo.AddAsync(notif, cancellationToken);
        await _notificationRepo.SaveChangesAsync(cancellationToken);

        // Push notification
        await _push.SendAsync(
            notification.CustomerId,
            "customer",
            title,
            body,
            new Dictionary<string, string> { ["type"] = "job_accepted", ["jobId"] = notification.JobId.ToString() },
            cancellationToken);

        // Link the provider to the pending transaction (customer paid before provider was assigned)
        await _mediator.Send(
            new AssignTransactionProviderCommand(notification.JobId, notification.ProviderId),
            cancellationToken);
    }
}
