namespace Khudmati.Modules.Customers.Application.DTOs;

public record CustomerAuthResponse(string AccessToken, string RefreshToken, CustomerAuthDto Customer);

public record CustomerAuthDto(Guid Id, string FullName, string Phone, string? Email);
