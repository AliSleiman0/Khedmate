using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.API.EventHandlers;

/// <summary>
/// Updates provider aggregate rating stats when a customer rates a provider.
/// Provider-to-customer ratings are not aggregated (no public customer score in V1).
/// </summary>
public class RatingSubmittedEventHandler : INotificationHandler<RatingSubmittedEvent>
{
    private readonly IProviderRatingStatsRepository _statsRepo;
    private readonly ILogger<RatingSubmittedEventHandler> _logger;

    public RatingSubmittedEventHandler(
        IProviderRatingStatsRepository statsRepo,
        ILogger<RatingSubmittedEventHandler> logger)
    {
        _statsRepo = statsRepo;
        _logger = logger;
    }

    public async Task Handle(RatingSubmittedEvent notification, CancellationToken cancellationToken)
    {
        if (notification.RaterType != "customer")
            return;  // Only aggregate customer→provider ratings

        try
        {
            await _statsRepo.UpsertRatingAsync(
                notification.RateeId,
                notification.IsPositive,
                notification.Tags,
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to update provider rating stats for provider {ProviderId} after rating {RatingId}.",
                notification.RateeId, notification.RatingId);
        }
    }
}
