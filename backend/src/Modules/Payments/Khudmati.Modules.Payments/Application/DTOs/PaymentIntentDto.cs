namespace Khudmati.Modules.Payments.Application.DTOs;

public record PaymentIntentDto(
    string PaymentIntentId,
    string ClientSecret,
    decimal Amount,
    string Currency,
    decimal? ReferralDiscountAmount = null,
    decimal? CreditAppliedAmount = null,
    decimal? OriginalAmount = null);
