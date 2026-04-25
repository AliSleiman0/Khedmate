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

        _ = Task.Run(() => SendAdminNotificationAsync(request), CancellationToken.None);
        _ = Task.Run(() => SendUserAcknowledgmentAsync(request), CancellationToken.None);

        return Ok(new { success = true });
    }

    private async Task SendAdminNotificationAsync(ContactRequest request)
    {
        try
        {
            var payload = new
            {
                api_key = _smtp.ApiKey,
                to = new[] { _smtp.SenderEmail },
                sender = $"{_smtp.SenderName} <{_smtp.SenderEmail}>",
                subject = $"[Khudmati] New Contact Form Submission from {request.Name}",
                // Reply-To = the user so admin can reply directly from their inbox
                // instead of replying to themselves.
                custom_headers = new[]
                {
                    new { header = "Reply-To", value = request.Email },
                },
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
                _logger.LogError("[Contact] Admin notification SMTP2GO returned {Status}: {Body}", response.StatusCode, body);
            }
            else
            {
                _logger.LogInformation("[Contact] Admin notification sent to {To}", _smtp.SenderEmail);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Contact] Failed to send admin notification email");
        }
    }

    private async Task SendUserAcknowledgmentAsync(ContactRequest request)
    {
        try
        {
            var nameHtml = System.Net.WebUtility.HtmlEncode(request.Name);
            var messageHtml = System.Net.WebUtility.HtmlEncode(request.Message).Replace("\n", "<br/>");

            var payload = new
            {
                api_key = _smtp.ApiKey,
                to = new[] { $"{request.Name} <{request.Email}>" },
                sender = $"{_smtp.SenderName} <{_smtp.SenderEmail}>",
                subject = "تم استلام رسالتك — Khudmati / We received your message",
                text_body =
                    $"شكراً لتواصلك مع خدمتي يا {request.Name}،\n\n" +
                    "استلمنا رسالتك وسيقوم فريقنا بالرد خلال يوم عمل واحد.\n\n" +
                    $"رسالتك:\n{request.Message}\n\n" +
                    "— فريق خدمتي\nhttps://khudmati.app\n\n" +
                    "---\n\n" +
                    $"Thanks for reaching out to Khudmati, {request.Name}.\n\n" +
                    "We've received your message and our team will reply within one business day.\n\n" +
                    $"Your message:\n{request.Message}\n\n" +
                    "— The Khudmati team\nhttps://khudmati.app\n\n" +
                    "If you didn't submit this form, please ignore this email.\n" +
                    "لم تقم بإرسال هذا النموذج؟ يمكنك تجاهل هذه الرسالة.",
                html_body =
                    "<div style=\"font-family:Cairo,Arial,sans-serif;max-width:560px;margin:0 auto;color:#333;\">" +
                    "<div dir=\"rtl\" style=\"padding:16px;background:#1B4F72;color:#fff;border-radius:8px 8px 0 0;text-align:right;\">" +
                    "<h2 style=\"margin:0;\">تم استلام رسالتك ✓</h2>" +
                    "</div>" +
                    "<div dir=\"rtl\" style=\"padding:16px;text-align:right;\">" +
                    $"<p>شكراً لتواصلك مع خدمتي يا <strong>{nameHtml}</strong>،</p>" +
                    "<p>استلمنا رسالتك وسيقوم فريقنا بالرد خلال يوم عمل واحد.</p>" +
                    "<p style=\"color:#666;font-size:14px;\">رسالتك:</p>" +
                    $"<blockquote style=\"border-right:3px solid #F39C12;padding:8px 12px;background:#f8f8f8;margin:0;\">{messageHtml}</blockquote>" +
                    "<p>— فريق خدمتي</p>" +
                    "</div>" +
                    "<hr style=\"border:none;border-top:1px solid #eee;margin:8px 0;\" />" +
                    "<div dir=\"ltr\" style=\"padding:16px;\">" +
                    $"<p>Thanks for reaching out to Khudmati, <strong>{nameHtml}</strong>.</p>" +
                    "<p>We've received your message and our team will reply within one business day.</p>" +
                    "<p style=\"color:#666;font-size:14px;\">Your message:</p>" +
                    $"<blockquote style=\"border-left:3px solid #F39C12;padding:8px 12px;background:#f8f8f8;margin:0;\">{messageHtml}</blockquote>" +
                    "<p>— The Khudmati team</p>" +
                    "</div>" +
                    "<div style=\"padding:12px 16px;background:#f8f8f8;border-radius:0 0 8px 8px;font-size:12px;color:#999;text-align:center;\">" +
                    "<a href=\"https://khudmati.app\" style=\"color:#1B4F72;\">khudmati.app</a><br/>" +
                    "If you didn't submit this form, please ignore this email.<br/>" +
                    "<span dir=\"rtl\">لم تقم بإرسال هذا النموذج؟ يمكنك تجاهل هذه الرسالة.</span>" +
                    "</div>" +
                    "</div>"
            };

            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsJsonAsync("https://api.smtp2go.com/v3/email/send", payload);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync();
                _logger.LogError("[Contact] User acknowledgment SMTP2GO returned {Status}: {Body}", response.StatusCode, body);
            }
            else
            {
                _logger.LogInformation("[Contact] User acknowledgment sent to {To}", request.Email);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Contact] Failed to send user acknowledgment email");
        }
    }
}

public record ContactRequest(string Name, string Email, string Message);
