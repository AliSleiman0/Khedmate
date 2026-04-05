using System.Text;
using System.Text.Json;

namespace Khudmati.API.Services;

public class GrokService : IGrokService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<GrokService> _logger;

    private const string SystemPrompt =
        "You are a helpful assistant for a home services app called Khudmati. " +
        "Rewrite the user's rough service request into a clear, professional, and concise " +
        "service request description. Respond in the same language as the input (Arabic or English). " +
        "Keep it under 300 words. Return only the improved description — no commentary, no greetings.";

    public GrokService(IHttpClientFactory httpClientFactory, ILogger<GrokService> logger)
    {
        _httpClient = httpClientFactory.CreateClient("grok");
        _logger = logger;
    }

    public async Task<string?> ImproveDescriptionAsync(
        string roughDescription,
        string categoryName,
        CancellationToken ct = default)
    {
        var userMessage = string.IsNullOrEmpty(categoryName)
            ? roughDescription
            : $"Service category: {categoryName}\n\nDescription: {roughDescription}";

        var requestBody = new
        {
            model = "grok-3-mini",
            messages = new[]
            {
                new { role = "system", content = SystemPrompt },
                new { role = "user", content = userMessage }
            },
            max_tokens = 400,
            temperature = 0.4
        };

        var json = JsonSerializer.Serialize(requestBody);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");

        try
        {
            var response = await _httpClient.PostAsync("/v1/chat/completions", content, ct);
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync(ct);
            using var doc = JsonDocument.Parse(responseJson);

            var improved = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            return improved?.Trim();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Grok API call failed for category '{Category}'", categoryName);
            return null;
        }
    }
}
