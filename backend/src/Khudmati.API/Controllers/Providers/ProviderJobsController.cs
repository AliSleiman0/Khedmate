using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers.Application.Commands;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers.Providers;

[ApiController]
[Route("api/providers")]
[Authorize(Policy = "ProviderOnly")]
public class ProviderJobsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IProvidersRepository _providersRepo;
    private readonly IProviderLocationRepository _locationRepo;
    private readonly IWebHostEnvironment _env;
    private readonly AppDbContext _context;

    public ProviderJobsController(
        IMediator mediator,
        IProvidersRepository providersRepo,
        IProviderLocationRepository locationRepo,
        IWebHostEnvironment env,
        AppDbContext context)
    {
        _mediator = mediator;
        _providersRepo = providersRepo;
        _locationRepo = locationRepo;
        _env = env;
        _context = context;
    }

    private Guid GetProviderId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? User.FindFirstValue("sub")
               ?? throw new UnauthorizedAccessException("Missing sub claim.");
        return Guid.Parse(sub);
    }

    // GET /api/providers/jobs/available?page=1&pageSize=20
    [HttpGet("jobs/available")]
    public async Task<ActionResult<Result<AvailableJobsResultDto>>> GetAvailableJobs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var providerId = GetProviderId();

        var provider = await _providersRepo.GetByIdAsync(providerId, ct);
        if (provider is null) return NotFound();

        // Require at least phone verification
        if (provider.Tier == VerificationTier.Unverified)
            return StatusCode(403, Result<AvailableJobsResultDto>.Fail("PROVIDER_NOT_VERIFIED"));

        // Get provider's last known location (default to 0,0 if never set — shows no jobs)
        var location = await _locationRepo.GetByProviderIdAsync(providerId, ct);
        var lat = location is not null ? (double)location.Latitude : 0.0;
        var lng = location is not null ? (double)location.Longitude : 0.0;

        var result = await _mediator.Send(new GetAvailableJobsQuery(lat, lng, page, pageSize), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    // GET /api/providers/jobs/{jobId}
    [HttpGet("jobs/{jobId:guid}")]
    public async Task<ActionResult<Result<JobDetailForProviderDto>>> GetJobById(
        Guid jobId, CancellationToken ct)
    {
        var providerId = GetProviderId();

        var location = await _locationRepo.GetByProviderIdAsync(providerId, ct);
        var lat = location is not null ? (double)location.Latitude : 0.0;
        var lng = location is not null ? (double)location.Longitude : 0.0;

        var result = await _mediator.Send(new GetJobForProviderQuery(jobId, lat, lng), ct);
        if (!result.Success)
            return result.Error == "JOB_NO_LONGER_AVAILABLE"
                ? StatusCode(410, result)
                : NotFound(result);

        return Ok(result);
    }

    // POST /api/providers/jobs/{jobId}/respond
    [HttpPost("jobs/{jobId:guid}/respond")]
    public async Task<ActionResult<Result<RespondToJobResultDto>>> Respond(
        Guid jobId,
        [FromBody] RespondRequest request,
        CancellationToken ct)
    {
        var providerId = GetProviderId();

        var result = await _mediator.Send(
            new RespondToJobCommand(jobId, providerId, request.Action), ct);

        if (!result.Success)
            return result.Error == "JOB_NO_LONGER_AVAILABLE"
                ? StatusCode(410, result)
                : BadRequest(result);

        return Ok(result);
    }

    // POST /api/providers/location
    [HttpPost("location")]
    public async Task<ActionResult<Result<bool>>> UpdateLocation(
        [FromBody] UpdateLocationRequest request,
        CancellationToken ct)
    {
        var providerId = GetProviderId();
        var result = await _mediator.Send(
            new Khudmati.Modules.Providers.Application.Commands.UpdateProviderLocationCommand(providerId, request.Latitude, request.Longitude), ct);
        return Ok(result);
    }

    // GET /api/providers/jobs/active — provider's accepted/in-progress jobs
    [HttpGet("jobs/active")]
    public async Task<ActionResult<Result<IReadOnlyList<JobDetailForProviderDto>>>> GetActiveJobs(CancellationToken ct)
    {
        var providerId = GetProviderId();
        var location = await _locationRepo.GetByProviderIdAsync(providerId, ct);
        var lat = location is not null ? (double)location.Latitude : 0.0;
        var lng = location is not null ? (double)location.Longitude : 0.0;

        var result = await _mediator.Send(new GetActiveJobsByProviderQuery(providerId, lat, lng), ct);
        return Ok(result);
    }

    // POST /api/providers/jobs/{jobId}/advance
    [HttpPost("jobs/{jobId:guid}/advance")]
    public async Task<ActionResult<Result<AdvanceJobStatusResultDto>>> AdvanceJobStatus(
        Guid jobId, CancellationToken ct)
    {
        var providerId = GetProviderId();
        var result = await _mediator.Send(new AdvanceJobStatusCommand(jobId, providerId), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND"             => NotFound(result),
                "FORBIDDEN"                 => StatusCode(403, result),
                "INVALID_STATUS_TRANSITION" => BadRequest(result),
                "AFTER_PHOTO_REQUIRED"      => UnprocessableEntity(result),
                _                           => BadRequest(result)
            };
        }

        return Ok(result);
    }

    // POST /api/providers/jobs/{jobId}/after-photos
    [HttpPost("jobs/{jobId:guid}/after-photos")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<Result<IReadOnlyList<string>>>> UploadAfterPhotos(
        Guid jobId,
        IFormFileCollection files,
        CancellationToken ct)
    {
        var providerId = GetProviderId();

        // Verify job exists and belongs to this provider
        var jobResult = await _mediator.Send(new GetJobByIdForProviderQuery(jobId, providerId), ct);
        if (!jobResult.Success)
            return StatusCode(jobResult.Error == "FORBIDDEN" ? 403 : 404, jobResult);

        if (jobResult.Data!.Status != JobStatus.InProgress)
            return UnprocessableEntity(Result<IReadOnlyList<string>>.Fail("INVALID_JOB_STATUS"));

        if (files.Count == 0)
            return BadRequest(Result<IReadOnlyList<string>>.Fail("NO_FILES_PROVIDED"));

        var allowedTypes = new HashSet<string> { "image/jpeg", "image/png" };
        const long maxSize = 5 * 1024 * 1024; // 5 MB

        var savedUrls = new List<string>();
        var uploadDir = Path.Combine(
            _env.WebRootPath ?? "wwwroot", "uploads", "jobs", jobId.ToString(), "after");
        Directory.CreateDirectory(uploadDir);

        foreach (var file in files.Take(5))
        {
            if (!allowedTypes.Contains(file.ContentType))
                continue;
            if (file.Length > maxSize)
                continue;

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (ext != ".jpg" && ext != ".jpeg" && ext != ".png")
                continue;

            var fileName = $"{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(uploadDir, fileName);

            await using var stream = System.IO.File.Create(filePath);
            await file.CopyToAsync(stream, ct);

            savedUrls.Add($"/uploads/jobs/{jobId}/after/{fileName}");
        }

        if (savedUrls.Count > 0)
            await _mediator.Send(new AddJobPhotosCommand(jobId, savedUrls, "after"), ct);

        return Ok(Result<IReadOnlyList<string>>.Ok(savedUrls));
    }

    // GET /api/providers/me/jobs?status=Paid&page=1&pageSize=20 — provider's completed/paid jobs
    [HttpGet("me/jobs")]
    public async Task<IActionResult> GetMyCompletedJobs(
        [FromQuery] string status = "Paid",
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var providerId = GetProviderId();

        // Only Paid status is supported for this endpoint
        if (!string.Equals(status, "Paid", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { success = false, error = "UNSUPPORTED_STATUS_FILTER" });

        var categoryNames = new Dictionary<string, string>
        {
            ["plumbing"] = "سباكة",
            ["electrical"] = "كهرباء",
            ["cleaning"] = "تنظيف",
            ["carpentry"] = "نجارة",
            ["painting"] = "دهان",
            ["ac_maintenance"] = "تكييف"
        };

        var query = _context.Set<Job>()
            .Where(j => j.ProviderId == providerId && j.Status == JobStatus.Paid)
            .OrderByDescending(j => j.PaidAt);

        var total = await query.CountAsync(ct);

        var jobs = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var jobIds = jobs.Select(j => j.Id).ToList();

        // Left-join with transactions to get net amounts
        var transactions = await _context.Set<Transaction>()
            .Where(t => jobIds.Contains(t.JobId) && t.ProviderId == providerId)
            .ToListAsync(ct);

        var txByJobId = transactions.ToDictionary(t => t.JobId, t => t.NetAmount);

        var items = jobs.Select(j => new
        {
            jobId = j.Id,
            referenceNumber = j.ReferenceNumber,
            categoryId = j.CategoryId,
            categoryName = categoryNames.GetValueOrDefault(j.CategoryId, j.CategoryId),
            district = j.Address.Split('،', ',')[0].Trim(),
            netAmount = (double)(txByJobId.TryGetValue(j.Id, out var net) ? net : 0m),
            completedAt = j.PaidAt ?? j.UpdatedAt
        }).ToList();

        return Ok(new
        {
            success = true,
            data = new
            {
                items,
                total,
                page,
                pageSize,
                hasNextPage = (page * pageSize) < total
            }
        });
    }
}

public record RespondRequest(string Action);
public record UpdateLocationRequest(double Latitude, double Longitude);
