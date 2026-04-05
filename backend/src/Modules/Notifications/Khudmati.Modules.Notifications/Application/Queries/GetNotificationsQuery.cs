using Khudmati.Modules.Notifications.Application.DTOs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Notifications.Application.Queries;

public record GetNotificationsQuery(
    Guid RecipientId,
    string RecipientType,
    int Page,
    int PageSize) : IRequest<Result<NotificationsPageDto>>;

public record NotificationsPageDto(IReadOnlyList<NotificationDto> Items, int TotalCount);

public class GetNotificationsQueryHandler : IRequestHandler<GetNotificationsQuery, Result<NotificationsPageDto>>
{
    private readonly INotificationRepository _repo;

    public GetNotificationsQueryHandler(INotificationRepository repo) => _repo = repo;

    public async Task<Result<NotificationsPageDto>> Handle(GetNotificationsQuery request, CancellationToken cancellationToken)
    {
        var (items, totalCount) = await _repo.GetByRecipientAsync(
            request.RecipientId,
            request.RecipientType,
            request.Page,
            request.PageSize,
            cancellationToken);

        var dtos = items.Select(n => new NotificationDto(
            n.Id,
            n.RecipientId,
            n.RecipientType,
            n.Title,
            n.Body,
            n.IsRead,
            n.CreatedAt)).ToList();

        return Result<NotificationsPageDto>.Ok(new NotificationsPageDto(dtos, totalCount));
    }
}
