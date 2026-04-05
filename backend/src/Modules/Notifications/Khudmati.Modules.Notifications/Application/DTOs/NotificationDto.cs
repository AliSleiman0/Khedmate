namespace Khudmati.Modules.Notifications.Application.DTOs;

public record NotificationDto(
    Guid Id,
    Guid RecipientId,
    string RecipientType,
    string Title,
    string Body,
    bool IsRead,
    DateTime CreatedAt
);
