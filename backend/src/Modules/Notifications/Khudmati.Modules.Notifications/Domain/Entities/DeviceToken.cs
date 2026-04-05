using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Notifications.Domain.Entities;

public class DeviceToken : AuditableEntity
{
    public Guid OwnerId { get; private set; }
    public string OwnerType { get; private set; } = string.Empty; // "customer" | "provider"
    public string FcmToken { get; private set; } = string.Empty;
    public string Platform { get; private set; } = string.Empty;  // "android" | "ios"

    private DeviceToken() { }

    public static DeviceToken Create(Guid ownerId, string ownerType, string fcmToken, string platform) =>
        new() { OwnerId = ownerId, OwnerType = ownerType, FcmToken = fcmToken, Platform = platform };

    public void UpdateToken(string newToken)
    {
        FcmToken = newToken;
        SetUpdated();
    }
}
