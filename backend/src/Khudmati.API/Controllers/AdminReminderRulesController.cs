using Khudmati.API.Domain;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/admin/reminder-rules")]
[Authorize(Policy = "AdminOnly")]
public class AdminReminderRulesController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminReminderRulesController(AppDbContext context)
    {
        _context = context;
    }

    // GET /api/admin/reminder-rules
    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var rules = await _context.Set<ReminderRule>()
            .OrderBy(r => r.Category)
            .Select(r => new
            {
                r.Id,
                r.Category,
                r.IntervalDays,
                r.IsActive,
                r.CreatedAt,
                r.UpdatedAt
            })
            .ToListAsync(ct);

        return Ok(new { success = true, data = rules });
    }

    // POST /api/admin/reminder-rules
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateReminderRuleRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Category))
            return BadRequest(new { success = false, error = "CATEGORY_REQUIRED" });

        if (request.IntervalDays < 1 || request.IntervalDays > 365)
            return BadRequest(new { success = false, error = "INVALID_INTERVAL_DAYS" });

        var exists = await _context.Set<ReminderRule>()
            .AnyAsync(r => r.Category.ToLower() == request.Category.ToLower(), ct);
        if (exists)
            return BadRequest(new { success = false, error = "CATEGORY_ALREADY_EXISTS" });

        var rule = ReminderRule.Create(request.Category.Trim(), request.IntervalDays);
        await _context.Set<ReminderRule>().AddAsync(rule, ct);
        await _context.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new { rule.Id, rule.Category, rule.IntervalDays, rule.IsActive, rule.CreatedAt }
        });
    }

    // PUT /api/admin/reminder-rules/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateReminderRuleRequest request, CancellationToken ct)
    {
        if (request.IntervalDays < 1 || request.IntervalDays > 365)
            return BadRequest(new { success = false, error = "INVALID_INTERVAL_DAYS" });

        var rule = await _context.Set<ReminderRule>().FirstOrDefaultAsync(r => r.Id == id, ct);
        if (rule is null)
            return NotFound(new { success = false, error = "RULE_NOT_FOUND" });

        rule.Update(request.IntervalDays, request.IsActive);
        await _context.SaveChangesAsync(ct);

        return Ok(new
        {
            success = true,
            data = new { rule.Id, rule.Category, rule.IntervalDays, rule.IsActive, rule.UpdatedAt }
        });
    }
}

public record CreateReminderRuleRequest(string Category, int IntervalDays);
public record UpdateReminderRuleRequest(int IntervalDays, bool IsActive);
