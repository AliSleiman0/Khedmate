using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetUnreadMessageCountQuery(
    Guid JobId,
    Guid RequesterId,
    string RequesterType   // "customer" or "provider"
) : IRequest<Result<UnreadCountDto>>;

public class GetUnreadMessageCountQueryHandler : IRequestHandler<GetUnreadMessageCountQuery, Result<UnreadCountDto>>
{
    private readonly IBookingsRepository _bookingsRepo;
    private readonly IChatMessageRepository _chatRepo;

    public GetUnreadMessageCountQueryHandler(
        IBookingsRepository bookingsRepo,
        IChatMessageRepository chatRepo)
    {
        _bookingsRepo = bookingsRepo;
        _chatRepo = chatRepo;
    }

    public async Task<Result<UnreadCountDto>> Handle(
        GetUnreadMessageCountQuery request, CancellationToken cancellationToken)
    {
        var job = await _bookingsRepo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null)
            return Result<UnreadCountDto>.Fail("JOB_NOT_FOUND");

        var isCustomer = request.RequesterType == "customer" && job.CustomerId == request.RequesterId;
        var isProvider = request.RequesterType == "provider" && job.ProviderId == request.RequesterId;
        if (!isCustomer && !isProvider)
            return Result<UnreadCountDto>.Fail("FORBIDDEN");

        var count = await _chatRepo.GetUnreadCountAsync(
            request.JobId, request.RequesterType, cancellationToken);

        return Result<UnreadCountDto>.Ok(new UnreadCountDto(count));
    }
}
