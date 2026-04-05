using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/bookings")]
[Authorize(Policy = "CustomerOnly")]
public class BookingsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IWebHostEnvironment _env;

    public BookingsController(IMediator mediator, IWebHostEnvironment env)
    {
        _mediator = mediator;
        _env = env;
    }

    private Guid GetCustomerId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? User.FindFirstValue("sub")
               ?? throw new UnauthorizedAccessException("Missing sub claim.");
        return Guid.Parse(sub);
    }

    // POST /api/bookings/jobs
    [HttpPost("jobs")]
    public async Task<ActionResult<Result<JobDto>>> CreateJob(
        [FromBody] CreateJobRequest request,
        CancellationToken ct)
    {
        var customerId = GetCustomerId();
        var command = new CreateJobCommand(
            customerId,
            request.CategoryId,
            request.Description,
            request.Latitude,
            request.Longitude,
            request.Address,
            request.PhotoUrls
        );

        var result = await _mediator.Send(command, ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    // GET /api/bookings/jobs/{jobId}
    [HttpGet("jobs/{jobId:guid}")]
    public async Task<ActionResult<Result<JobDto>>> GetJobById(Guid jobId, CancellationToken ct)
    {
        var customerId = GetCustomerId();
        var result = await _mediator.Send(new GetJobByIdQuery(jobId, customerId), ct);
        return result.Success ? Ok(result) : NotFound(result);
    }

    // GET /api/bookings/jobs?status=Pending&page=1&pageSize=10
    [HttpGet("jobs")]
    public async Task<ActionResult<Result<JobListDto>>> GetMyJobs(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken ct = default)
    {
        var customerId = GetCustomerId();

        JobStatus? statusFilter = null;
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<JobStatus>(status, true, out var parsed))
            statusFilter = parsed;

        var result = await _mediator.Send(
            new GetCustomerJobsQuery(customerId, statusFilter, page, pageSize), ct);

        return result.Success ? Ok(result) : BadRequest(result);
    }

    // POST /api/bookings/jobs/{jobId}/photos
    [HttpPost("jobs/{jobId:guid}/photos")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<Result<IReadOnlyList<string>>>> UploadPhotos(
        Guid jobId,
        IFormFileCollection files,
        CancellationToken ct)
    {
        var customerId = GetCustomerId();

        // Verify job belongs to customer
        var jobResult = await _mediator.Send(new GetJobByIdQuery(jobId, customerId), ct);
        if (!jobResult.Success)
            return NotFound(jobResult);

        if (files.Count == 0)
            return BadRequest(Result<IReadOnlyList<string>>.Fail("No files provided."));

        var allowedTypes = new HashSet<string> { "image/jpeg", "image/png" };
        const long maxSize = 5 * 1024 * 1024; // 5 MB

        var savedUrls = new List<string>();
        var uploadDir = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "jobs", jobId.ToString());
        Directory.CreateDirectory(uploadDir);

        foreach (var file in files.Take(3))
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

            savedUrls.Add($"/uploads/jobs/{jobId}/{fileName}");
        }

        // Persist photo records to DB
        if (savedUrls.Count > 0)
            await _mediator.Send(new AddJobPhotosCommand(jobId, savedUrls, "before"), ct);

        return Ok(Result<IReadOnlyList<string>>.Ok(savedUrls));
    }

    // POST /api/bookings/jobs/{jobId}/dispute
    [HttpPost("jobs/{jobId:guid}/dispute")]
    public async Task<IActionResult> RaiseDispute(
        Guid jobId,
        [FromBody] RaiseDisputeRequest request,
        CancellationToken ct)
    {
        var customerId = GetCustomerId();
        var result = await _mediator.Send(
            new OpenDisputeCommand(jobId, customerId, request.Complaint), ct);

        if (!result.Success)
        {
            return result.Error switch
            {
                "JOB_NOT_FOUND" => NotFound(new { success = false, error = result.Error }),
                _ => UnprocessableEntity(new { success = false, error = result.Error })
            };
        }

        return Ok(new { success = true, data = new { disputeId = result.Data!.DisputeId } });
    }
}
