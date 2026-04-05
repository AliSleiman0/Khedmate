# Backend Patterns — Khudmati .NET 8

All backend code lives under `backend/src/`. The project is a **modular monolith** — one ASP.NET Core host (`Khudmati.API`), multiple feature modules under `Modules/`.

---

## Module structure

```
backend/src/
├── Khudmati.API/
│   ├── Controllers/          ← one controller per module (or per domain area)
│   ├── Program.cs            ← ALL service registrations + EF model config
│   └── appsettings.json
├── Khudmati.Shared/
│   ├── Application/Result.cs ← Result<T> pattern
│   └── Infrastructure/Persistence/AppDbContext.cs
└── Modules/
    └── {ModuleName}/
        └── Khudmati.Modules.{ModuleName}/
            ├── Application/
            │   ├── Commands/   ← Command + Handler + Validator (same file or separate)
            │   ├── Queries/    ← Query + Handler
            │   └── DTOs/
            ├── Domain/
            │   ├── Entities/
            │   └── Enums/
            └── Infrastructure/
                └── Persistence/  ← IRepository interface + implementation
```

---

## Result\<T\> — the return type of every handler

File: `backend/src/Khudmati.Shared/Application/Result.cs`

```csharp
namespace Khudmati.Shared.Application;

public class Result<T>
{
    public bool Success { get; private set; }
    public T? Data { get; private set; }
    public string? Error { get; private set; }

    private Result() { }

    public static Result<T> Ok(T data) => new() { Success = true, Data = data };
    public static Result<T> Fail(string error) => new() { Success = false, Error = error };
}

public class Result
{
    public bool Success { get; private set; }
    public string? Error { get; private set; }

    private Result() { }

    public static Result Ok() => new() { Success = true };
    public static Result Fail(string error) => new() { Success = false, Error = error };
}
```

**Rules:**
- Handlers NEVER throw — catch exceptions and return `Result.Fail("ERROR_CODE")`.
- Error codes are `SCREAMING_SNAKE_CASE` strings (e.g. `"JOB_NOT_FOUND"`, `"INVALID_CREDENTIALS"`).
- Controllers map `result.Success` to HTTP status: `Ok(result)` / `BadRequest(result)` / `NotFound(result)`.

---

## CQRS — Command + Handler

```csharp
// Commands/CreateJobCommand.cs
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record CreateJobCommand(
    Guid CustomerId,
    string CategoryId,
    string Description,
    double Latitude,
    double Longitude,
    string Address,
    IReadOnlyList<string>? PhotoUrls
) : IRequest<Result<JobDto>>;

public class CreateJobCommandHandler : IRequestHandler<CreateJobCommand, Result<JobDto>>
{
    private readonly IBookingsRepository _repo;

    public CreateJobCommandHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<JobDto>> Handle(CreateJobCommand request, CancellationToken cancellationToken)
    {
        var job = Job.Create(
            request.CustomerId,
            request.CategoryId,
            request.Description,
            (decimal)request.Latitude,
            (decimal)request.Longitude,
            request.Address
        );

        await _repo.AddAsync(job, cancellationToken);
        await _repo.SaveChangesAsync(cancellationToken);

        return Result<JobDto>.Ok(new JobDto(job.Id, job.Status, job.CreatedAt));
    }
}
```

---

## CQRS — Query + Handler

```csharp
// Queries/GetJobByIdQuery.cs
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetJobByIdQuery(Guid JobId, Guid CustomerId) : IRequest<Result<JobDto>>;

public class GetJobByIdQueryHandler : IRequestHandler<GetJobByIdQuery, Result<JobDto>>
{
    private readonly IBookingsRepository _repo;

    public GetJobByIdQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<JobDto>> Handle(GetJobByIdQuery request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);

        // Don't leak existence of other customers' jobs
        if (job is null || job.CustomerId != request.CustomerId)
            return Result<JobDto>.Fail("JOB_NOT_FOUND");

        return Result<JobDto>.Ok(new JobDto(
            job.Id,
            job.ReferenceNumber,
            job.CustomerId,
            job.ProviderId,
            job.CategoryId,
            job.Description,
            job.Latitude,
            job.Longitude,
            job.Address,
            job.Status,
            job.Photos.Select(p => p.Url).ToList(),
            job.CreatedAt
        ));
    }
}
```

---

## FluentValidation — Validator

Each command gets a separate `*Validator.cs` in the same `Commands/` folder.

```csharp
// Commands/CreateJobCommandValidator.cs
using FluentValidation;

namespace Khudmati.Modules.Bookings.Application.Commands;

public class CreateJobCommandValidator : AbstractValidator<CreateJobCommand>
{
    private static readonly HashSet<string> ValidCategories =
        ["plumbing", "electrical", "cleaning", "carpentry", "painting", "ac_maintenance"];

    public CreateJobCommandValidator()
    {
        RuleFor(x => x.CategoryId)
            .NotEmpty()
            .Must(id => ValidCategories.Contains(id.ToLowerInvariant()))
            .WithMessage("CategoryId must be a valid service category.");

        RuleFor(x => x.Description)
            .NotEmpty()
            .MinimumLength(20)
            .MaximumLength(500);

        RuleFor(x => x.Latitude)
            .InclusiveBetween(-90, 90);

        RuleFor(x => x.Longitude)
            .InclusiveBetween(-180, 180);

        RuleFor(x => x.Address)
            .NotEmpty()
            .MaximumLength(500);
    }
}
```

Validators are auto-registered in `Program.cs` via:
```csharp
builder.Services.AddValidatorsFromAssemblyContaining<CreateJobCommandValidator>();
```
MediatR pipeline behaviour picks them up — no manual invocation needed.

---

## Repository — Interface + Implementation

**Rule:** DB access lives ONLY in the Infrastructure layer. Repositories use `_context.Set<T>()` — no `DbSet<T>` properties on `AppDbContext`.

```csharp
// Infrastructure/Persistence/BookingsRepository.cs

public interface IBookingsRepository
{
    Task<Job?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<(IReadOnlyList<Job> Jobs, int Total)> GetByCustomerIdAsync(
        Guid customerId, JobStatus? status, int page, int pageSize, CancellationToken ct = default);
    Task AddAsync(Job job, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
}

public class BookingsRepository : IBookingsRepository
{
    private readonly AppDbContext _context;

    public BookingsRepository(AppDbContext context) => _context = context;

    public async Task<Job?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _context.Set<Job>()
            .Include(j => j.Photos)
            .FirstOrDefaultAsync(j => j.Id == id, ct);

    public async Task<(IReadOnlyList<Job> Jobs, int Total)> GetByCustomerIdAsync(
        Guid customerId, JobStatus? status, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Set<Job>()
            .Include(j => j.Photos)
            .Where(j => j.CustomerId == customerId);

        if (status.HasValue)
            query = query.Where(j => j.Status == status.Value);

        var total = await query.CountAsync(ct);
        var jobs = await query
            .OrderByDescending(j => j.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (jobs, total);
    }

    public async Task AddAsync(Job job, CancellationToken ct = default) =>
        await _context.Set<Job>().AddAsync(job, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await _context.SaveChangesAsync(ct);
}
```

---

## Controller

```csharp
// Controllers/BookingsController.cs
using System.Security.Claims;
using Khudmati.Modules.Bookings.Application.Commands;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Application.Queries;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/bookings")]
[Authorize(Policy = "CustomerOnly")]          // ← audience-based policy
public class BookingsController : ControllerBase
{
    private readonly IMediator _mediator;

    public BookingsController(IMediator mediator) => _mediator = mediator;

    // Extract caller's GUID from JWT sub claim
    private Guid GetCustomerId() =>
        Guid.Parse(
            User.FindFirstValue(ClaimTypes.NameIdentifier)
         ?? User.FindFirstValue("sub")
         ?? throw new UnauthorizedAccessException("Missing sub claim."));

    [HttpPost("jobs")]
    public async Task<ActionResult<Result<JobDto>>> CreateJob(
        [FromBody] CreateJobRequest request, CancellationToken ct)
    {
        var result = await _mediator.Send(
            new CreateJobCommand(GetCustomerId(), request.CategoryId,
                request.Description, request.Latitude, request.Longitude,
                request.Address, request.PhotoUrls), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpGet("jobs/{jobId:guid}")]
    public async Task<ActionResult<Result<JobDto>>> GetJobById(Guid jobId, CancellationToken ct)
    {
        var result = await _mediator.Send(new GetJobByIdQuery(jobId, GetCustomerId()), ct);
        return result.Success ? Ok(result) : NotFound(result);
    }

    [HttpGet("jobs")]
    public async Task<ActionResult<Result<JobListDto>>> GetMyJobs(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken ct = default)
    {
        JobStatus? statusFilter = null;
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<JobStatus>(status, true, out var parsed))
            statusFilter = parsed;

        var result = await _mediator.Send(
            new GetCustomerJobsQuery(GetCustomerId(), statusFilter, page, pageSize), ct);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
```

**Auth policies available (defined in Program.cs):**
```csharp
opts.AddPolicy("CustomerOnly",        p => p.RequireClaim("aud", "customer"));
opts.AddPolicy("ProviderOnly",        p => p.RequireClaim("aud", "provider"));
opts.AddPolicy("AdminOnly",           p => p.RequireClaim("aud", "admin"));
opts.AddPolicy("SuperAdminOnly",      p => p.RequireClaim("aud", "superadmin"));
opts.AddPolicy("CustomerOrProvider",  p => p.RequireClaim("aud", "customer", "provider"));
```

---

## AppDbContext

File: `backend/src/Khudmati.Shared/Infrastructure/Persistence/AppDbContext.cs`

```csharp
public class AppDbContext : DbContext
{
    public static Action<ModelBuilder>? AdditionalModelConfiguration { get; set; }

    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("public");
        AdditionalModelConfiguration?.Invoke(modelBuilder);
        base.OnModelCreating(modelBuilder);
    }
}
```

**Entity configuration goes in `Program.cs` inside `AdditionalModelConfiguration`, NOT in the entity class or a separate `IEntityTypeConfiguration`.**

```csharp
// In Program.cs
AppDbContext.AdditionalModelConfiguration = modelBuilder =>
{
    modelBuilder.Entity<Job>(e =>
    {
        e.ToTable("jobs", "bookings");            // schema-per-module
        e.Property(x => x.Status)
            .HasConversion<string>()
            .HasMaxLength(30);
        e.HasIndex(x => x.CustomerId);
        e.HasMany(x => x.Photos).WithOne().HasForeignKey(p => p.JobId)
            .OnDelete(DeleteBehavior.Cascade);
        e.Ignore(x => x.DomainEvents);           // ignore domain events collection
    });

    // Add ALL new entities here — one block per entity
    modelBuilder.Entity<NewEntity>(e =>
    {
        e.ToTable("table_name", "schema_name");
        // ... columns, indexes, relationships
    });
};
```

---

## DB Schema Convention

Each module owns its own PostgreSQL schema:

| Module | Schema |
|--------|--------|
| Customers | `customers` |
| Providers | `providers` |
| Bookings | `bookings` |
| Payments | `payments` |
| Notifications / shared | `public` |

New tables always go in the owning module's schema.

---

## Migrations

Run from solution root:
```bash
cd backend
dotnet ef migrations add MigrationName --project src/Khudmati.API --startup-project src/Khudmati.API
dotnet ef database update --project src/Khudmati.API --startup-project src/Khudmati.API
```

The migration files land in `backend/src/Khudmati.API/Migrations/`.

---

## Module Service Registration

Each module's services are registered in `Program.cs`:

```csharp
// Repositories
builder.Services.AddScoped<IBookingsRepository, BookingsRepository>();
builder.Services.AddScoped<INewModuleRepository, NewModuleRepository>();

// MediatR — add new module assemblies here if the handler is in a new project
builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(CreateJobCommand).Assembly);
    cfg.RegisterServicesFromAssembly(typeof(SomeNewCommand).Assembly);
    // ...
});
```

---

## Domain Entity Pattern

```csharp
// Domain/Entities/Job.cs
namespace Khudmati.Modules.Bookings.Domain.Entities;

public class Job
{
    public Guid Id { get; private set; }
    public string ReferenceNumber { get; private set; } = default!;
    public Guid CustomerId { get; private set; }
    public Guid? ProviderId { get; private set; }
    public string CategoryId { get; private set; } = default!;
    public string Description { get; private set; } = default!;
    public decimal Latitude { get; private set; }
    public decimal Longitude { get; private set; }
    public string Address { get; private set; } = default!;
    public JobStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? AcceptedAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }

    private readonly List<JobPhoto> _photos = [];
    public IReadOnlyList<JobPhoto> Photos => _photos.AsReadOnly();

    // Domain events (ignored by EF, dispatched by MediatR pipeline)
    private readonly List<object> _domainEvents = [];
    public IReadOnlyList<object> DomainEvents => _domainEvents.AsReadOnly();

    private Job() { } // EF constructor

    public static Job Create(string refNumber, Guid customerId, string categoryId,
        string description, decimal latitude, decimal longitude, string address)
    {
        return new Job
        {
            Id = Guid.NewGuid(),
            ReferenceNumber = refNumber,
            CustomerId = customerId,
            CategoryId = categoryId,
            Description = description,
            Latitude = latitude,
            Longitude = longitude,
            Address = address,
            Status = JobStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(2), // 2-min acceptance window
        };
    }

    public void Accept(Guid providerId)
    {
        if (Status != JobStatus.Pending) throw new InvalidOperationException("Job is not pending.");
        ProviderId = providerId;
        Status = JobStatus.Accepted;
        AcceptedAt = DateTime.UtcNow;
        _domainEvents.Add(new JobAcceptedEvent(Id, providerId));
    }
}
```

---

## SignalR — firing events

Inject `IHubContext<AppHub>` into a handler or event handler:

```csharp
public class JobCreatedEventHandler : INotificationHandler<JobCreatedEvent>
{
    private readonly IHubContext<AppHub> _hub;

    public JobCreatedEventHandler(IHubContext<AppHub> hub) => _hub = hub;

    public async Task Handle(JobCreatedEvent notification, CancellationToken ct)
    {
        await _hub.Clients.Group("providers-available")
            .SendAsync("NewJobAvailable", new
            {
                jobId = notification.JobId,
                categoryId = notification.CategoryId,
                distanceKm = notification.DistanceKm,
            }, ct);
    }
}
```

**SignalR groups:**
- `providers-available` — all online Active-tier providers
- `customer-{customerId}` — per-customer personal group
- `provider-{providerId}` — per-provider personal group
- `job-{jobId}` — per-job group
