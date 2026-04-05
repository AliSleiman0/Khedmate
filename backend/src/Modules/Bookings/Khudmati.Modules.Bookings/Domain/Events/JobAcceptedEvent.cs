using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record JobAcceptedEvent(Guid JobId, Guid CustomerId, Guid ProviderId) : INotification;
