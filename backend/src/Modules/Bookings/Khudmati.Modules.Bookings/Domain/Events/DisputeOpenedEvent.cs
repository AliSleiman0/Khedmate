using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record DisputeOpenedEvent(
    Guid DisputeId,
    Guid JobId,
    Guid CustomerId,
    Guid ProviderId
) : INotification;
