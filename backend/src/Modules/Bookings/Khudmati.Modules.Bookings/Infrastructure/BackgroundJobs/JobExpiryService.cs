using Khudmati.Modules.Bookings.Application.Commands;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Bookings.Infrastructure.BackgroundJobs;

public class JobExpiryService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<JobExpiryService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(30);

    public JobExpiryService(IServiceScopeFactory scopeFactory, ILogger<JobExpiryService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(Interval, stoppingToken);
            await ExpireJobsAsync(stoppingToken);
        }
    }

    private async Task ExpireJobsAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<Infrastructure.Persistence.IBookingsRepository>();
        var mediator = scope.ServiceProvider.GetRequiredService<IMediator>();

        try
        {
            var expiredJobs = await repo.GetExpiredPendingJobsAsync(ct);
            foreach (var job in expiredJobs)
            {
                try
                {
                    await mediator.Send(new ExpireJobCommand(job.Id), ct);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to expire job {JobId}", job.Id);
                }
            }

            if (expiredJobs.Count > 0)
                _logger.LogInformation("Expired {Count} pending job(s)", expiredJobs.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in JobExpiryService");
        }
    }
}
