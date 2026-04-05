using System.Security.Claims;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.Modules.Notifications.Infrastructure.Hubs;

[Authorize]
public class JobHub : Hub
{
    private readonly IProvidersRepository _providersRepo;

    public JobHub(IProvidersRepository providersRepo)
    {
        _providersRepo = providersRepo;
    }

    // Client-invocable: join/leave specific job groups
    public async Task JoinJobGroup(string jobId) =>
        await Groups.AddToGroupAsync(Context.ConnectionId, $"job-{jobId}");

    public async Task LeaveJobGroup(string jobId) =>
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"job-{jobId}");

    // Client-invocable: providers toggle availability
    public async Task JoinProvidersAvailable() =>
        await Groups.AddToGroupAsync(Context.ConnectionId, "providers-available");

    public async Task LeaveProvidersAvailable() =>
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, "providers-available");

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var audience = Context.User?.FindFirst("aud")?.Value;

        if (!string.IsNullOrEmpty(userId) && Guid.TryParse(userId, out var userGuid))
        {
            if (audience == "provider")
            {
                // Only Active tier providers can join the available pool
                var provider = await _providersRepo.GetByIdAsync(userGuid, CancellationToken.None);
                if (provider?.Tier == VerificationTier.Active)
                {
                    await Groups.AddToGroupAsync(Context.ConnectionId, "providers-available");
                }
                
                // All providers join their personal group for notifications
                await Groups.AddToGroupAsync(Context.ConnectionId, $"provider-{userId}");
            }
            else if (audience == "customer")
            {
                // Customers join their personal group for job status / payment notifications
                await Groups.AddToGroupAsync(Context.ConnectionId, $"customer-{userId}");
            }
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await base.OnDisconnectedAsync(exception);
    }
}
