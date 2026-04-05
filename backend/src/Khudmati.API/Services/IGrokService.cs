namespace Khudmati.API.Services;

public interface IGrokService
{
    /// <summary>
    /// Sends a rough service description to the Grok API and returns an improved version.
    /// Returns null if the API call fails.
    /// </summary>
    Task<string?> ImproveDescriptionAsync(
        string roughDescription,
        string categoryName,
        CancellationToken ct = default);
}
