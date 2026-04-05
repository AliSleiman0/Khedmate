using FluentValidation;
using Khudmati.Modules.Bookings.Application.Behaviors;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace Khudmati.Modules.Bookings;

public static class BookingsModule
{
    public static IServiceCollection AddBookingsModule(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(typeof(BookingsModule).Assembly);
            cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
        });

        services.AddValidatorsFromAssembly(typeof(BookingsModule).Assembly);
        services.AddScoped<IBookingsRepository, BookingsRepository>();
        services.AddScoped<IRatingRepository, RatingRepository>();
        services.AddScoped<IChatMessageRepository, ChatMessageRepository>();

        return services;
    }
}
