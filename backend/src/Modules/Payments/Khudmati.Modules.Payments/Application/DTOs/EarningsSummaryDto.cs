namespace Khudmati.Modules.Payments.Application.DTOs;

public record EarningsSummaryDto(
    decimal PendingBalance,
    decimal AvailableBalance,
    decimal TotalEarnedAllTime,
    decimal TotalEarnedThisMonth,
    string Currency,
    string StripeConnectStatus);   // not_started | pending | complete
