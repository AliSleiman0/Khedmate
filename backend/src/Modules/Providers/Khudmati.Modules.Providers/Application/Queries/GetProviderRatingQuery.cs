using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Providers.Application.Queries;

public record ProviderRatingDto(
    int TotalRatings,
    int PositiveCount,
    int NegativeCount,
    decimal? PositiveRate,   // null when 0 ratings
    string[] TopTags,
    decimal? CompletionRate  // null when 0 jobs accepted
);

public record GetProviderRatingQuery(Guid ProviderId) : IRequest<Result<ProviderRatingDto>>;

public class GetProviderRatingQueryHandler
    : IRequestHandler<GetProviderRatingQuery, Result<ProviderRatingDto>>
{
    private readonly IProviderRatingStatsRepository _statsRepo;

    public GetProviderRatingQueryHandler(IProviderRatingStatsRepository statsRepo)
        => _statsRepo = statsRepo;

    public async Task<Result<ProviderRatingDto>> Handle(
        GetProviderRatingQuery request, CancellationToken cancellationToken)
    {
        var stats = await _statsRepo.GetByProviderIdAsync(request.ProviderId, cancellationToken);

        if (stats is null || stats.TotalRatings == 0)
        {
            return Result<ProviderRatingDto>.Ok(new ProviderRatingDto(
                TotalRatings: 0,
                PositiveCount: 0,
                NegativeCount: 0,
                PositiveRate: null,
                TopTags: Array.Empty<string>(),
                CompletionRate: null));
        }

        return Result<ProviderRatingDto>.Ok(new ProviderRatingDto(
            stats.TotalRatings,
            stats.PositiveCount,
            stats.NegativeCount,
            stats.PositiveRate,
            stats.TopTags,
            null));  // completionRate: future enhancement
    }
}
