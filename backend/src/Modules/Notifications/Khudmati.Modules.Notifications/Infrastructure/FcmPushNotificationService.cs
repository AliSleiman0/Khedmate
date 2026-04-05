using FirebaseAdmin.Messaging;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Notifications.Infrastructure;

public class FcmPushNotificationService : IPushNotificationService
{
    private readonly AppDbContext _context;
    private readonly ILogger<FcmPushNotificationService> _logger;

    public FcmPushNotificationService(AppDbContext context, ILogger<FcmPushNotificationService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task SendAsync(
        Guid recipientId,
        string recipientType,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken ct = default)
    {
        var tokens = await _context.Set<DeviceToken>()
            .Where(t => t.OwnerId == recipientId && t.OwnerType == recipientType)
            .ToListAsync(ct);

        if (tokens.Count == 0) return;

        var staleTokenIds = new List<Guid>();

        foreach (var deviceToken in tokens)
        {
            var message = new Message
            {
                Token = deviceToken.FcmToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data ?? new Dictionary<string, string>()
            };

            try
            {
                await FirebaseMessaging.DefaultInstance.SendAsync(message, ct);
            }
            catch (FirebaseMessagingException ex) when (
                ex.MessagingErrorCode == MessagingErrorCode.Unregistered ||
                ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument)
            {
                _logger.LogWarning("Stale FCM token removed for owner {OwnerId}: {Token}", recipientId, deviceToken.FcmToken);
                staleTokenIds.Add(deviceToken.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send FCM push to owner {OwnerId}", recipientId);
            }
        }

        if (staleTokenIds.Count > 0)
        {
            var staleEntities = tokens.Where(t => staleTokenIds.Contains(t.Id)).ToList();
            _context.Set<DeviceToken>().RemoveRange(staleEntities);
            await _context.SaveChangesAsync(ct);
        }
    }
}
