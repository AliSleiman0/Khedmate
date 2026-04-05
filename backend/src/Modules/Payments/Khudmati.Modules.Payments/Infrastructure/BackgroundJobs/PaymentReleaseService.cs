using Khudmati.Modules.Payments.Application.Commands;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Khudmati.Modules.Payments.Infrastructure.BackgroundJobs;

/// <summary>
/// Polls every 5 minutes for Held transactions whose 24-hour dispute window has expired
/// and releases funds to the provider via Stripe Connect.
/// </summary>
public class PaymentReleaseService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<PaymentReleaseService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    public PaymentReleaseService(IServiceScopeFactory scopeFactory, ILogger<PaymentReleaseService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(Interval, stoppingToken);
            await ProcessReleasesAsync(stoppingToken);
        }
    }

    private async Task ProcessReleasesAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<IPaymentsRepository>();
        var mediator = scope.ServiceProvider.GetRequiredService<IMediator>();

        try
        {
            var readyToRelease = await repo.GetHeldReadyToReleaseAsync(ct);

            foreach (var transaction in readyToRelease)
            {
                try
                {
                    await mediator.Send(new ReleasePaymentCommand(transaction.Id), ct);
                }
                catch (Exception ex)
                {
                    // One failure must not stop the rest
                    _logger.LogError(ex,
                        "Failed to release payment for transaction {TransactionId}", transaction.Id);
                }
            }

            if (readyToRelease.Count > 0)
                _logger.LogInformation("Processed {Count} payment release(s)", readyToRelease.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in PaymentReleaseService");
        }
    }
}
