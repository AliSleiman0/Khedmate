using Khudmati.Modules.Providers.Domain.Enums;
using MediatR;

namespace Khudmati.Modules.Providers.Domain.Events;

public record VerificationStatusChangedEvent(
    Guid ProviderId,
    VerificationTier NewTier,
    string Status,      // "Approved"or "Rejected"
    string? Message
) : INotification;
