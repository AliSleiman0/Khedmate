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
        var refNumber = await _repo.GenerateReferenceNumberAsync(cancellationToken);

        var job = Job.Create(
            refNumber,
            request.CustomerId,
            request.CategoryId,
            request.Description,
            (decimal)request.Latitude,
            (decimal)request.Longitude,
            request.Address
        );

        await _repo.AddAsync(job, cancellationToken);

        if (request.PhotoUrls is { Count: > 0 })
        {
            foreach (var url in request.PhotoUrls.Take(3))
            {
                var photo = JobPhoto.Create(job.Id, url, "before");
                await _repo.AddPhotoAsync(photo, cancellationToken);
            }
        }

        await _repo.SaveChangesAsync(cancellationToken);

        return Result<JobDto>.Ok(ToDto(job, request.PhotoUrls ?? []));
    }

    private static JobDto ToDto(Job job, IReadOnlyList<string> beforePhotoUrls) =>
        new(
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
            beforePhotoUrls,
            [],
            job.CreatedAt,
            HasOpenDispute: false,
            TransactionStatus: null
        );
}
