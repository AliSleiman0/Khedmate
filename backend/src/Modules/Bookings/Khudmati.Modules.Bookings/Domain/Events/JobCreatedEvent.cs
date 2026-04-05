using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record JobCreatedEvent(Guid JobId, Guid CustomerId, string CategoryId) : INotification;
