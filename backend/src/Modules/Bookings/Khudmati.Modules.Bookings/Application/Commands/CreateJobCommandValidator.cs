using FluentValidation;

namespace Khudmati.Modules.Bookings.Application.Commands;

public class CreateJobCommandValidator : AbstractValidator<CreateJobCommand>
{
    private static readonly HashSet<string> ValidCategories =
        ["plumbing", "electrical", "cleaning", "carpentry", "painting", "ac_maintenance"];

    public CreateJobCommandValidator()
    {
        RuleFor(x => x.CategoryId)
            .NotEmpty()
            .Must(id => ValidCategories.Contains(id.ToLowerInvariant()))
            .WithMessage("CategoryId must be a valid service category.");

        RuleFor(x => x.Description)
            .NotEmpty()
            .MinimumLength(20)
            .WithMessage("Description must be at least 20 characters.")
            .MaximumLength(500);

        RuleFor(x => x.Latitude)
            .InclusiveBetween(-90, 90)
            .WithMessage("Latitude must be between -90 and 90.");

        RuleFor(x => x.Longitude)
            .InclusiveBetween(-180, 180)
            .WithMessage("Longitude must be between -180 and 180.");

        RuleFor(x => x.Address)
            .NotEmpty()
            .MaximumLength(500);
    }
}
