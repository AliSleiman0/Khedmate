namespace Khudmati.API.Domain;

/// <summary>
/// Service-category master record. Mobile + admin both read this; jobs,
/// providers, skill_test_questions, and reminder_rules reference the
/// <see cref="Slug"/> as a free-text value (no FK — validation is
/// application-level so historical rows continue to resolve labels even
/// after a category is soft-deleted).
/// </summary>
public class ServiceCategory
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public string Slug { get; private set; } = string.Empty;
    public string NameEn { get; private set; } = string.Empty;
    public string NameAr { get; private set; } = string.Empty;
    public string IconKey { get; private set; } = "category";
    public string? IconUrl { get; private set; }
    public int DisplayOrder { get; private set; } = 100;
    public bool IsActive { get; private set; } = true;
    public bool RequiresSkillTest { get; private set; } = true;
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; private set; } = DateTime.UtcNow;
    public Guid? CreatedBy { get; private set; }

    private ServiceCategory() { }

    public static ServiceCategory Create(
        string slug,
        string nameEn,
        string nameAr,
        string iconKey,
        int displayOrder,
        bool requiresSkillTest,
        Guid? createdBy)
    {
        return new ServiceCategory
        {
            Slug = slug,
            NameEn = nameEn,
            NameAr = nameAr,
            IconKey = iconKey,
            DisplayOrder = displayOrder,
            RequiresSkillTest = requiresSkillTest,
            IsActive = false,
            CreatedBy = createdBy,
        };
    }

    public void UpdateDetails(
        string? slug,
        string? nameEn,
        string? nameAr,
        string? iconKey,
        int? displayOrder,
        bool? requiresSkillTest)
    {
        if (slug is not null) Slug = slug;
        if (nameEn is not null) NameEn = nameEn;
        if (nameAr is not null) NameAr = nameAr;
        if (iconKey is not null) IconKey = iconKey;
        if (displayOrder is not null) DisplayOrder = displayOrder.Value;
        if (requiresSkillTest is not null) RequiresSkillTest = requiresSkillTest.Value;
        UpdatedAt = DateTime.UtcNow;
    }

    public void SetActive(bool isActive)
    {
        IsActive = isActive;
        UpdatedAt = DateTime.UtcNow;
    }

    public void SetIconUrl(string? iconUrl)
    {
        IconUrl = iconUrl;
        UpdatedAt = DateTime.UtcNow;
    }
}
