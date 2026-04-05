namespace Khudmati.Modules.Customers.Application.DTOs;

public record CustomerDto(
    Guid Id,
    string FullName,
    string Phone,
    string Email,
    bool IsActive,
    DateTime CreatedAt
);
