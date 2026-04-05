using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Shared.Domain;

namespace Khudmati.Modules.Providers.Domain.Entities;

public class DocumentSubmission : AuditableEntity
{
    public Guid ProviderId { get; private set; }
    public DocumentType DocumentType { get; private set; }
    public string FrontImageUrl { get; private set; } = string.Empty;
    public string? BackImageUrl { get; private set; }
    public DocumentStatus Status { get; private set; } = DocumentStatus.PendingReview;
    public string? RejectionReason { get; private set; }
    public Guid? ReviewedBy { get; private set; }
    public DateTime? ReviewedAt { get; private set; }
    public DateTime SubmittedAt { get; private set; } = DateTime.UtcNow;

    private DocumentSubmission() { }

    public static DocumentSubmission Create(Guid providerId, DocumentType documentType, string frontImageUrl, string? backImageUrl)
    {
        return new DocumentSubmission
        {
            ProviderId = providerId,
            DocumentType = documentType,
            FrontImageUrl = frontImageUrl,
            BackImageUrl = backImageUrl,
            Status = DocumentStatus.PendingReview,
            SubmittedAt = DateTime.UtcNow
        };
    }

    public void Approve(Guid reviewedBy)
    {
        Status = DocumentStatus.Approved;
        ReviewedBy = reviewedBy;
        ReviewedAt = DateTime.UtcNow;
        SetUpdated();
    }

    public void Reject(Guid reviewedBy, string reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
            throw new ArgumentException("Rejection reason is required.", nameof(reason));

        Status = DocumentStatus.Rejected;
        RejectionReason = reason;
        ReviewedBy = reviewedBy;
        ReviewedAt = DateTime.UtcNow;
        SetUpdated();
    }

    public bool IsPending() => Status == DocumentStatus.PendingReview;
}
