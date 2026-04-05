using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;

namespace Khudmati.Modules.Payments.Application.Commands;

public record OnboardProviderStripeCommand(Guid ProviderId, string Email)
    : IRequest<Result<OnboardProviderStripeResult>>;

public record OnboardProviderStripeResult(string OnboardingUrl);

public class OnboardProviderStripeCommandHandler
    : IRequestHandler<OnboardProviderStripeCommand, Result<OnboardProviderStripeResult>>
{
    private readonly IPaymentsRepository _repo;
    private readonly IPaymentProvider _paymentProvider;

    public OnboardProviderStripeCommandHandler(IPaymentsRepository repo, IPaymentProvider paymentProvider)
    {
        _repo = repo;
        _paymentProvider = paymentProvider;
    }

    public async Task<Result<OnboardProviderStripeResult>> Handle(
        OnboardProviderStripeCommand request, CancellationToken cancellationToken)
    {
        var existing = await _repo.GetProviderStripeAccountAsync(request.ProviderId, cancellationToken);

        if (existing is null)
        {
            var result = await _paymentProvider.CreateOrGetProviderAccountAsync(
                request.ProviderId, request.Email, cancellationToken);

            var account = ProviderStripeAccount.Create(request.ProviderId, result.StripeAccountId);
            await _repo.AddProviderStripeAccountAsync(account, cancellationToken);
            await _repo.SaveChangesAsync(cancellationToken);

            return Result<OnboardProviderStripeResult>.Ok(
                new OnboardProviderStripeResult(result.OnboardingUrl));
        }

        // Re-generate onboarding link (existing account, not yet complete)
        var linkResult = await _paymentProvider.CreateOrGetProviderAccountAsync(
            request.ProviderId, request.Email, cancellationToken);

        return Result<OnboardProviderStripeResult>.Ok(
            new OnboardProviderStripeResult(linkResult.OnboardingUrl));
    }
}
