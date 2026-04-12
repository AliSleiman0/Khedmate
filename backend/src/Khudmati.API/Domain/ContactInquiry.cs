namespace Khudmati.API.Domain;

public class ContactInquiry
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Email { get; private set; } = string.Empty;
    public string Message { get; private set; } = string.Empty;
    public DateTime SubmittedAt { get; private set; }

    private ContactInquiry() { }

    public static ContactInquiry Create(string name, string email, string message) => new()
    {
        Id = Guid.NewGuid(),
        Name = name,
        Email = email,
        Message = message,
        SubmittedAt = DateTime.UtcNow,
    };
}
