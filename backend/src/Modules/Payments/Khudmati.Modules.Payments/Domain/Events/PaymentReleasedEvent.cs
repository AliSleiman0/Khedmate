using MediatR;

namespace Khudmati.Modules.Payments.Domain.Events;

public record PaymentReleasedEvent(
    Guid JobId,
    Guid ProviderId,
    decimal NetAmount,
    string Currency) : INotification;
