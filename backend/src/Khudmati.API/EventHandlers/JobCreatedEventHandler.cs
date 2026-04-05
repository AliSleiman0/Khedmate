using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.EventHandlers;

public class JobCreatedEventHandler : INotificationHandler<JobCreatedEvent>
{
    private static readonly Dictionary<string, string> CategoryNames = new()
    {
        ["plumbing"] = "سباكة",
        ["electrical"] = "كهرباء",
        ["cleaning"] = "تنظيف",
        ["carpentry"] = "نجارة",
        ["painting"] = "دهان",
        ["ac_maintenance"] = "تكييف"
    };

    private readonly IHubContext<JobHub> _hub;
    private readonly IBookingsRepository _repo;
    private readonly IPushNotificationService _push;
    private readonly AppDbContext _context;

    public JobCreatedEventHandler(
        IHubContext<JobHub> hub,
        IBookingsRepository repo,
        IPushNotificationService push,
        AppDbContext context)
    {
        _hub = hub;
        _repo = repo;
        _push = push;
        _context = context;
    }

    public async Task Handle(JobCreatedEvent notification, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(notification.JobId, cancellationToken);
        if (job is null) return;

        var secondsRemaining = Math.Max(0, (int)(job.ExpiresAt - DateTime.UtcNow).TotalSeconds);
        var categoryName = CategoryNames.GetValueOrDefault(job.CategoryId, job.CategoryId);
        var district = job.Address.Split('،', ',')[0].Trim();

        await _hub.Clients.Group("providers-available").SendAsync("NewJobAvailable", new
        {
            jobId = job.Id,
            categoryId = job.CategoryId,
            categoryName,
            district,
            secondsRemaining,
            latitude = (double)job.Latitude,
            longitude = (double)job.Longitude,
            postedAt = job.CreatedAt
        }, cancellationToken);

        // FCM fallback: push to all Active-tier providers with registered tokens
        var activeProviderIds = await _context.Set<Khudmati.Modules.Providers.Domain.Entities.Provider>()
            .Where(p => p.Tier == VerificationTier.Active)
            .Select(p => p.Id)
            .ToListAsync(cancellationToken);

        if (activeProviderIds.Count == 0) return;

        var pushTitle = "وظيفة جديدة قريبة منك! 🔔";
        var pushBody = $"{categoryName} — {district}";

        var deviceTokens = await _context.Set<DeviceToken>()
            .Where(t => t.OwnerType == "provider" && activeProviderIds.Contains(t.OwnerId))
            .ToListAsync(cancellationToken);

        foreach (var token in deviceTokens)
        {
            await _push.SendAsync(
                token.OwnerId,
                "provider",
                pushTitle,
                pushBody,
                new Dictionary<string, string>
                {
                    ["type"] = "new_job",
                    ["jobId"] = job.Id.ToString(),
                    ["categoryId"] = job.CategoryId
                },
                cancellationToken);
        }
    }
}
