using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record ChatMessageSentEvent(
    Guid MessageId,
    Guid JobId,
    Guid SenderId,
    string SenderType,    // "customer" or "provider"
    string Text,
    DateTime SentAt,
    Guid CustomerId,
    Guid ProviderId
) : INotification;
