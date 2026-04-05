using Khudmati.Modules.Providers.Application.DTOs;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;
using Khudmati.Modules.Providers.Infrastructure.Persistence;
using Khudmati.Shared.Application;
using MediatR;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace Khudmati.Modules.Providers.Application.Commands;

public record SubmitDocumentsCommand(
    Guid ProviderId,
    DocumentType DocumentType,
    IFormFile FrontImage,
    IFormFile? BackImage
) : IRequest<Result<DocumentSubmissionResultDto>>;

public class SubmitDocumentsCommandHandler : IRequestHandler<SubmitDocumentsCommand, Result<DocumentSubmissionResultDto>>
{
    private readonly IDocumentSubmissionRepository _submissionRepo;
    private readonly IWebHostEnvironment _environment;

    public SubmitDocumentsCommandHandler(
        IDocumentSubmissionRepository submissionRepo,
        IWebHostEnvironment environment)
    {
        _submissionRepo = submissionRepo;
        _environment = environment;
    }

    public async Task<Result<DocumentSubmissionResultDto>> Handle(
        SubmitDocumentsCommand request, CancellationToken cancellationToken)
    {
        // Check if there's already a pending submission
        var existingPending = await _submissionRepo.GetPendingByProviderIdAsync(request.ProviderId, cancellationToken);
        if (existingPending != null)
            return Result<DocumentSubmissionResultDto>.Fail("SUBMISSION_ALREADY_PENDING");

        // Validate file sizes and types
        const long maxFileSize = 5 * 1024 * 1024; // 5MB
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".pdf" };

        if (request.FrontImage.Length > maxFileSize)
            return Result<DocumentSubmissionResultDto>.Fail("FILE_TOO_LARGE");

        var frontExt = Path.GetExtension(request.FrontImage.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(frontExt))
            return Result<DocumentSubmissionResultDto>.Fail("UNSUPPORTED_FILE_TYPE");

        if (request.BackImage != null)
        {
            if (request.BackImage.Length > maxFileSize)
                return Result<DocumentSubmissionResultDto>.Fail("FILE_TOO_LARGE");

            var backExt = Path.GetExtension(request.BackImage.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(backExt))
                return Result<DocumentSubmissionResultDto>.Fail("UNSUPPORTED_FILE_TYPE");
        }

        // Save files
        var uploadsDir = Path.Combine(_environment.WebRootPath, "uploads", "providers", request.ProviderId.ToString(), "documents");
        Directory.CreateDirectory(uploadsDir);

        var frontFileName = $"front_{Guid.NewGuid()}{frontExt}";
        var frontPath = Path.Combine(uploadsDir, frontFileName);
        await using (var stream = File.Create(frontPath))
        {
            await request.FrontImage.CopyToAsync(stream, cancellationToken);
        }
        var frontUrl = $"/uploads/providers/{request.ProviderId}/documents/{frontFileName}";

        string? backUrl = null;
        if (request.BackImage != null)
        {
            var backExt = Path.GetExtension(request.BackImage.FileName).ToLowerInvariant();
            var backFileName = $"back_{Guid.NewGuid()}{backExt}";
            var backPath = Path.Combine(uploadsDir, backFileName);
            await using (var stream = File.Create(backPath))
            {
                await request.BackImage.CopyToAsync(stream, cancellationToken);
            }
            backUrl = $"/uploads/providers/{request.ProviderId}/documents/{backFileName}";
        }

        // Create submission
        var submission = DocumentSubmission.Create(request.ProviderId, request.DocumentType, frontUrl, backUrl);
        await _submissionRepo.AddAsync(submission, cancellationToken);
        await _submissionRepo.SaveChangesAsync(cancellationToken);

        return Result<DocumentSubmissionResultDto>.Ok(new DocumentSubmissionResultDto(
            submission.Id,
            "PendingReview"
        ));
    }
}
