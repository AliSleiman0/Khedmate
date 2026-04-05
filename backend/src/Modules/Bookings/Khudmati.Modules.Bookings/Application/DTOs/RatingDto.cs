namespace Khudmati.Modules.Bookings.Application.DTOs;

public record RatingResponseDto(
    Guid RatingId,
    Guid JobId,
    bool IsPositive,
    DateTime SubmittedAt
);

public record PendingRatingDto(
    Guid JobId,
    string ReferenceNumber,
    string CategoryName,
    DateTime PaidAt,
    DateTime ExpiresAt,
    string RateTarget   // name of the person being rated
);

public record PendingRatingsResultDto(IReadOnlyList<PendingRatingDto> PendingRatings);
