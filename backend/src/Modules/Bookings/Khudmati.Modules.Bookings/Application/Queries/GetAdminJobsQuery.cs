using Khudmati.Modules.Bookings.Application.DTOs;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Bookings.Application.Queries;

public record GetAdminJobsQuery(
    string? Search,
    JobStatus? Status,
    DateTime? From,
    DateTime? To,
    int Page,
    int PageSize
) : IRequest<Result<AdminJobListResultDto>>;

public class GetAdminJobsQueryHandler : IRequestHandler<GetAdminJobsQuery, Result<AdminJobListResultDto>>
{
    private readonly IBookingsRepository _repo;

    public GetAdminJobsQueryHandler(IBookingsRepository repo) => _repo = repo;

    public async Task<Result<AdminJobListResultDto>> Handle(
        GetAdminJobsQuery request, CancellationToken cancellationToken)
    {
        var pageSize = Math.Min(request.PageSize, 50);
        var page = Math.Max(request.Page, 1);

        var (items, totalCount, stats) = await _repo.GetAdminJobsAsync(
            request.Search,
            request.Status,
            request.From,
            request.To,
            page,
            pageSize,
            cancellationToken);

        return Result<AdminJobListResultDto>.Ok(new AdminJobListResultDto(
            items,
            totalCount,
            page,
            pageSize,
            stats));
    }
}
