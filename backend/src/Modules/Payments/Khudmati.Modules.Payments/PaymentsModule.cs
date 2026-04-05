using Khudmati.Modules.Payments.Application;
using Khudmati.Modules.Payments.Infrastructure.BackgroundJobs;
using Khudmati.Modules.Payments.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Infrastructure.Stripe;
using Microsoft.Extensions.DependencyInjection;

namespace Khudmati.Modules.Payments;

public static class PaymentsModule
{
    public static IServiceCollection AddPaymentsModule(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
            cfg.RegisterServicesFromAssembly(typeof(PaymentsModule).Assembly));

        services.AddScoped<IPaymentsRepository, PaymentsRepository>();
        services.AddScoped<IPaymentProvider, StripePaymentProvider>();

        services.AddHostedService<PaymentReleaseService>();

        return services;
    }
}
