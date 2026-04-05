using FluentValidation;

namespace Khudmati.Modules.Bookings.Application.Commands;

public class AdvanceJobStatusCommandValidator : AbstractValidator<AdvanceJobStatusCommand>
{
    public AdvanceJobStatusCommandValidator()
    {
        RuleFor(x => x.JobId).NotEmpty();
        RuleFor(x => x.ProviderId).NotEmpty();
    }
}
