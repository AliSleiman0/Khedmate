using FluentValidation;
using Khudmati.Modules.Customers.Application.Behaviors;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace Khudmati.Modules.Customers;

public static class CustomersModule
{
    public static IServiceCollection AddCustomersModule(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(typeof(CustomersModule).Assembly);
            cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
        });

        services.AddValidatorsFromAssembly(typeof(CustomersModule).Assembly);
        services.AddScoped<ICustomersRepository, CustomersRepository>();

        return services;
    }
}
