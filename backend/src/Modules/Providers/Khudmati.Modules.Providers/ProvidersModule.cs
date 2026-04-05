using FluentValidation;
using Khudmati.Modules.Providers.Application.Behaviors;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace Khudmati.Modules.Providers;

public static class ProvidersModule
{
    public static IServiceCollection AddProvidersModule(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(typeof(ProvidersModule).Assembly);
            cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
        });

        services.AddValidatorsFromAssembly(typeof(ProvidersModule).Assembly);
        services.AddScoped<IProvidersRepository, ProvidersRepository>();
        services.AddScoped<IProviderLocationRepository, ProviderLocationRepository>();
        services.AddScoped<IProviderRatingStatsRepository, ProviderRatingStatsRepository>();
        services.AddScoped<IDocumentSubmissionRepository, DocumentSubmissionRepository>();
        services.AddScoped<ISkillTestRepository, SkillTestRepository>();
        services.AddScoped<ITierHistoryRepository, TierHistoryRepository>();

        return services;
    }
}
