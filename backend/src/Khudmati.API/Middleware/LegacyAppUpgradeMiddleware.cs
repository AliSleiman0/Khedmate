using System.Text.Json;

namespace Khudmati.API.Middleware;

/// <summary>
/// Phase 10 hard-cutover gate. Reads the <c>X-App-Package</c> header set by the
/// mobile clients; if the request is coming from one of the legacy bundle ids
/// (<c>com.khudmati.customer</c> / <c>com.khudmati.provider</c>) and the
/// <c>Auth:ForceUpgradeForLegacyApps</c> feature flag is on, returns
/// HTTP 426 Upgrade Required with a JSON body the mobile apps already
/// recognise (see <c>mobile/lib/core/api/api_client.dart</c> and the legacy
/// apps' matching interceptor).
///
/// Flip the flag to <c>true</c> only after the unified app is live in both
/// stores and the legacy apps have received their final "Download the new
/// Khudmati app" update — otherwise existing users lose access to the API
/// before they can install the replacement.
/// </summary>
public sealed class LegacyAppUpgradeMiddleware
{
    private static readonly HashSet<string> LegacyBundleIds = new(StringComparer.OrdinalIgnoreCase)
    {
        "com.khudmati.customer",
        "com.khudmati.provider",
    };

    private readonly RequestDelegate _next;
    private readonly ILogger<LegacyAppUpgradeMiddleware> _logger;

    public LegacyAppUpgradeMiddleware(
        RequestDelegate next,
        ILogger<LegacyAppUpgradeMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, IConfiguration configuration)
    {
        // Always let the health probe through so ops / load balancers
        // don't mark the service unhealthy if they send no package header.
        var path = context.Request.Path.Value;
        if (!string.IsNullOrEmpty(path) &&
            path.Equals("/api/health", StringComparison.OrdinalIgnoreCase))
        {
            await _next(context);
            return;
        }

        var flagEnabled = configuration.GetValue("Auth:ForceUpgradeForLegacyApps", false);
        if (!flagEnabled)
        {
            await _next(context);
            return;
        }

        var appPackage = context.Request.Headers["X-App-Package"].FirstOrDefault();
        if (string.IsNullOrEmpty(appPackage) || !LegacyBundleIds.Contains(appPackage))
        {
            await _next(context);
            return;
        }

        var storeUrl = configuration["Auth:UnifiedAndroidStoreUrl"]
            ?? "https://play.google.com/store/apps/details?id=com.khudmati.app";
        var iosStoreUrl = configuration["Auth:UnifiedIosStoreUrl"]
            ?? "https://apps.apple.com/app/khudmati/id000000000";

        _logger.LogInformation(
            "UPGRADE_REQUIRED blocked legacy bundle {Bundle} on {Path}",
            appPackage, path);

        context.Response.StatusCode = StatusCodes.Status426UpgradeRequired;
        context.Response.ContentType = "application/json; charset=utf-8";

        var payload = JsonSerializer.Serialize(new
        {
            success = false,
            error = "UPGRADE_REQUIRED",
            data = new
            {
                storeUrl,
                iosStoreUrl,
            },
        });

        await context.Response.WriteAsync(payload);
    }
}

public static class LegacyAppUpgradeMiddlewareExtensions
{
    public static IApplicationBuilder UseLegacyAppUpgradeGate(this IApplicationBuilder app)
    {
        return app.UseMiddleware<LegacyAppUpgradeMiddleware>();
    }
}
