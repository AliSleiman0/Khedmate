using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Notifications.Application.Commands;

public record MarkNotificationReadCommand(
    Guid NotificationId,
    Guid CallerId) : IRequest<Result>;

public class MarkNotificationReadCommandHandler : IRequestHandler<MarkNotificationReadCommand, Result>
{
    private readonly INotificationRepository _repo;

    public MarkNotificationReadCommandHandler(INotificationRepository repo) => _repo = repo;

    public async Task<Result> Handle(MarkNotificationReadCommand request, CancellationToken cancellationToken)
    {
        var notification = await _repo.GetByIdAsync(request.NotificationId, cancellationToken);
        if (notification is null)
            return Result.Fail("NOTIFICATION_NOT_FOUND");

        if (notification.RecipientId != request.CallerId)
            return Result.Fail("FORBIDDEN");

        notification.MarkRead();
        await _repo.SaveChangesAsync(cancellationToken);
        return Result.Ok();
    }
}
