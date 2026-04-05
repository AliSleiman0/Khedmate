using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using Khudmati.Shared.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.Modules.Providers.Application.Queries;

public record GetVerificationQueueQuery(
    int Page = 1,
    int PageSize = 20
) : IRequest<Result<List<ProviderVerificationQueueDto>>>;

public class GetVerificationQueueQueryHandler : IRequestHandler<GetVerificationQueueQuery, Result<List<ProviderVerificationQueueDto>>>
{
    private readonly AppDbContext _context;

    public GetVerificationQueueQueryHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Result<List<ProviderVerificationQueueDto>>> Handle(
        GetVerificationQueueQuery request, CancellationToken cancellationToken)
    {
        var result = await (
            from submission in _context.Set<Khudmati.Modules.Providers.Domain.Entities.DocumentSubmission>()
            join provider in _context.Set<Khudmati.Modules.Providers.Domain.Entities.Provider>()
                on submission.ProviderId equals provider.Id
            where submission.Status == Domain.Enums.DocumentStatus.PendingReview
            orderby submission.SubmittedAt
            select new ProviderVerificationQueueDto(
                provider.Id,
                provider.FullName,
                provider.Phone,
                submission.DocumentType,
                submission.SubmittedAt,
                submission.Id
            )
        )
        .Skip((request.Page - 1) * request.PageSize)
        .Take(request.PageSize)
        .ToListAsync(cancellationToken);

        return Result<List<ProviderVerificationQueueDto>>.Ok(result);
    }
}
