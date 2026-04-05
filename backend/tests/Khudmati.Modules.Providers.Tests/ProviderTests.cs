using Xunit;
using FluentAssertions;
using Khudmati.Modules.Providers.Domain.Entities;
using Khudmati.Modules.Providers.Domain.Enums;

namespace Khudmati.Modules.Providers.Tests;

public class ProviderTests
{
    [Fact]
    public void Create_SetsDefaultTierToUnverified()
    {
        var provider = Provider.Create("Khalid Ahmed", "+966501234567", null, "hash", new[] { "cleaning" });
        provider.Tier.Should().Be(VerificationTier.Unverified);
        provider.IsOnline.Should().BeFalse();
    }

    [Fact]
    public void UpgradeTier_Succeeds_WhenNewTierIsHigher()
    {
        var provider = Provider.Create("Khalid Ahmed", "+966501234567", null, "hash", new[] { "cleaning" });
        provider.UpgradeTier(VerificationTier.PhoneVerified);
        provider.Tier.Should().Be(VerificationTier.PhoneVerified);
    }

    [Fact]
    public void UpgradeTier_Throws_WhenDowngrading()
    {
        var provider = Provider.Create("Khalid Ahmed", "+966501234567", null, "hash", new[] { "cleaning" });
        provider.UpgradeTier(VerificationTier.IdVerified);
        var act = () => provider.UpgradeTier(VerificationTier.PhoneVerified);
        act.Should().Throw<InvalidOperationException>();
    }

    [Fact]
    public void UpdateRating_Throws_WhenOutOfRange()
    {
        var provider = Provider.Create("Khalid Ahmed", "+966501234567", null, "hash", new[] { "cleaning" });
        var act = () => provider.UpdateRating(6.0);
        act.Should().Throw<ArgumentOutOfRangeException>();
    }
}
