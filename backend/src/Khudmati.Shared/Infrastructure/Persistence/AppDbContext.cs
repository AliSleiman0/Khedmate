using Microsoft.EntityFrameworkCore;

namespace Khudmati.Shared.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    // Delegate invoked after base OnModelCreating — used by the API layer (and modules)
    // to register entities and their schema configuration without creating circular references.
    public static Action<ModelBuilder>? AdditionalModelConfiguration { get; set; }

    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("public");

        AdditionalModelConfiguration?.Invoke(modelBuilder);

        base.OnModelCreating(modelBuilder);
    }
}
