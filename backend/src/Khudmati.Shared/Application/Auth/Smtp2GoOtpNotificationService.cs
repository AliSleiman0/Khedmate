using System.Net.Http.Json;
using System.Text.Json;
using Khudmati.Shared.Infrastructure;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Khudmati.Shared.Application.Auth;

public class Smtp2GoOtpNotificationService : IOtpNotificationService
{
    private const string ApiUrl = "https://api.smtp2go.com/v3/email/send";

    private readonly Smtp2GoSettings _settings;
    private readonly HttpClient _httpClient;
    private readonly ILogger<Smtp2GoOtpNotificationService> _logger;

    public Smtp2GoOtpNotificationService(
        IOptions<Smtp2GoSettings> settings,
        HttpClient httpClient,
        ILogger<Smtp2GoOtpNotificationService> logger)
    {
        _settings = settings.Value;
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task SendOtpAsync(string phone, string? email, string otp, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            _logger.LogWarning("[OTP] No email provided for phone={Phone} — skipping.", phone);
            return;
        }

        var payload = new
        {
            api_key = _settings.ApiKey,
            to = new[] { email },
            sender = $"{_settings.SenderName} <{_settings.SenderEmail}>",
            subject = $"رمز التحقق / Your Khudmati OTP: {otp}",
            html_body = BuildHtmlBody(otp),
            text_body = $"Your Khudmati verification code is: {otp}\n" +
                        $"رمز التحقق الخاص بك في خدمتي: {otp}\n\n" +
                        "Valid for 10 minutes only."
        };

        try
        {
            var response = await _httpClient.PostAsJsonAsync(ApiUrl, payload, ct);
            var body = await response.Content.ReadAsStringAsync(ct);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("[OTP] SMTP2GO returned {StatusCode}: {Body}", response.StatusCode, body);
                throw new InvalidOperationException($"SMTP2GO error {response.StatusCode}: {body}");
            }

            // Parse "succeeded" count from response
            using var doc = JsonDocument.Parse(body);
            var succeeded = doc.RootElement
                .GetProperty("data")
                .GetProperty("succeeded")
                .GetInt32();

            if (succeeded == 0)
            {
                var failures = doc.RootElement
                    .GetProperty("data")
                    .GetProperty("failures")
                    .GetRawText();
                _logger.LogError("[OTP] SMTP2GO reported 0 sent. Failures: {Failures}", failures);
                throw new InvalidOperationException($"SMTP2GO sent 0 emails. Failures: {failures}");
            }

            _logger.LogInformation("[OTP] Email sent via SMTP2GO to {Email}", email);
        }
        catch (Exception ex) when (ex is not InvalidOperationException)
        {
            _logger.LogError(ex, "[OTP] Failed to send OTP email to {Email}", email);
            throw;
        }
    }

    private static string BuildHtmlBody(string otp) => $"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>Your Khudmati Verification Code</title>
        </head>
        <body style="margin:0;padding:0;background:#efe8df;font-family:Arial,'Helvetica Neue',sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background:#efe8df;padding:48px 20px 40px;">
            <tr>
              <td align="center">

                <!-- Logo + Brand -->
                <table cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
                  <tr>
                    <td align="center">
                      <svg width="72" height="72" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                        <!-- Chimney -->
                        <rect x="132" y="28" width="16" height="38" fill="#3D1000"/>
                        <!-- Roof triangle -->
                        <polygon points="100,18 188,90 12,90" fill="#3D1000"/>
                        <!-- Dormer window on roof -->
                        <rect x="87" y="46" width="26" height="22" fill="#efe8df"/>
                        <line x1="100" y1="46" x2="100" y2="68" stroke="#3D1000" stroke-width="3"/>
                        <line x1="87" y1="57" x2="113" y2="57" stroke="#3D1000" stroke-width="3"/>
                        <!-- Decorative shingle lines on roof -->
                        <line x1="55" y1="75" x2="72" y2="80" stroke="#efe8df" stroke-width="2.5" stroke-linecap="round"/>
                        <line x1="45" y1="65" x2="62" y2="70" stroke="#efe8df" stroke-width="2.5" stroke-linecap="round"/>
                        <line x1="128" y1="75" x2="145" y2="80" stroke="#efe8df" stroke-width="2.5" stroke-linecap="round"/>
                        <line x1="138" y1="65" x2="155" y2="70" stroke="#efe8df" stroke-width="2.5" stroke-linecap="round"/>
                        <!-- Eave bar -->
                        <rect x="5" y="88" width="190" height="11" rx="3" fill="#3D1000"/>
                        <!-- Left pillar -->
                        <rect x="6" y="97" width="9" height="92" fill="#3D1000"/>
                        <!-- Right pillar -->
                        <rect x="185" y="97" width="9" height="92" fill="#3D1000"/>
                        <!-- Left window box -->
                        <rect x="22" y="114" width="48" height="40" fill="#3D1000"/>
                        <rect x="24" y="116" width="44" height="36" fill="#efe8df"/>
                        <line x1="46" y1="116" x2="46" y2="152" stroke="#3D1000" stroke-width="3"/>
                        <line x1="24" y1="134" x2="68" y2="134" stroke="#3D1000" stroke-width="3"/>
                        <!-- Right window box -->
                        <rect x="130" y="114" width="48" height="40" fill="#3D1000"/>
                        <rect x="132" y="116" width="44" height="36" fill="#efe8df"/>
                        <line x1="154" y1="116" x2="154" y2="152" stroke="#3D1000" stroke-width="3"/>
                        <line x1="132" y1="134" x2="176" y2="134" stroke="#3D1000" stroke-width="3"/>
                        <!-- Door -->
                        <rect x="84" y="130" width="32" height="59" fill="#3D1000"/>
                        <!-- Door knob -->
                        <circle cx="112" cy="162" r="3" fill="#efe8df"/>
                        <!-- Step -->
                        <rect x="79" y="185" width="42" height="7" rx="2" fill="#3D1000"/>
                        <!-- Ground curve -->
                        <path d="M0,194 Q100,204 200,194" stroke="#3D1000" stroke-width="5" fill="none" stroke-linecap="round"/>
                      </svg>
                      <div style="margin-top:10px;font-size:22px;font-weight:800;color:#1B4F72;letter-spacing:0.5px;">خدمتي &nbsp;·&nbsp; Khudmati</div>
                      <div style="font-size:12px;color:#a09080;margin-top:4px;letter-spacing:1px;text-transform:uppercase;">Home Services · خدمات منزلية</div>
                    </td>
                  </tr>
                </table>

                <!-- Card -->
                <table width="520" cellpadding="0" cellspacing="0"
                       style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 6px 32px rgba(61,16,0,0.12);max-width:520px;">

                  <!-- Top accent bar: amber -->
                  <tr>
                    <td style="background:linear-gradient(90deg,#F39C12,#e8890a);height:6px;font-size:0;">&nbsp;</td>
                  </tr>

                  <!-- OTP hero -->
                  <tr>
                    <td style="padding:44px 48px 32px;text-align:center;">
                      <p style="color:#1B4F72;font-size:17px;font-weight:700;margin:0 0 6px;">مرحباً &nbsp;/&nbsp; Hello!</p>
                      <p style="color:#9a8878;font-size:14px;margin:0 0 32px;line-height:1.6;">
                        رمز التحقق الخاص بحسابك في خدمتي<br/>
                        Your Khudmati account verification code
                      </p>

                      <!-- OTP box -->
                      <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
                        <tr>
                          <td style="background:#fffbf0;border:2.5px solid #F39C12;border-radius:16px;padding:28px 44px;text-align:center;">
                            <div style="font-size:11px;color:#c0a878;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;">Verification Code · رمز التحقق</div>
                            <div style="font-size:52px;font-weight:900;color:#1B4F72;letter-spacing:14px;line-height:1;">{otp}</div>
                          </td>
                        </tr>
                      </table>

                      <!-- Timer -->
                      <table cellpadding="0" cellspacing="0" style="margin:0 auto;">
                        <tr>
                          <td style="background:#fff7ed;border-radius:20px;padding:8px 20px;">
                            <span style="font-size:13px;color:#F39C12;font-weight:700;">⏱&nbsp; </span>
                            <span style="font-size:13px;color:#c07010;">Valid 10 min &nbsp;·&nbsp; صالح 10 دقائق</span>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>

                  <!-- Divider -->
                  <tr>
                    <td style="padding:0 48px;">
                      <div style="height:1px;background:#f2ece4;"></div>
                    </td>
                  </tr>

                  <!-- Message -->
                  <tr>
                    <td style="padding:28px 48px 36px;">
                      <p style="color:#555;font-size:14px;line-height:1.8;margin:0 0 14px;">
                        Enter this code in the app to complete your registration with
                        <strong style="color:#1B4F72;">Khudmati</strong>.<br/>
                        أدخل هذا الرمز في التطبيق لإتمام تسجيلك في
                        <strong style="color:#1B4F72;">خدمتي</strong>.
                      </p>
                      <p style="color:#c0b0a0;font-size:12px;line-height:1.7;margin:0;">
                        If you didn't create an account, you can safely ignore this email.<br/>
                        إذا لم تنشئ حساباً، يمكنك تجاهل هذا البريد بأمان.
                      </p>
                    </td>
                  </tr>

                  <!-- Footer -->
                  <tr>
                    <td style="background:#efe8df;padding:18px 48px;text-align:center;border-top:1px solid #e0d5c8;">
                      <p style="color:#b8a898;font-size:12px;margin:0;">
                        © 2026 Khudmati &nbsp;·&nbsp; <a href="mailto:info@khudmati.app" style="color:#b8a898;text-decoration:none;">info@khudmati.app</a>
                      </p>
                    </td>
                  </tr>

                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        """;
}
