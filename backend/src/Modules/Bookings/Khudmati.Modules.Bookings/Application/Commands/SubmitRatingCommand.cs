using FluentValidation;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record SubmitRatingCommand(
    Guid JobId,
    Guid RaterId,
    string RaterType,   // "customer" or "provider"
    bool IsPositive,
    IReadOnlyList<string> Tags
) : IRequest<Result<RatingResponseDto>>;

public class SubmitRatingCommandValidator : AbstractValidator<SubmitRatingCommand>
{
    public SubmitRatingCommandValidator()
    {
        RuleFor(x => x.JobId).NotEmpty();
        RuleFor(x => x.RaterId).NotEmpty();
        RuleFor(x => x.RaterType)
            .Must(t => t == "customer" || t == "provider")
            .WithMessage("RaterType must be 'customer' or 'provider'.");
    }
}

public class SubmitRatingCommandHandler : IRequestHandler<SubmitRatingCommand, Result<RatingResponseDto>>
{
    private static readonly IReadOnlySet<string> CustomerTags = new HashSet<string>
    {
        "arrived_on_time", "clean_worksite", "fair_pricing", "professional", "would_recommend"
    };

    private static readonly IReadOnlySet<string> ProviderTags = new HashSet<string>
    {
        "easy_to_deal_with", "described_problem_accurately", "paid_promptly"
    };

    private readonly IBookingsRepository _repo;
    private readonly IRatingRepository _ratingRepo;
    private readonly IMediator _mediator;
    private readonly ILogger<SubmitRatingCommandHandler> _logger;

    public SubmitRatingCommandHandler(
        IBookingsRepository repo,
        IRatingRepository ratingRepo,
        IMediator mediator,
        ILogger<SubmitRatingCommandHandler> logger)
    {
        _repo = repo;
        _ratingRepo = ratingRepo;
        _mediator = mediator;
        _logger = logger;
    }

    public async Task<Result<RatingResponseDto>> Handle(
        SubmitRatingCommand request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null)
            return Result<RatingResponseDto>.Fail("JOB_NOT_FOUND");

        // Validate ownership
        var isOwner = request.RaterType == "customer"
            ? job.CustomerId == request.RaterId
            : job.ProviderId == request.RaterId;

        if (!isOwner)
            return Result<RatingResponseDto>.Fail("JOB_NOT_FOUND");

        // Job must be Paid
        if (job.Status != JobStatus.Paid)
            return Result<RatingResponseDto>.Fail("JOB_NOT_ELIGIBLE_FOR_RATING");

        // Check PaidAt exists and is within 48h window
        if (job.PaidAt is null)
        {
            _logger.LogWarning("Job {JobId} has no PaidAt timestamp — treating as ineligible.", job.Id);
            return Result<RatingResponseDto>.Fail("JOB_NOT_ELIGIBLE_FOR_RATING");
        }

        if (job.PaidAt.Value.AddHours(48) < DateTime.UtcNow)
            return Result<RatingResponseDto>.Fail("RATING_WINDOW_EXPIRED");

        // Check for duplicate rating
        var existing = await _ratingRepo.GetByJobAndRaterTypeAsync(
            request.JobId, request.RaterType, cancellationToken);

        if (existing is not null)
            return Result<RatingResponseDto>.Fail("ALREADY_RATED");

        // Filter tags to allowed set for the rater type (silently ignore unknown)
        var allowedTags = request.RaterType == "customer" ? CustomerTags : ProviderTags;
        var filteredTags = request.Tags
            .Where(t => allowedTags.Contains(t))
            .Distinct()
            .ToArray();

        // Determine rateeId
        var rateeId = request.RaterType == "customer"
            ? job.ProviderId!.Value
            : job.CustomerId;

        var rating = Rating.Create(
            request.JobId,
            request.RaterId,
            rateeId,
            request.RaterType,
            request.IsPositive,
            filteredTags);

        await _ratingRepo.AddAsync(rating, cancellationToken);
        await _ratingRepo.SaveChangesAsync(cancellationToken);

        // Publish domain events (triggers provider stats update for customer ratings)
        foreach (var evt in rating.DomainEvents)
            await _mediator.Publish(evt, cancellationToken);

        return Result<RatingResponseDto>.Ok(new RatingResponseDto(
            rating.Id,
            rating.JobId,
            rating.IsPositive,
            rating.SubmittedAt));
    }
}
