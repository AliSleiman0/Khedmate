using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record MarkMessagesReadCommand(
    Guid JobId,
    Guid ReaderId,
    string ReaderType   // "customer" or "provider"
) : IRequest<Result>;

public class MarkMessagesReadCommandHandler : IRequestHandler<MarkMessagesReadCommand, Result>
{
    private readonly IBookingsRepository _bookingsRepo;
    private readonly IChatMessageRepository _chatRepo;

    public MarkMessagesReadCommandHandler(
        IBookingsRepository bookingsRepo,
        IChatMessageRepository chatRepo)
    {
        _bookingsRepo = bookingsRepo;
        _chatRepo = chatRepo;
    }

    public async Task<Result> Handle(MarkMessagesReadCommand request, CancellationToken cancellationToken)
    {
        var job = await _bookingsRepo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null)
            return Result.Fail("JOB_NOT_FOUND");

        var isCustomer = request.ReaderType == "customer" && job.CustomerId == request.ReaderId;
        var isProvider = request.ReaderType == "provider" && job.ProviderId == request.ReaderId;
        if (!isCustomer && !isProvider)
            return Result.Fail("FORBIDDEN");

        // Mark messages sent by the other party as read
        await _chatRepo.MarkAsReadAsync(request.JobId, request.ReaderType, cancellationToken);
        await _chatRepo.SaveChangesAsync(cancellationToken);

        return Result.Ok();
    }
}
