using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record ExpireJobCommand(Guid JobId) : IRequest<Result<bool>>;

public class ExpireJobCommandHandler : IRequestHandler<ExpireJobCommand, Result<bool>>
{
    private readonly IBookingsRepository _repo;
    private readonly IMediator _mediator;

    public ExpireJobCommandHandler(IBookingsRepository repo, IMediator mediator)
    {
        _repo = repo;
        _mediator = mediator;
    }

    public async Task<Result<bool>> Handle(ExpireJobCommand request, CancellationToken cancellationToken)
    {
        var job = await _repo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null) return Result<bool>.Ok(false);

        job.MarkExpired();
        await _repo.SaveChangesAsync(cancellationToken);

        foreach (var evt in job.DomainEvents)
            await _mediator.Publish(evt, cancellationToken);

        return Result<bool>.Ok(true);
    }
}
