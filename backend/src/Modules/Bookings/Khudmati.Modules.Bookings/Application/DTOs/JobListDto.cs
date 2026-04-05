namespace Khudmati.Modules.Bookings.Application.DTOs;

public record JobListDto(
    IReadOnlyList<JobDto> Items,
    int TotalCount,
    int Page,
    int PageSize
);
