using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Application.Queries;

public record GetAllProvidersQuery(
    VerificationTier? Tier = null,
    string? CategoryId = null,
    int Page = 1,
    int PageSize = 20
) : IRequest<Result<(List<ProviderAdminDto> Providers, int Total)>>;

public class GetAllProvidersQueryHandler : IRequestHandler<GetAllProvidersQuery, Result<(List<ProviderAdminDto>, int)>>
{
    private readonly AppDbContext _context;

    public GetAllProvidersQueryHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Result<(List<ProviderAdminDto>, int)>> Handle(
        GetAllProvidersQuery request, CancellationToken cancellationToken)
    {
        var query = _context.Set<Khudmati.Modules.Providers.Domain.Entities.Provider>().AsQueryable();

        if (request.Tier.HasValue)
            query = query.Where(p => p.Tier == request.Tier.Value);

        if (!string.IsNullOrWhiteSpace(request.CategoryId))
            query = query.Where(p => p.ServiceCategories.Contains(request.CategoryId));

        var total = await query.CountAsync(cancellationToken);

        var providers = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(p => new ProviderAdminDto(
                p.Id,
                p.FullName,
                p.Phone,
                p.Email,
                p.Tier,
                p.ServiceCategories,
                p.Rating,
                p.JobsCompleted,
                p.CreatedAt
            ))
            .ToListAsync(cancellationToken);

        return Result<(List<ProviderAdminDto>, int)>.Ok((providers, total));
    }
}
