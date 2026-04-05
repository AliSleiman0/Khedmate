using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Shared.Domain;
using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Entities;

public class Rating : AuditableEntity
{
    public Guid JobId { get; private set; }
    public Guid RaterId { get; private set; }
    public Guid RateeId { get; private set; }
    public string RaterType { get; private set; } = string.Empty; // "customer" or "provider"
    public bool IsPositive { get; private set; }
    public string[] Tags { get; private set; } = Array.Empty<string>();
    public DateTime SubmittedAt { get; private set; }

    private readonly List<INotification> _domainEvents = new();
    public IReadOnlyList<INotification> DomainEvents => _domainEvents.AsReadOnly();

    private Rating() { }

    public static Rating Create(
        Guid jobId,
        Guid raterId,
        Guid rateeId,
        string raterType,
        bool isPositive,
        string[] tags)
    {
        var rating = new Rating
        {
            JobId = jobId,
            RaterId = raterId,
            RateeId = rateeId,
            RaterType = raterType,
            IsPositive = isPositive,
            Tags = tags,
            SubmittedAt = DateTime.UtcNow
        };
        rating._domainEvents.Add(new RatingSubmittedEvent(
            rating.Id, jobId, rateeId, raterType, isPositive, tags));
        return rating;
    }
}
