namespace Khudmati.Modules.Notifications.Application;

public interface IPushNotificationService
{
    Task SendAsync(
        Guid recipientId,
        string recipientType,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken ct = default);
}
