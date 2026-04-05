namespace Khudmati.Modules.Bookings.Application.DTOs;

public record ChatMessageDto(
    Guid Id,
    Guid JobId,
    Guid SenderId,
    string SenderType,
    string Text,
    DateTime SentAt,
    bool IsRead
);

public record ChatMessagesPageDto(
    IReadOnlyList<ChatMessageDto> Messages,
    int TotalCount,
    int Page
);

public record SendMessageResponseDto(
    Guid Id,
    string Text,
    DateTime SentAt
);

public record UnreadCountDto(int UnreadCount);
