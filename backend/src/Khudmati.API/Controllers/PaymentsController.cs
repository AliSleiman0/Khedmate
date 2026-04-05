using System.Security.Claims;
using Khudmati.Modules.Customers.Application.Commands;
using Khudmati.Modules.Customers.Application.Queries;
using Khudmati.Modules.Payments.Application.Commands;
using Khudmati.Modules.Payments.Application.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Khudmati.API.Controllers;

[ApiController]
[Route("api/payments")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IMediator _mediator;

    public PaymentsController(IMediator mediator) => _mediator = mediator;

    // POST /api/payments/intent
    [HttpPost("intent")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> CreateIntent(
        [FromBody] CreateIntentRequest req,
        CancellationToken ct)
    {
        var customerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Apply referral discount and credits before creating the Stripe intent
        var discountsResult = await _mediator.Send(
            new GetCheckoutDiscountsQuery(customerId, req.Amount), ct);

        decimal discountAmount = 0m, creditToApply = 0m;
        if (discountsResult.Success && discountsResult.Data is not null)
        {
            discountAmount = discountsResult.Data.ReferralDiscountAmount;
            creditToApply = discountsResult.Data.CreditToApply;
        }

        var result = await _mediator.Send(
            new CreatePaymentIntentCommand(
                customerId,
                req.Amount,
                req.Currency,
                req.CategoryId,
                discountAmount,
                creditToApply), ct);

        if (!result.Success)
            return result.Error switch
            {
                "INVALID_AMOUNT" => BadRequest(new { success = false, error = result.Error }),
                _ => StatusCode(422, new { success = false, error = result.Error })
            };

        return Ok(new { success = true, data = result.Data });
    }

    // POST /api/payments/confirm
    [HttpPost("confirm")]
    [Authorize(Policy = "CustomerOnly")]
    public async Task<IActionResult> Confirm(
        [FromBody] ConfirmPaymentRequest req,
        CancellationToken ct)
    {
        var customerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _mediator.Send(
            new ConfirmPaymentCommand(customerId, req.PaymentIntentId, req.JobId), ct);

        if (!result.Success)
            return result.Error switch
            {
                "PAYMENT_ALREADY_EXISTS" => Conflict(new { success = false, error = result.Error }),
                "TRANSACTION_NOT_FOUND" => NotFound(new { success = false, error = result.Error }),
                "FORBIDDEN" => Forbid(),
                "PAYMENT_NOT_SUCCEEDED" => BadRequest(new { success = false, error = result.Error }),
                _ => StatusCode(422, new { success = false, error = result.Error })
            };

        // Consume platform credits that were applied to this payment
        if (result.Data?.CreditApplied is > 0)
        {
            await _mediator.Send(
                new ConsumeCustomerCreditsCommand(customerId, result.Data.CreditApplied.Value), ct);
        }

        return Ok(new { success = true, data = result.Data });
    }

    // GET /api/payments/my-transactions
    [HttpGet("my-transactions")]
    [Authorize(Policy = "CustomerOrProvider")]
    public async Task<IActionResult> GetMyTransactions(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var audience = User.FindFirstValue("aud") ?? "customer";

        var result = await _mediator.Send(
            new GetMyTransactionsQuery(userId, audience, page, pageSize), ct);

        return Ok(new { success = true, data = result.Data });
    }
}

public record CreateIntentRequest(decimal Amount, string Currency, string CategoryId);
public record ConfirmPaymentRequest(string PaymentIntentId, Guid JobId);
