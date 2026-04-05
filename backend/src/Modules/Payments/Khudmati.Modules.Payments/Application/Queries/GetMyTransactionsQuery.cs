using Khudmati.Modules.Payments.Application.DTOs;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Payments.Application.Queries;

public record GetMyTransactionsQuery(
    Guid UserId,
    string Audience,   // "customer" | "provider"
    int Page,
    int PageSize) : IRequest<Result<PagedTransactionsDto>>;

public record PagedTransactionsDto(IReadOnlyList<TransactionDto> Items, int Total, int Page, int PageSize);

public class GetMyTransactionsQueryHandler
    : IRequestHandler<GetMyTransactionsQuery, Result<PagedTransactionsDto>>
{
    private readonly IPaymentsRepository _repo;

    public GetMyTransactionsQueryHandler(IPaymentsRepository repo) => _repo = repo;

    public async Task<Result<PagedTransactionsDto>> Handle(
        GetMyTransactionsQuery request, CancellationToken cancellationToken)
    {
        var (items, total) = request.Audience == "customer"
            ? await _repo.GetByCustomerIdPagedAsync(request.UserId, request.Page, request.PageSize, cancellationToken)
            : await _repo.GetByProviderIdPagedAsync(request.UserId, request.Page, request.PageSize, cancellationToken);

        var dtos = items.Select(t => new TransactionDto(
            t.Id, t.JobId, t.CustomerId, t.ProviderId,
            t.GrossAmount, t.CommissionAmount, t.NetAmount,
            t.Currency, t.Status, t.HoldUntil, t.CreatedAt)).ToList();

        return Result<PagedTransactionsDto>.Ok(
            new PagedTransactionsDto(dtos, total, request.Page, request.PageSize));
    }
}
