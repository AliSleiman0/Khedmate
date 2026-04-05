using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Commands;

public record AddJobPhotosCommand(Guid JobId, IReadOnlyList<string> Urls, string PhotoType = "before") : IRequest<Result<IReadOnlyList<string>>>;

public class AddJobPhotosCommandHandler : IRequestHandler<AddJobPhotosCommand, Result<IReadOnlyList<string>>>
{
    private readonly IBookingsRepository _repo;

    public AddJobPhotosCommandHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<IReadOnlyList<string>>> Handle(
        AddJobPhotosCommand request, CancellationToken cancellationToken)
    {
        foreach (var url in request.Urls)
        {
            var photo = JobPhoto.Create(request.JobId, url, request.PhotoType);
            await _repo.AddPhotoAsync(photo, cancellationToken);
        }

        await _repo.SaveChangesAsync(cancellationToken);

        return Result<IReadOnlyList<string>>.Ok(request.Urls);
    }
}
