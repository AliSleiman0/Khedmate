using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetChatMessagesQuery(
    Guid JobId,
    Guid RequesterId,
    string RequesterType,  // "customer" or "provider"
    int Page,
    int PageSize
) : IRequest<Result<ChatMessagesPageDto>>;

public class GetChatMessagesQueryHandler : IRequestHandler<GetChatMessagesQuery, Result<ChatMessagesPageDto>>
{
    private readonly IBookingsRepository _bookingsRepo;
    private readonly IChatMessageRepository _chatRepo;

    public GetChatMessagesQueryHandler(
        IBookingsRepository bookingsRepo,
        IChatMessageRepository chatRepo)
    {
        _bookingsRepo = bookingsRepo;
        _chatRepo = chatRepo;
    }

    public async Task<Result<ChatMessagesPageDto>> Handle(
        GetChatMessagesQuery request, CancellationToken cancellationToken)
    {
        var job = await _bookingsRepo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null)
            return Result<ChatMessagesPageDto>.Fail("JOB_NOT_FOUND");

        var isCustomer = request.RequesterType == "customer" && job.CustomerId == request.RequesterId;
        var isProvider = request.RequesterType == "provider" && job.ProviderId == request.RequesterId;
        if (!isCustomer && !isProvider)
            return Result<ChatMessagesPageDto>.Fail("FORBIDDEN");

        var (messages, total) = await _chatRepo.GetByJobIdAsync(
            request.JobId, request.Page, request.PageSize, cancellationToken);

        var dtos = messages.Select(m => new ChatMessageDto(
            m.Id,
            m.JobId,
            m.SenderId,
            m.SenderType,
            m.Text,
            m.SentAt,
            m.ReadAt.HasValue
        )).ToList();

        return Result<ChatMessagesPageDto>.Ok(
            new ChatMessagesPageDto(dtos, total, request.Page));
    }
}
