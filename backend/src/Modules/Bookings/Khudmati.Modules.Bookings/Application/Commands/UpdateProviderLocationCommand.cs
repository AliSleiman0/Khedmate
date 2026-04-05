using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.SignalR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record UpdateProviderLocationCommand(
    Guid JobId,
    Guid ProviderId,
    double Latitude,
    double Longitude
) : IRequest<Result<bool>>;

public class UpdateProviderLocationCommandHandler : IRequestHandler<UpdateProviderLocationCommand, Result<bool>>
{
    private readonly IBookingsRepository _jobs;
    private readonly IProviderLocationRepository _locationRepo;
    private readonly IHubContext<JobHub> _hubContext;

    public UpdateProviderLocationCommandHandler(
        IBookingsRepository jobs,
        IProviderLocationRepository locationRepo,
        IHubContext<JobHub> hubContext)
    {
        _jobs = jobs;
        _locationRepo = locationRepo;
        _hubContext = hubContext;
    }

    public async Task<Result<bool>> Handle(UpdateProviderLocationCommand request, CancellationToken ct)
    {
        // Validate coordinates
        if (request.Latitude < -90 || request.Latitude > 90 ||
            request.Longitude < -180 || request.Longitude > 180)
            return Result<bool>.Fail("INVALID_COORDINATES");

        // Reject 0,0 coordinates (GPS initialization artifact)
        if (request.Latitude == 0 && request.Longitude == 0)
            return Result<bool>.Fail("INVALID_COORDINATES");

        var job = await _jobs.GetByIdAsync(request.JobId, ct);
        if (job is null || job.ProviderId != request.ProviderId)
            return Result<bool>.Fail("JOB_NOT_FOUND");

        if (job.Status != JobStatus.EnRoute)
            return Result<bool>.Fail("TRACKING_NOT_ACTIVE");

        // Upsert provider location
        await _locationRepo.UpsertAsync(
            request.ProviderId,
            (decimal)request.Latitude,
            (decimal)request.Longitude,
            ct);

        // Fire SignalR event to customer
        await _hubContext.Clients
            .Group($"customer-{job.CustomerId}")
            .SendAsync("ProviderLocationUpdated", new
            {
                JobId = job.Id,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Timestamp = DateTime.UtcNow
            }, ct);

        return Result<bool>.Ok(true);
    }
}
