namespace Khudmati.Modules.Payments.Application.DTOs;

public record TransactionDto(
    Guid Id,
    Guid JobId,
    Guid CustomerId,
    Guid ProviderId,
    decimal GrossAmount,
    decimal CommissionAmount,
    decimal NetAmount,
    string Currency,
    string Status,
    DateTime? HoldUntil,
    DateTime CreatedAt,
    decimal? CreditApplied = null,
    decimal? ReferralDiscount = null);
