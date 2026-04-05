using Xunit;
using FluentAssertions;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;

namespace Khudmati.Modules.Bookings.Tests;

public class JobTests
{
    [Fact]
    public void Create_SetsStatusToPending()
    {
        var job = Job.Create("KH-20260404-0001", Guid.NewGuid(), "cleaning", "Clean my house", 24.7m, 46.7m, "123 Main St");
        job.Status.Should().Be(JobStatus.Pending);
    }

    [Fact]
    public void Accept_FromPending_ChangesStatusToAccepted()
    {
        var job = Job.Create("KH-20260404-0002", Guid.NewGuid(), "plumbing", "Fix sink", 24.7m, 46.7m, "456 Oak Ave");
        var providerId = Guid.NewGuid();
        job.Accept(providerId);
        job.Status.Should().Be(JobStatus.Accepted);
        job.ProviderId.Should().Be(providerId);
    }

    [Fact]
    public void Accept_WhenAlreadyAccepted_Throws()
    {
        var job = Job.Create("KH-20260404-0003", Guid.NewGuid(), "painting", "Paint walls", 24.7m, 46.7m, "789 Pine Rd");
        job.Accept(Guid.NewGuid());
        var act = () => job.Accept(Guid.NewGuid());
        act.Should().Throw<InvalidOperationException>();
    }

    [Fact]
    public void FullWorkflow_TraversesAllStatuses()
    {
        var job = Job.Create("KH-20260404-0004", Guid.NewGuid(), "ac", "Install AC", 24.7m, 46.7m, "10 Market St");
        job.Accept(Guid.NewGuid());
        job.MarkEnRoute();
        job.MarkInProgress();
        job.MarkCompleted();
        job.MarkPaid();
        job.Status.Should().Be(JobStatus.Paid);
        job.DomainEvents.Should().HaveCount(5);
    }
}
