using FluentValidation;
using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Domain.Events;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record SendChatMessageCommand(
    Guid JobId,
    Guid SenderId,
    string SenderType,   // "customer" or "provider"
    string Text
) : IRequest<Result<SendMessageResponseDto>>;

public class SendChatMessageCommandValidator : AbstractValidator<SendChatMessageCommand>
{
    public SendChatMessageCommandValidator()
    {
        RuleFor(x => x.JobId).NotEmpty();
        RuleFor(x => x.SenderId).NotEmpty();
        RuleFor(x => x.SenderType)
            .Must(t => t == "customer" || t == "provider")
            .WithMessage("SenderType must be 'customer' or 'provider'.");
        RuleFor(x => x.Text)
            .NotEmpty().WithMessage("Message text cannot be empty.")
            .Must(t => !string.IsNullOrWhiteSpace(t)).WithMessage("Message text cannot be whitespace.")
            .MaximumLength(1000).WithMessage("MESSAGE_TOO_LONG");
    }
}

public class SendChatMessageCommandHandler : IRequestHandler<SendChatMessageCommand, Result<SendMessageResponseDto>>
{
    private static readonly HashSet<JobStatus> ChatOpenStatuses =
        [JobStatus.Accepted, JobStatus.EnRoute, JobStatus.InProgress];

    private readonly IBookingsRepository _bookingsRepo;
    private readonly IChatMessageRepository _chatRepo;
    private readonly IMediator _mediator;

    public SendChatMessageCommandHandler(
        IBookingsRepository bookingsRepo,
        IChatMessageRepository chatRepo,
        IMediator mediator)
    {
        _bookingsRepo = bookingsRepo;
        _chatRepo = chatRepo;
        _mediator = mediator;
    }

    public async Task<Result<SendMessageResponseDto>> Handle(
        SendChatMessageCommand request, CancellationToken cancellationToken)
    {
        var job = await _bookingsRepo.GetByIdAsync(request.JobId, cancellationToken);
        if (job is null)
            return Result<SendMessageResponseDto>.Fail("JOB_NOT_FOUND");

        // Verify caller is the customer or provider of this job
        var isCustomer = request.SenderType == "customer" && job.CustomerId == request.SenderId;
        var isProvider = request.SenderType == "provider" && job.ProviderId == request.SenderId;
        if (!isCustomer && !isProvider)
            return Result<SendMessageResponseDto>.Fail("FORBIDDEN");

        if (!ChatOpenStatuses.Contains(job.Status))
            return Result<SendMessageResponseDto>.Fail("CHAT_NOT_AVAILABLE");

        var message = ChatMessage.Create(
            request.JobId,
            request.SenderId,
            request.SenderType,
            request.Text.Trim()
        );

        await _chatRepo.AddAsync(message, cancellationToken);
        await _chatRepo.SaveChangesAsync(cancellationToken);

        // Publish event so API layer can fire SignalR to the other party
        await _mediator.Publish(new ChatMessageSentEvent(
            message.Id,
            job.Id,
            message.SenderId,
            message.SenderType,
            message.Text,
            message.SentAt,
            job.CustomerId,
            job.ProviderId!.Value
        ), cancellationToken);

        return Result<SendMessageResponseDto>.Ok(
            new SendMessageResponseDto(message.Id, message.Text, message.SentAt));
    }
}
