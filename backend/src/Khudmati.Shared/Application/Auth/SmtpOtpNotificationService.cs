using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;
using Khudmati.Shared.Infrastructure;

namespace Khudmati.Shared.Application.Auth;

public class SmtpOtpNotificationService : IOtpNotificationService
{
    private readonly SmtpSettings _settings;
    private readonly ILogger<SmtpOtpNotificationService> _logger;

    public SmtpOtpNotificationService(
        IOptions<SmtpSettings> settings,
        ILogger<SmtpOtpNotificationService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendOtpAsync(string phone, string? email, string otp, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            _logger.LogWarning("[OTP] No email address provided for phone={phone} — OTP not sent.", phone);
            return;
        }

        try
        {
            var message = BuildOtpEmail(email, otp);

            using var client = new SmtpClient();
            await client.ConnectAsync(
                _settings.Host,
                _settings.Port,
                _settings.EnableSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None,
                ct);

            await client.AuthenticateAsync(_settings.Username, _settings.Password, ct);
            await client.SendAsync(message, ct);
            await client.DisconnectAsync(quit: true, ct);

            _logger.LogInformation("[OTP] Email sent to {email}", email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[OTP] Failed to send OTP email to {email}", email);
            throw;
        }
    }

    private MimeMessage BuildOtpEmail(string toEmail, string otp)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_settings.FromName, _settings.Username));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = $"رمز التحقق الخاص بك / Your Khudmati OTP: {otp}";

        var bodyBuilder = new BodyBuilder
        {
            HtmlBody = BuildHtmlBody(otp),
            TextBody = $"Your Khudmati verification code is: {otp}\nرمز التحقق الخاص بك في خدمتي: {otp}\n\nThis code expires in 10 minutes."
        };

        message.Body = bodyBuilder.ToMessageBody();
        return message;
    }

    private static string BuildHtmlBody(string otp) => $"""
        <!DOCTYPE html>
        <html lang="ar" dir="rtl">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>رمز التحقق - Khudmati OTP</title>
        </head>
        <body style="margin:0;padding:0;background:#f4f6f9;font-family:'Cairo',Arial,sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f9;padding:40px 0;">
            <tr>
              <td align="center">
                <table width="500" cellpadding="0" cellspacing="0"
                       style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">
                  <!-- Header -->
                  <tr>
                    <td style="background:#1B4F72;padding:32px 40px;text-align:center;">
                      <h1 style="color:#ffffff;margin:0;font-size:28px;font-weight:700;letter-spacing:1px;">خدمتي</h1>
                      <p style="color:#a8c8e8;margin:6px 0 0;font-size:14px;">Khudmati — Your Service, At Your Fingertips</p>
                    </td>
                  </tr>
                  <!-- Body -->
                  <tr>
                    <td style="padding:40px 40px 20px;">
                      <p style="color:#2c3e50;font-size:17px;margin:0 0 8px;font-weight:600;">مرحباً / Hello,</p>
                      <p style="color:#555;font-size:15px;line-height:1.7;margin:0 0 28px;">
                        استخدم الرمز أدناه للتحقق من حسابك في خدمتي.<br/>
                        Use the code below to verify your Khudmati account.
                      </p>
                      <!-- OTP Box -->
                      <div style="background:#f0f7ff;border:2px dashed #1B4F72;border-radius:12px;
                                  padding:24px;text-align:center;margin-bottom:28px;">
                        <p style="margin:0 0 6px;color:#777;font-size:13px;">رمز التحقق / Verification Code</p>
                        <span style="font-size:42px;font-weight:800;color:#1B4F72;letter-spacing:10px;">{otp}</span>
                      </div>
                      <p style="color:#e67e22;font-size:14px;text-align:center;margin:0 0 24px;">
                        ⏱ صالح لمدة 10 دقائق فقط &nbsp;|&nbsp; Valid for 10 minutes only
                      </p>
                      <p style="color:#999;font-size:13px;line-height:1.6;">
                        إذا لم تطلب هذا الرمز، يمكنك تجاهل هذا البريد بأمان.<br/>
                        If you didn't request this code, you can safely ignore this email.
                      </p>
                    </td>
                  </tr>
                  <!-- Footer -->
                  <tr>
                    <td style="background:#f8f9fa;padding:20px 40px;text-align:center;border-top:1px solid #eee;">
                      <p style="color:#aaa;font-size:12px;margin:0;">
                        © 2026 Khudmati · info@khudmati.app
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
