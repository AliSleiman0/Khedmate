using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Shared.Application;
using Khudmati.Shared.Domain;
using MediatR;

namespace Khudmati.Modules.Bookings.Domain.Entities;

public class Job : AuditableEntity
{
    public string ReferenceNumber { get; private set; } = string.Empty;
    public Guid CustomerId { get; private set; }
    public Guid? ProviderId { get; private set; }
    public string CategoryId { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public decimal Latitude { get; private set; }
    public decimal Longitude { get; private set; }
    public string Address { get; private set; } = string.Empty;
    public JobStatus Status { get; private set; } = JobStatus.Pending;
    public DateTime ExpiresAt { get; private set; }
    public DateTime? AcceptedAt { get; private set; }
    public DateTime? PaidAt { get; private set; }

    public List<JobPhoto> Photos { get; private set; } = new();

    private readonly List<INotification> _domainEvents = new();
    public IReadOnlyList<INotification> DomainEvents => _domainEvents.AsReadOnly();

    private Job() { }

    public static Job Create(
        string referenceNumber,
        Guid customerId,
        string categoryId,
        string description,
        decimal latitude,
        decimal longitude,
        string address)
    {
        var job = new Job
        {
            ReferenceNumber = referenceNumber,
            CustomerId = customerId,
            CategoryId = categoryId,
            Description = description,
            Latitude = latitude,
            Longitude = longitude,
            Address = address,
            Status = JobStatus.Pending,
            ExpiresAt = DateTime.UtcNow.AddMinutes(2)
        };
        job._domainEvents.Add(new JobCreatedEvent(job.Id, customerId, categoryId));
        return job;
    }

    public void Accept(Guid providerId)
    {
        EnsureStatus(JobStatus.Pending, JobStatus.Accepted);
        ProviderId = providerId;
        AcceptedAt = DateTime.UtcNow;
        Transition(JobStatus.Accepted);
        _domainEvents.Add(new JobAcceptedEvent(Id, CustomerId, providerId));
    }

    public void MarkExpired()
    {
        if (Status != JobStatus.Pending)
            throw new InvalidOperationException($"Cannot expire a job with status {Status}.");
        Status = JobStatus.Expired;
        SetUpdated();
        _domainEvents.Add(new JobExpiredEvent(Id, CustomerId));
    }

    /// <summary>Admin override — transitions Pending or Accepted jobs to Expired.</summary>
    public void AdminForceExpire()
    {
        if (Status != JobStatus.Pending && Status != JobStatus.Accepted)
            throw new InvalidOperationException($"Cannot force-cancel a job with status {Status}.");
        Status = JobStatus.Expired;
        SetUpdated();
        _domainEvents.Add(new JobExpiredEvent(Id, CustomerId));
    }

    public void MarkEnRoute()
    {
        EnsureStatus(JobStatus.Accepted, JobStatus.EnRoute);
        Transition(JobStatus.EnRoute);
    }

    public void MarkInProgress()
    {
        EnsureStatus(JobStatus.EnRoute, JobStatus.InProgress);
        Transition(JobStatus.InProgress);
    }

    public void MarkCompleted()
    {
        EnsureStatus(JobStatus.InProgress, JobStatus.Completed);
        Transition(JobStatus.Completed);
    }

    public void MarkPaid()
    {
        EnsureStatus(JobStatus.Completed, JobStatus.Paid);
        PaidAt = DateTime.UtcNow;
        Transition(JobStatus.Paid);
    }

    public Result<JobStatus> Advance()
    {
        JobStatus? next = Status switch
        {
            JobStatus.Accepted   => JobStatus.EnRoute,
            JobStatus.EnRoute    => JobStatus.InProgress,
            JobStatus.InProgress => JobStatus.Completed,
            _                    => (JobStatus?)null
        };

        if (next is null)
            return Result<JobStatus>.Fail($"Cannot advance job from '{Status}' status.");

        Transition(next.Value);
        return Result<JobStatus>.Ok(next.Value);
    }

    private void EnsureStatus(JobStatus required, JobStatus next)
    {
        if (Status != required)
            throw new InvalidOperationException(
                $"Cannot transition to {next}. Current status is {Status}, expected {required}.");
    }

    private void Transition(JobStatus next)
    {
        var prev = Status;
        Status = next;
        SetUpdated();
        _domainEvents.Add(new JobStatusChangedEvent(Id, CustomerId, prev, next));
    }
}
