using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Infrastructure;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace Khudmati.Modules.Notifications;

public static class NotificationsModule
{
    public static IServiceCollection AddNotificationsModule(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
            cfg.RegisterServicesFromAssembly(typeof(NotificationsModule).Assembly));

        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<IPushNotificationService, FcmPushNotificationService>();

        return services;
    }
}
