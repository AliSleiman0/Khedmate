import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../data/onboarding_api_service.dart';
import '../domain/onboarding_status.dart';

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
        data: (status) => _OnboardingHubBody(status: status),
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
                onPressed: () => ref.invalidate(onboardingStatusProvider),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHubBody extends ConsumerWidget {
  final OnboardingStatus status;

  const _OnboardingHubBody({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);

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
              onPressed: () => context.go('/provider/jobs'),
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
        _StepCard(
          title: s.onboardingIdVerify,
          step: status.steps.idVerified,
          onTap: () => context.push('/provider/onboarding/id-upload'),
        ),
        const SizedBox(height: 16),
        _StepCard(
          title: s.onboardingSkillTest,
          step: status.steps.skillTested,
          onTap: () => context.push('/provider/onboarding/skill-test'),
          enabled: status.steps.idVerified.isComplete,
        ),
        const SizedBox(height: 16),
        _StepCard(
          title: s.onboardingPhoneVerify,
          step: status.steps.phoneVerified,
          onTap: null,
        ),
      ],
    );
  }
}

class _StepCard extends ConsumerWidget {
  final String title;
  final OnboardingStep step;
  final VoidCallback? onTap;
  final bool enabled;

  const _StepCard({
    required this.title,
    required this.step,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
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
}
