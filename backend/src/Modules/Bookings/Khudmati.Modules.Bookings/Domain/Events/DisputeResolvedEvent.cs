using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record DisputeResolvedEvent(
    Guid DisputeId,
    Guid JobId,
    Guid CustomerId,
    Guid ProviderId,
    string Action,   // "approve_refund" | "reject"
    decimal Amount,
    string Currency
) : INotification;
