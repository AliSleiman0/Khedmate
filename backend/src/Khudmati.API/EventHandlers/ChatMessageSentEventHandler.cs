using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.API.EventHandlers;

public class ChatMessageSentEventHandler : INotificationHandler<ChatMessageSentEvent>
{
    private readonly IHubContext<JobHub> _hub;

    public ChatMessageSentEventHandler(IHubContext<JobHub> hub)
    {
        _hub = hub;
    }

    public async Task Handle(ChatMessageSentEvent notification, CancellationToken cancellationToken)
    {
        var payload = new
        {
            id = notification.MessageId,
            jobId = notification.JobId,
            senderId = notification.SenderId,
            senderType = notification.SenderType,
            text = notification.Text,
            sentAt = notification.SentAt
        };

        // Send to the OTHER party only (not the sender)
        if (notification.SenderType == "customer")
        {
            await _hub.Clients
                .Group($"provider-{notification.ProviderId}")
                .SendAsync("NewChatMessage", payload, cancellationToken);
        }
        else
        {
            await _hub.Clients
                .Group($"customer-{notification.CustomerId}")
                .SendAsync("NewChatMessage", payload, cancellationToken);
        }
    }
}
