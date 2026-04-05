using Khudmati.Modules.Bookings.Infrastructure.Persistence;
using Khudmati.Modules.Customers.Application.Commands;
using Khudmati.Modules.Customers.Domain.Entities;
using Khudmati.Modules.Customers.Infrastructure.Persistence;
using Khudmati.Modules.Notifications.Application;
using Khudmati.Modules.Notifications.Domain.Entities;
using Khudmati.Modules.Notifications.Infrastructure.Persistence;
using Khudmati.Modules.Payments.Domain.Events;
using MediatR;

namespace Khudmati.API.EventHandlers;

/// <summary>
/// Listens for PaymentReleasedEvent. When the referred customer's FIRST job
/// reaches Paid status, awards platform credit to the referrer and marks the
/// referral use as Completed.
/// </summary>
public class ReferralAwardHandler : INotificationHandler<PaymentReleasedEvent>
{
    private readonly IBookingsRepository _bookingsRepo;
    private readonly ICustomersRepository _customersRepo;
    private readonly INotificationRepository _notificationRepo;
    private readonly IPushNotificationService _push;

    public ReferralAwardHandler(
        IBookingsRepository bookingsRepo,
        ICustomersRepository customersRepo,
        INotificationRepository notificationRepo,
        IPushNotificationService push)
    {
        _bookingsRepo = bookingsRepo;
        _customersRepo = customersRepo;
        _notificationRepo = notificationRepo;
        _push = push;
    }

    public async Task Handle(PaymentReleasedEvent notification, CancellationToken cancellationToken)
    {
        // 1. Load the job to get the customer id
        var job = await _bookingsRepo.GetByIdAsync(notification.JobId, cancellationToken);
        if (job is null) return;

        var customerId = job.CustomerId;

        // 2. Check if this customer has a Pending referral use record (they were referred)
        var referralUse = await _customersRepo.GetPendingReferralUseByReferredCustomerAsync(
            customerId, cancellationToken);
        if (referralUse is null) return;

        // 3. Verify this is the customer's FIRST paid job (count includes the current one
        //    since MarkJobPaidCommand fires before this handler completes)
        var paidCount = await _bookingsRepo.CountPaidJobsByCustomerAsync(customerId, cancellationToken);
        if (paidCount != 1) return;

        // 4. Award credit to the referrer
        var credit = CustomerCredit.Create(
            referralUse.ReferrerCustomerId,
            referralUse.ReferrerCreditAmount,
            "Referral",
            referralUse.Id,
            DateTime.UtcNow.AddDays(ReferralConstants.CreditValidityDays));

        await _customersRepo.AddCreditAsync(credit, cancellationToken);

        // 5. Complete the referral use record
        referralUse.Complete(notification.JobId);
        await _customersRepo.UpdateReferralUseAsync(referralUse, cancellationToken);

        await _customersRepo.SaveChangesAsync(cancellationToken);

        // 6. Push notification to referrer
        var title = "🎉 أكمل صديقك أول حجز!";
        var body = $"تم إضافة {referralUse.ReferrerCreditAmount:F2} ر.س لرصيدك";

        var notif = Notification.Create(referralUse.ReferrerCustomerId, "customer", title, body);
        await _notificationRepo.AddAsync(notif, cancellationToken);
        await _notificationRepo.SaveChangesAsync(cancellationToken);

        await _push.SendAsync(
            referralUse.ReferrerCustomerId,
            "customer",
            title,
            body,
            new Dictionary<string, string>
            {
                ["type"] = "referral_credited",
                ["amount"] = referralUse.ReferrerCreditAmount.ToString("F2")
            },
            cancellationToken);
    }
}
