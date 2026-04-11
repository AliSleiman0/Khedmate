import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../providers/onboarding_providers.dart';
import '../domain/onboarding_status.dart';
import 'id_upload_screen.dart';
import 'skill_test_screen.dart';

class OnboardingHubScreen extends ConsumerWidget {
  const OnboardingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final statusAsync = ref.watch(onboardingStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.onboardingTitle),
        centerTitle: true,
      ),
      body: statusAsync.when(
        data: (status) => _buildContent(context, status, s),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(s.onboardingError(error.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(onboardingStatusProvider),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OnboardingStatus status, S s) {
    if (status.canAcceptJobs) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            Text(
              s.onboardingDone,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              s.onboardingCanAccept,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.onboardingGoToJobs),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.onboardingInstructions,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildStep(
          context, s,
          title: s.onboardingIdVerify,
          step: status.steps.idVerified,
          onTap: () => _navigateToIdUpload(context),
        ),
        const SizedBox(height: 16),
        _buildStep(
          context, s,
          title: s.onboardingSkillTest,
          step: status.steps.skillTested,
          onTap: () => _navigateToSkillTest(context),
          enabled: status.steps.idVerified.isComplete,
        ),
        const SizedBox(height: 16),
        _buildStep(
          context, s,
          title: s.onboardingPhoneVerify,
          step: status.steps.phoneVerified,
          onTap: null, // Auto-marked
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    S s, {
    required String title,
    required OnboardingStep step,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    IconData icon;
    Color color;
    String statusText;

    if (step.isComplete) {
      icon = Icons.check_circle;
      color = Colors.green;
      statusText = s.onboardingStepComplete;
    } else if (step.isPending) {
      icon = Icons.pending;
      color = Colors.amber;
      statusText = s.onboardingStepPending;
    } else if (step.isRejected) {
      icon = Icons.cancel;
      color = Colors.red;
      statusText = s.onboardingStepRejected;
    } else {
      icon = Icons.radio_button_unchecked;
      color = Colors.grey;
      statusText = s.onboardingStepRequired;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusText, style: TextStyle(color: color)),
            if (step.isRejected && step.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${s.onboardingReason}: ${step.rejectionReason}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        trailing: enabled && !step.isComplete
            ? const Icon(Icons.arrow_forward_ios)
            : null,
        onTap: enabled && !step.isComplete ? onTap : null,
        enabled: enabled && !step.isComplete,
      ),
    );
  }

  void _navigateToIdUpload(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IdUploadScreen()),
    );
  }

  void _navigateToSkillTest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SkillTestScreen()),
    );
  }
}
