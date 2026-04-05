using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Notifications.Application.Commands;

public record RegisterDeviceTokenCommand(
    Guid OwnerId,
    string OwnerType,
    string FcmToken,
    string Platform) : IRequest<Result>;

public class RegisterDeviceTokenCommandHandler : IRequestHandler<RegisterDeviceTokenCommand, Result>
{
    private readonly AppDbContext _context;

    public RegisterDeviceTokenCommandHandler(AppDbContext context) => _context = context;

    public async Task<Result> Handle(RegisterDeviceTokenCommand request, CancellationToken cancellationToken)
    {
        var existing = await _context.Set<DeviceToken>()
            .FirstOrDefaultAsync(
                t => t.OwnerId == request.OwnerId && t.Platform == request.Platform,
                cancellationToken);

        if (existing is not null)
        {
            existing.UpdateToken(request.FcmToken);
        }
        else
        {
            var token = DeviceToken.Create(
                request.OwnerId,
                request.OwnerType,
                request.FcmToken,
                request.Platform);

            await _context.Set<DeviceToken>().AddAsync(token, cancellationToken);
        }

        await _context.SaveChangesAsync(cancellationToken);
        return Result.Ok();
    }
}
