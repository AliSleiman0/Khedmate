using Khudmati.Modules.Bookings.Domain.Enums;
using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record JobStatusChangedEvent(Guid JobId, Guid CustomerId, JobStatus From, JobStatus To) : INotification;
