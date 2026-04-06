using System.Text;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Khudmati.API.Domain;
using Khudmati.API.EventHandlers;
using Khudmati.API.Infrastructure;
using Khudmati.API.Services;
using Khudmati.Modules.Bookings;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Bookings.Infrastructure.BackgroundJobs;
using Khudmati.Modules.Customers;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Notifications;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure;
using Khudmati.Modules.Notifications.Infrastructure.Hubs;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Modules.Payments;
using Khudmati.Modules.Payments.Domain.Entities;
using Khudmati.Modules.Providers;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Application.Auth;
using Khudmati.Shared.Infrastructure;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// ── Entity model configuration (all modules + API-local entities) ─────────────
AppDbContext.AdditionalModelConfiguration = modelBuilder =>
{
    // Customers schema
    modelBuilder.Entity<Customer>(e =>
    {
        e.ToTable("accounts", "customers");
        e.HasIndex(x => x.Phone).IsUnique();
        e.HasIndex(x => x.Email).IsUnique().HasFilter("\"Email\" IS NOT NULL");
    });
    modelBuilder.Entity<OtpVerification>(e =>
    {
        e.ToTable("otp_verifications", "customers");
        e.HasOne<Customer>().WithMany().HasForeignKey(x => x.AccountId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });
    modelBuilder.Entity<CustomerRefreshToken>(e =>
    {
        e.ToTable("refresh_tokens", "customers");
        e.HasOne<Customer>().WithMany().HasForeignKey(x => x.AccountId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });

    // Referral codes (customers schema)
    modelBuilder.Entity<ReferralCode>(e =>
    {
        e.ToTable("referral_codes", "customers");
        e.HasIndex(x => x.CustomerId).IsUnique();
        e.HasIndex(x => x.Code).IsUnique();
        e.Property(x => x.Code).HasMaxLength(10);
    });

    // Referral uses (customers schema)
    modelBuilder.Entity<ReferralUse>(e =>
    {
        e.ToTable("referral_uses", "customers");
        e.HasIndex(x => x.ReferredCustomerId).IsUnique();
        e.HasIndex(x => x.ReferrerCustomerId);
        e.HasIndex(x => x.Status);
        e.Property(x => x.Status).HasMaxLength(20);
        e.Property(x => x.ReferrerCreditAmount).HasColumnType("decimal(10,2)");
        e.Property(x => x.RefereeDiscountPct).HasColumnType("decimal(5,2)");
    });

    // Customer credits (customers schema)
    modelBuilder.Entity<CustomerCredit>(e =>
    {
        e.ToTable("customer_credits", "customers");
        e.HasIndex(x => x.CustomerId);
        e.HasIndex(x => x.ExpiresAt);
        e.Property(x => x.Amount).HasColumnType("decimal(10,2)");
        e.Property(x => x.SourceType).HasMaxLength(30);
    });

    // Providers schema
    modelBuilder.Entity<Provider>(e =>
    {
        e.ToTable("accounts", "providers");
        e.HasIndex(x => x.Phone).IsUnique();
        e.HasIndex(x => x.Email).IsUnique().HasFilter("\"Email\" IS NOT NULL");
        e.Property(x => x.ServiceCategories).HasColumnType("text[]");
    });
    modelBuilder.Entity<ProviderOtpVerification>(e =>
    {
        e.ToTable("otp_verifications", "providers");
        e.HasOne<Provider>().WithMany().HasForeignKey(x => x.AccountId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });
    modelBuilder.Entity<ProviderRefreshToken>(e =>
    {
        e.ToTable("refresh_tokens", "providers");
        e.HasOne<Provider>().WithMany().HasForeignKey(x => x.AccountId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });

    // Admins schema
    modelBuilder.Entity<AdminAccount>(e =>
    {
        e.ToTable("accounts", "admins");
        e.HasIndex(x => x.Email).IsUnique();
    });
    modelBuilder.Entity<AdminRefreshToken>(e =>
    {
        e.ToTable("refresh_tokens", "admins");
        e.HasOne<AdminAccount>().WithMany().HasForeignKey(x => x.AccountId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });

    // Provider locations (providers schema)
    modelBuilder.Entity<ProviderLocation>(e =>
    {
        e.ToTable("locations", "providers");
        e.HasKey(x => x.ProviderId);
        e.Property(x => x.Latitude).HasColumnType("decimal(10,8)");
        e.Property(x => x.Longitude).HasColumnType("decimal(11,8)");
    });

    // Document submissions (providers schema)
    modelBuilder.Entity<DocumentSubmission>(e =>
    {
        e.ToTable("document_submissions", "providers");
        e.Property(x => x.DocumentType).HasConversion<string>().HasMaxLength(30);
        e.Property(x => x.FrontImageUrl).HasMaxLength(500);
        e.Property(x => x.BackImageUrl).HasMaxLength(500);
        e.Property(x => x.Status).HasConversion<string>().HasMaxLength(30);
        e.Property(x => x.RejectionReason).HasColumnType("text");
        e.HasIndex(x => x.ProviderId);
        e.HasIndex(x => x.Status);
    });

    // Skill test questions (providers schema)
    modelBuilder.Entity<SkillTestQuestion>(e =>
    {
        e.ToTable("skill_test_questions", "providers");
        e.Property(x => x.CategoryId).HasMaxLength(50);
        e.Property(x => x.QuestionText).HasColumnType("text");
        e.Property(x => x.OptionA).HasColumnType("text");
        e.Property(x => x.OptionB).HasColumnType("text");
        e.Property(x => x.OptionC).HasColumnType("text");
        e.Property(x => x.OptionD).HasColumnType("text");
        e.Property(x => x.CorrectKey).HasMaxLength(1);
        e.HasIndex(x => x.CategoryId);
        e.HasIndex(x => x.IsActive);
    });

    // Skill test sessions (providers schema)
    modelBuilder.Entity<SkillTestSession>(e =>
    {
        e.ToTable("skill_test_sessions", "providers");
        e.Property(x => x.CategoryId).HasMaxLength(50);
        e.Property(x => x.Status).HasConversion<string>().HasMaxLength(20);
        e.HasIndex(x => new { x.ProviderId, x.CategoryId });
        e.HasIndex(x => x.Status);
        e.HasIndex(x => x.NextRetryAt);
    });

    // Tier history (providers schema)
    modelBuilder.Entity<TierHistory>(e =>
    {
        e.ToTable("tier_history", "providers");
        e.Property(x => x.PreviousTier).HasConversion<string>().HasMaxLength(30);
        e.Property(x => x.NewTier).HasConversion<string>().HasMaxLength(30);
        e.Property(x => x.Reason).HasColumnType("text");
        e.HasIndex(x => x.ProviderId);
        e.HasIndex(x => x.ChangedAt).IsDescending();
    });

    // Bookings schema
    modelBuilder.Entity<Job>(e =>
    {
        e.ToTable("jobs", "bookings");
        e.Property(x => x.ReferenceNumber).HasMaxLength(20);
        e.HasIndex(x => x.ReferenceNumber).IsUnique();
        e.Property(x => x.CategoryId).HasMaxLength(50);
        e.Property(x => x.Description).HasColumnType("text");
        e.Property(x => x.Latitude).HasColumnType("decimal(10,8)");
        e.Property(x => x.Longitude).HasColumnType("decimal(11,8)");
        e.Property(x => x.Address).HasMaxLength(500);
        e.Property(x => x.Status)
            .HasConversion<string>()
            .HasMaxLength(30);
        e.HasIndex(x => x.CustomerId);
        e.HasIndex(x => x.Status);
        e.HasIndex(x => x.CreatedAt).IsDescending();
        e.HasIndex(x => x.ExpiresAt);
        e.HasMany(x => x.Photos).WithOne().HasForeignKey(p => p.JobId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
        e.Ignore(x => x.DomainEvents);
        e.Navigation(x => x.Photos).AutoInclude();
    });
    modelBuilder.Entity<JobPhoto>(e =>
    {
        e.ToTable("job_photos", "bookings");
        e.Property(x => x.Url).HasMaxLength(1000);
        e.Property(x => x.PhotoType).HasColumnName("photo_type").HasMaxLength(10);
    });
    modelBuilder.Entity<JobRejection>(e =>
    {
        e.ToTable("job_rejections", "bookings");
        e.HasIndex(x => x.JobId);
        e.HasIndex(x => x.ProviderId);
    });
    modelBuilder.Entity<JobStatusHistory>(e =>
    {
        e.ToTable("job_status_history", "bookings");
        e.Property(x => x.PreviousStatus).HasMaxLength(30);
        e.Property(x => x.NewStatus).HasMaxLength(30);
        e.HasIndex(x => x.JobId);
        // FK to bookings.jobs — cascade delete
        e.HasOne<Job>().WithMany().HasForeignKey(x => x.JobId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });

    // Ratings (bookings schema)
    modelBuilder.Entity<Rating>(e =>
    {
        e.ToTable("ratings", "bookings");
        e.Property(x => x.RaterType).HasMaxLength(20);
        e.Property(x => x.Tags).HasColumnType("text[]");
        e.HasIndex(x => x.RateeId);
        e.HasIndex(x => x.JobId);
        e.HasIndex(new[] { "JobId", "RaterType" }).IsUnique();
        e.HasOne<Job>().WithMany().HasForeignKey(x => x.JobId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
        e.Ignore(x => x.DomainEvents);
    });

    // Provider rating stats (providers schema — denormalised aggregate)
    modelBuilder.Entity<ProviderRatingStats>(e =>
    {
        e.ToTable("rating_stats", "providers");
        e.HasKey(x => x.ProviderId);
        e.Property(x => x.PositiveRate).HasColumnType("decimal(5,2)");
        e.Property(x => x.TopTags).HasColumnType("text[]");
    });

    // Payments schema
    modelBuilder.Entity<Transaction>(e =>
    {
        e.ToTable("transactions", "payments");
        e.HasIndex(x => x.JobId);
        e.HasIndex(x => x.CustomerId);
        e.HasIndex(x => x.ProviderId);
        e.HasIndex(x => x.Status);
        e.HasIndex(x => x.StripePaymentIntentId).IsUnique();
        e.Property(x => x.GrossAmount).HasColumnType("decimal(10,2)");
        e.Property(x => x.CommissionRate).HasColumnType("decimal(5,4)");
        e.Property(x => x.CommissionAmount).HasColumnType("decimal(10,2)");
        e.Property(x => x.NetAmount).HasColumnType("decimal(10,2)");
        e.Property(x => x.Currency).HasMaxLength(10);
        e.Property(x => x.Status).HasMaxLength(30);
        e.Property(x => x.StripePaymentIntentId).HasMaxLength(100);
        e.Property(x => x.StripeTransferId).HasMaxLength(100);
        e.Property(x => x.ReferralDiscountAmount).HasColumnType("decimal(10,2)");
        e.Property(x => x.CreditAppliedAmount).HasColumnType("decimal(10,2)");
    });
    modelBuilder.Entity<ProviderStripeAccount>(e =>
    {
        e.ToTable("provider_stripe_accounts", "payments");
        e.HasKey(x => x.ProviderId);
        e.HasIndex(x => x.StripeAccountId).IsUnique();
        e.Property(x => x.StripeAccountId).HasMaxLength(100);
        e.Property(x => x.OnboardingStatus).HasMaxLength(30);
    });

    // Notifications (public schema)
    modelBuilder.Entity<Notification>(e => e.ToTable("notifications"));
    modelBuilder.Entity<DeviceToken>(e =>
    {
        e.ToTable("device_tokens", "public");
        e.Property(x => x.OwnerType).HasMaxLength(20);
        e.Property(x => x.Platform).HasMaxLength(10);
        e.Property(x => x.FcmToken).HasMaxLength(500);
        e.HasIndex(x => new { x.OwnerId, x.Platform }).IsUnique();
    });

    // Chat messages (bookings schema)
    modelBuilder.Entity<ChatMessage>(e =>
    {
        e.ToTable("chat_messages", "bookings");
        e.Property(x => x.SenderType).HasMaxLength(20);
        e.Property(x => x.Text).HasColumnType("text");
        e.HasIndex(x => new { x.JobId, x.SentAt });
        e.HasIndex(x => new { x.JobId, x.ReadAt })
            .HasFilter("\"ReadAt\" IS NULL");
        e.HasOne<Job>().WithMany().HasForeignKey(x => x.JobId)
            .OnDelete(Microsoft.EntityFrameworkCore.DeleteBehavior.Cascade);
    });

    // Super admin tables (admins schema)
    modelBuilder.Entity<PlatformConfig>(e => { e.ToTable("platform_config", "admins"); });
    modelBuilder.Entity<AuditLogEntry>(e =>
    {
        e.ToTable("audit_log", "admins");
        e.HasIndex(x => x.AdminId);
        e.HasIndex(x => x.CreatedAt).IsDescending();
    });

    // Disputes (bookings schema)
    modelBuilder.Entity<Dispute>(e =>
    {
        e.ToTable("disputes", "bookings");
        e.HasKey(d => d.Id);
        e.Property(d => d.Complaint).HasColumnType("text").IsRequired();
        e.Property(d => d.AdminNote).HasColumnType("text");
        e.Property(d => d.Status).HasMaxLength(20).IsRequired();
        e.HasIndex(d => d.JobId);
        e.HasIndex(d => d.Status);
    });

    // Ensure the bookings schema and sequence exist (idempotent raw SQL via migration)
    // Sequence is created in the migration — not here.
};

// ── Database ─────────────────────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// ── Authentication / JWT ──────────────────────────────────────────────────────
var jwtSection = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtSection["Key"]!);

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opts =>
    {
        opts.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtSection["Issuer"],
            ValidateAudience = true,
            ValidAudiences = new[] { "customer", "provider", "admin", "superadmin" },
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateLifetime = true
        };

        opts.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var accessToken = ctx.Request.Query["access_token"];
                var path = ctx.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                    ctx.Token = accessToken;
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization(opts =>
{
    opts.AddPolicy("CustomerOnly", p => p.RequireClaim("aud", "customer"));
    opts.AddPolicy("ProviderOnly", p => p.RequireClaim("aud", "provider"));
    opts.AddPolicy("CustomerOrProvider", p => p.RequireClaim("aud", "customer", "provider"));
    opts.AddPolicy("AdminOnly", p => p.RequireClaim("aud", "admin"));
    opts.AddPolicy("AdminOrSuperAdmin", p => p.RequireClaim("aud", "admin", "superadmin"));
    opts.AddPolicy("SuperAdminOnly", p => p.RequireClaim("aud", "superadmin"));
});

// ── Grok AI Service ──────────────────────────────────────────────────────────
var grokApiKey = builder.Configuration["Grok:ApiKey"] ?? string.Empty;
builder.Services.AddHttpClient("grok", client =>
{
    client.BaseAddress = new Uri("https://api.x.ai");
    if (!string.IsNullOrEmpty(grokApiKey))
        client.DefaultRequestHeaders.Add("Authorization", $"Bearer {grokApiKey}");
});
builder.Services.AddScoped<IGrokService, GrokService>();

// ── Shared services ───────────────────────────────────────────────────────────
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.Configure<SmtpSettings>(builder.Configuration.GetSection("SmtpSettings"));
builder.Services.AddScoped<IOtpNotificationService, SmtpOtpNotificationService>();
builder.Services.AddScoped<IAdminRepository, AdminRepository>();

// ── Modules ───────────────────────────────────────────────────────────────────
builder.Services
    .AddBookingsModule()
    .AddCustomersModule()
    .AddProvidersModule()
    .AddPaymentsModule()
    .AddNotificationsModule();

// ── API-level MediatR handlers (SignalR event broadcasters) ───────────────────
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(JobCreatedEventHandler).Assembly));

// ── Background services ───────────────────────────────────────────────────────
builder.Services.AddHostedService<JobExpiryService>();

// ── SignalR ───────────────────────────────────────────────────────────────────
builder.Services.AddSignalR();

// ── Controllers + Swagger ─────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Khudmati API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

// ── CORS ──────────────────────────────────────────────────────────────────────
builder.Services.AddCors(opts =>
    opts.AddDefaultPolicy(p => p
        .WithOrigins("http://localhost:3000", "http://localhost:3001", "http://localhost:3002")
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials()));

// ── Firebase Admin SDK ────────────────────────────────────────────────────────
var firebaseSection = builder.Configuration.GetSection("Firebase");
var serviceAccountPath = firebaseSection["ServiceAccountPath"];
var credentialsJson = firebaseSection["CredentialsJson"];

if (FirebaseApp.DefaultInstance is null)
{
    try
    {
        GoogleCredential credential;
        if (!string.IsNullOrEmpty(credentialsJson) && credentialsJson.TrimStart().StartsWith("{\"type\""))
        {
            credential = GoogleCredential.FromJson(credentialsJson);
        }
        else if (!string.IsNullOrEmpty(serviceAccountPath) && File.Exists(serviceAccountPath))
        {
            credential = GoogleCredential.FromFile(serviceAccountPath);
        }
        else
        {
            // No valid Firebase credentials — skip init (push notifications unavailable)
            goto skipFirebase;
        }
        FirebaseApp.Create(new AppOptions { Credential = credential });
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[WARNING] Firebase init skipped: {ex.Message}");
    }
}
skipFirebase:

var app = builder.Build();

// ── Ensure DB schemas and sequences exist ─────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.ExecuteSqlRawAsync(@"
        CREATE SCHEMA IF NOT EXISTS bookings;
        CREATE SCHEMA IF NOT EXISTS customers;
        CREATE SCHEMA IF NOT EXISTS providers;
        CREATE SCHEMA IF NOT EXISTS admins;
        CREATE SCHEMA IF NOT EXISTS payments;
    ");
    await db.Database.ExecuteSqlRawAsync(@"
        CREATE SEQUENCE IF NOT EXISTS bookings.daily_job_seq START 1;
    ");
    // bookings.job_rejections table doesn't need a sequence
    await db.Database.EnsureCreatedAsync();
}

// ── Seed superadmin ───────────────────────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var adminRepo = scope.ServiceProvider.GetRequiredService<IAdminRepository>();
    var jwtSvc = scope.ServiceProvider.GetRequiredService<IJwtService>();
    if (!await adminRepo.AnyAdminExistsAsync())
    {
        var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var email = config["SeedAdmin:Email"] ?? "superadmin@khudmati.com";
        var password = config["SeedAdmin:Password"] ?? "Admin@12345";
        var hash = jwtSvc.HashPassword(password);
        var admin = AdminAccount.Create(email, hash, "superadmin");
        await adminRepo.AddAsync(admin);
        await adminRepo.SaveChangesAsync();
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<JobHub>("/hubs/jobs");
app.MapGet("/api/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

app.Run();
