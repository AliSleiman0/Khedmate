using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Events;

public record RatingSubmittedEvent(
    Guid RatingId,
    Guid JobId,
    Guid RateeId,
    string RaterType,   // "customer" or "provider"
    bool IsPositive,
    string[] Tags
) : INotification;
