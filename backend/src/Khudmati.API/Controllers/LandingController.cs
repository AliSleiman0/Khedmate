using System.Net.Http.Json;
using Khudmati.API.Domain;
using Khudmati.Modules.Bookings.Domain.Entities;
using Khudmati.Modules.Bookings.Domain.Enums;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Infrastructure;
using Khudmati.Shared.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/landing")]
[AllowAnonymous]
public class LandingController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly Smtp2GoSettings _smtp;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<LandingController> _logger;

    public LandingController(
        AppDbContext context,
        IOptions<Smtp2GoSettings> smtp,
        IHttpClientFactory httpClientFactory,
        ILogger<LandingController> logger)
    {
        _context = context;
        _smtp = smtp.Value;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    // GET /api/landing/stats
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken ct)
    {
        try
        {
            var totalProviders = await _context.Set<Provider>()
                .CountAsync(p => p.Tier == VerificationTier.Active, ct);

            var totalBookings = await _context.Set<Job>()
                .CountAsync(j => j.Status == JobStatus.Paid, ct);

            var avgPositiveRate = await _context.Set<ProviderRatingStats>()
                .Where(r => r.TotalRatings > 0)
                .AverageAsync(r => (decimal?)r.PositiveRate, ct);
            // Convert 0-100 positive rate to a 5-star equivalent
            var avgRating = avgPositiveRate.HasValue
                ? Math.Round((double)avgPositiveRate.Value / 100 * 5, 1)
                : 4.8;

            return Ok(new
            {
                success = true,
                data = new
                {
                    totalProviders,
                    totalBookings,
                    avgRating = Math.Round(avgRating, 1),
                    citiesCovered = 6,
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching landing stats");
            return Ok(new
            {
                success = true,
                data = new { totalProviders = 350, totalBookings = 1200, avgRating = 4.8, citiesCovered = 6 }
            });
        }
    }

    // POST /api/landing/contact
    [HttpPost("contact")]
    public async Task<IActionResult> SubmitContact([FromBody] ContactRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Name) ||
            string.IsNullOrWhiteSpace(request.Email) ||
            string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { success = false, error = "VALIDATION_ERROR" });
        }

        var inquiry = ContactInquiry.Create(request.Name.Trim(), request.Email.Trim(), request.Message.Trim());
        _context.Set<ContactInquiry>().Add(inquiry);
        await _context.SaveChangesAsync(ct);

        _ = Task.Run(() => SendContactEmailAsync(request), CancellationToken.None);

        return Ok(new { success = true });
    }

    private async Task SendContactEmailAsync(ContactRequest request)
    {
        try
        {
            var payload = new
            {
                api_key = _smtp.ApiKey,
                to = new[] { _smtp.SenderEmail },
                sender = $"{_smtp.SenderName} <{_smtp.SenderEmail}>",
                subject = $"[Khudmati] New Contact Form Submission from {request.Name}",
                text_body =
                    $"Name: {request.Name}\n" +
                    $"Email: {request.Email}\n\n" +
                    $"Message:\n{request.Message}",
                html_body =
                    $"<p><strong>Name:</strong> {System.Net.WebUtility.HtmlEncode(request.Name)}</p>" +
                    $"<p><strong>Email:</strong> {System.Net.WebUtility.HtmlEncode(request.Email)}</p>" +
                    $"<p><strong>Message:</strong></p>" +
                    $"<p>{System.Net.WebUtility.HtmlEncode(request.Message).Replace("\n", "<br/>")}</p>"
            };

            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsJsonAsync("https://api.smtp2go.com/v3/email/send", payload);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync();
                _logger.LogError("[Contact] SMTP2GO returned {Status}: {Body}", response.StatusCode, body);
            }
            else
            {
                _logger.LogInformation("[Contact] Email sent to {To}", _smtp.SenderEmail);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Contact] Failed to send contact email");
        }
    }
}

public record ContactRequest(string Name, string Email, string Message);
