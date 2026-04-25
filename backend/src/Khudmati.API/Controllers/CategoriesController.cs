using Khudmati.API.Domain;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

/// <summary>
/// Public service-category lookup. The unified mobile app fetches the active
/// list on cold start and pulls history-only metadata via the by-slug endpoint
/// when a job references a deactivated category.
/// </summary>
[ApiController]
[Route("api/categories")]
public class CategoriesController : ControllerBase
{
    private readonly AppDbContext _context;

    public CategoriesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetActive(CancellationToken ct)
    {
        var categories = await _context.Set<ServiceCategory>()
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.NameEn)
            .Select(c => new
            {
                c.Slug,
                c.NameEn,
                c.NameAr,
                c.IconKey,
                c.IconUrl,
                c.RequiresSkillTest,
            })
            .ToListAsync(ct);

        Response.Headers["Cache-Control"] = "public, max-age=60";
        return Ok(new { success = true, data = categories });
    }

    [HttpGet("{slug}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetBySlug(string slug, CancellationToken ct)
    {
        var lower = (slug ?? string.Empty).Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(lower))
            return BadRequest(new { success = false, error = "SLUG_REQUIRED" });

        var category = await _context.Set<ServiceCategory>()
            .Where(c => c.Slug == lower)
            .Select(c => new
            {
                c.Slug,
                c.NameEn,
                c.NameAr,
                c.IconKey,
                c.IconUrl,
                c.IsActive,
                c.RequiresSkillTest,
            })
            .FirstOrDefaultAsync(ct);

        if (category is null)
            return NotFound(new { success = false, error = "CATEGORY_NOT_FOUND" });

        return Ok(new { success = true, data = category });
    }
}
