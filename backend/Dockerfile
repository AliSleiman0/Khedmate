# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution + all .csproj files first for layer-caching of restore
COPY Khudmati.sln .
COPY src/Khudmati.API/Khudmati.API.csproj                                                         src/Khudmati.API/
COPY src/Khudmati.Shared/Khudmati.Shared.csproj                                                   src/Khudmati.Shared/
COPY src/Modules/Bookings/Khudmati.Modules.Bookings/Khudmati.Modules.Bookings.csproj              src/Modules/Bookings/Khudmati.Modules.Bookings/
COPY src/Modules/Customers/Khudmati.Modules.Customers/Khudmati.Modules.Customers.csproj          src/Modules/Customers/Khudmati.Modules.Customers/
COPY src/Modules/Providers/Khudmati.Modules.Providers/Khudmati.Modules.Providers.csproj          src/Modules/Providers/Khudmati.Modules.Providers/
COPY src/Modules/Payments/Khudmati.Modules.Payments/Khudmati.Modules.Payments.csproj             src/Modules/Payments/Khudmati.Modules.Payments/
COPY src/Modules/Notifications/Khudmati.Modules.Notifications/Khudmati.Modules.Notifications.csproj src/Modules/Notifications/Khudmati.Modules.Notifications/

RUN dotnet restore src/Khudmati.API/Khudmati.API.csproj

# Copy remaining source and publish
COPY . .
RUN dotnet publish src/Khudmati.API/Khudmati.API.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Create non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

COPY --from=build /app/publish .

# Uploads directory (mapped to a volume in production)
RUN mkdir -p /app/uploads && chown -R appuser:appgroup /app

USER appuser
EXPOSE 80

ENTRYPOINT ["dotnet", "Khudmati.API.dll"]
