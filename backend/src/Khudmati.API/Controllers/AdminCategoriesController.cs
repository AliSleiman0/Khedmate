using System.Text.RegularExpressions;
using Khudmati.API.Domain;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin/categories")]
[Authorize(Policy = "AdminOnly")]
public class AdminCategoriesController : ControllerBase
{
    private static readonly Regex SlugPattern = new("^[a-z][a-z0-9_]*$", RegexOptions.Compiled);

    private readonly AppDbContext _context;

    public AdminCategoriesController(AppDbContext context)
    {
        _context = context;
    }

    // GET /api/admin/categories
    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var categories = await _context.Set<ServiceCategory>()
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.NameEn)
            .ToListAsync(ct);

        // Compute published-question count per slug. Until PR 2 adds an
        // explicit IsPublished column we use IsActive as the proxy — the
        // seeded skill-test questions all ship with IsActive=true so the 5
        // existing categories report 10 each.
        var slugs = categories.Select(c => c.Slug).ToList();
        var counts = await _context.Set<SkillTestQuestion>()
            .Where(q => q.IsActive && slugs.Contains(q.CategoryId))
            .GroupBy(q => q.CategoryId)
            .Select(g => new { Slug = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Slug, x => x.Count, ct);

        var result = categories.Select(c => new
        {
            c.Id,
            c.Slug,
            c.NameEn,
            c.NameAr,
            c.IconKey,
            c.IconUrl,
            c.DisplayOrder,
            c.IsActive,
            c.RequiresSkillTest,
            PublishedQuestionCount = counts.GetValueOrDefault(c.Slug, 0),
            c.CreatedAt,
            c.UpdatedAt,
        });

        return Ok(new { success = true, data = result });
    }

    // POST /api/admin/categories
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateCategoryRequest request,
        CancellationToken ct)
    {
        var slug = (request.Slug ?? string.Empty).Trim().ToLowerInvariant();
        var nameEn = (request.NameEn ?? string.Empty).Trim();
        var nameAr = (request.NameAr ?? string.Empty).Trim();
        var iconKey = (request.IconKey ?? string.Empty).Trim();

        if (string.IsNullOrEmpty(slug))
            return BadRequest(new { success = false, error = "SLUG_REQUIRED" });
        if (!SlugPattern.IsMatch(slug) || slug.Length > 50)
            return BadRequest(new { success = false, error = "SLUG_INVALID_FORMAT" });
        if (string.IsNullOrEmpty(nameEn) || nameEn.Length > 100)
            return BadRequest(new { success = false, error = "NAME_EN_INVALID" });
        if (string.IsNullOrEmpty(nameAr) || nameAr.Length > 100)
            return BadRequest(new { success = false, error = "NAME_AR_INVALID" });
        if (string.IsNullOrEmpty(iconKey) || iconKey.Length > 50)
            return BadRequest(new { success = false, error = "ICON_KEY_INVALID" });

        var exists = await _context.Set<ServiceCategory>()
            .AnyAsync(c => c.Slug == slug, ct);
        if (exists)
            return Conflict(new { success = false, error = "SLUG_ALREADY_EXISTS" });

        var adminId = TryGetAdminId();
        var category = ServiceCategory.Create(
            slug, nameEn, nameAr, iconKey,
            request.DisplayOrder ?? 100,
            request.RequiresSkillTest ?? true,
            adminId);

        await _context.Set<ServiceCategory>().AddAsync(category, ct);
        await _context.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = ToDto(category, publishedQuestionCount: 0),
        });
    }

    // PUT /api/admin/categories/{id}
    // PR 1: slug is read-only after creation. Renaming a slug requires a
    // cross-table reference check (jobs, providers.service_categories,
    // skill_test_questions, reminder_rules) that's deferred to a follow-up.
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(
        Guid id,
        [FromBody] UpdateCategoryRequest request,
        CancellationToken ct)
    {
        var category = await _context.Set<ServiceCategory>()
            .FirstOrDefaultAsync(c => c.Id == id, ct);
        if (category is null)
            return NotFound(new { success = false, error = "CATEGORY_NOT_FOUND" });

        var nameEn = request.NameEn?.Trim();
        var nameAr = request.NameAr?.Trim();
        var iconKey = request.IconKey?.Trim();

        if (nameEn is not null && (nameEn.Length == 0 || nameEn.Length > 100))
            return BadRequest(new { success = false, error = "NAME_EN_INVALID" });
        if (nameAr is not null && (nameAr.Length == 0 || nameAr.Length > 100))
            return BadRequest(new { success = false, error = "NAME_AR_INVALID" });
        if (iconKey is not null && (iconKey.Length == 0 || iconKey.Length > 50))
            return BadRequest(new { success = false, error = "ICON_KEY_INVALID" });

        category.UpdateDetails(
            slug: null,
            nameEn: nameEn,
            nameAr: nameAr,
            iconKey: iconKey,
            displayOrder: request.DisplayOrder,
            requiresSkillTest: request.RequiresSkillTest);

        await _context.SaveChangesAsync(ct);

        var publishedCount = await _context.Set<SkillTestQuestion>()
            .CountAsync(q => q.IsActive && q.CategoryId == category.Slug, ct);

        return Ok(new { success = true, data = ToDto(category, publishedCount) });
    }

    // PATCH /api/admin/categories/{id}/active
    [HttpPatch("{id:guid}/active")]
    public async Task<IActionResult> SetActive(
        Guid id,
        [FromBody] SetCategoryActiveRequest request,
        CancellationToken ct)
    {
        var category = await _context.Set<ServiceCategory>()
            .FirstOrDefaultAsync(c => c.Id == id, ct);
        if (category is null)
            return NotFound(new { success = false, error = "CATEGORY_NOT_FOUND" });

        var publishedCount = await _context.Set<SkillTestQuestion>()
            .CountAsync(q => q.IsActive && q.CategoryId == category.Slug, ct);

        if (request.IsActive && category.RequiresSkillTest && publishedCount < 10)
        {
            return UnprocessableEntity(new
            {
                success = false,
                error = "INSUFFICIENT_QUESTIONS",
                data = new { publishedQuestionCount = publishedCount, required = 10 },
            });
        }

        category.SetActive(request.IsActive);
        await _context.SaveChangesAsync(ct);

        return Ok(new { success = true, data = ToDto(category, publishedCount) });
    }

    // DELETE /api/admin/categories/{id} — soft delete (sets IsActive = false).
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var category = await _context.Set<ServiceCategory>()
            .FirstOrDefaultAsync(c => c.Id == id, ct);
        if (category is null)
            return NotFound(new { success = false, error = "CATEGORY_NOT_FOUND" });

        category.SetActive(false);
        await _context.SaveChangesAsync(ct);

        return Ok(new { success = true });
    }

    private Guid? TryGetAdminId()
    {
        var sub = User.FindFirst("sub")?.Value
                  ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(sub, out var id) ? id : null;
    }

    private static object ToDto(ServiceCategory c, int publishedQuestionCount) => new
    {
        c.Id,
        c.Slug,
        c.NameEn,
        c.NameAr,
        c.IconKey,
        c.IconUrl,
        c.DisplayOrder,
        c.IsActive,
        c.RequiresSkillTest,
        PublishedQuestionCount = publishedQuestionCount,
        c.CreatedAt,
        c.UpdatedAt,
    };
}

public record CreateCategoryRequest(
    string? Slug,
    string? NameEn,
    string? NameAr,
    string? IconKey,
    int? DisplayOrder,
    bool? RequiresSkillTest);

public record UpdateCategoryRequest(
    string? NameEn,
    string? NameAr,
    string? IconKey,
    int? DisplayOrder,
    bool? RequiresSkillTest);

public record SetCategoryActiveRequest(bool IsActive);
