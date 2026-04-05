using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record JobExpiredEvent(Guid JobId, Guid CustomerId) : INotification;
