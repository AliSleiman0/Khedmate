using FluentValidation;
using Khudmati.Modules.Providers.Application.Commands.Auth;

namespace Khudmati.Modules.Providers.Application.Validators;

public class RegisterProviderValidator : AbstractValidator<RegisterProviderCommand>
{
    public RegisterProviderValidator()
    {
        RuleFor(x => x.Phone)
            .NotEmpty().WithMessage("Phone is required.")
            .Matches(@"^\+?[0-9]{7,15}$").WithMessage("Phone must be a valid number (7–15 digits, optional leading +).");

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full name is required.")
            .Length(2, 100).WithMessage("Full name must be between 2 and 100 characters.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters.");

        RuleFor(x => x.ServiceCategories)
            .NotNull().WithMessage("Service categories are required.")
            .Must(c => c != null && c.Length > 0).WithMessage("At least one service category must be provided.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.");
    }
}
