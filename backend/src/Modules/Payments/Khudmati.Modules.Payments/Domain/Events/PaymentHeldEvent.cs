using MediatR;

namespace Khudmati.Modules.Payments.Domain.Events;

public record PaymentHeldEvent(
    Guid JobId,
    Guid CustomerId,
    Guid ProviderId,
    decimal GrossAmount,
    DateTime HoldUntil) : INotification;
