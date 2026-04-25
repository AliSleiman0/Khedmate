import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../auth/presentation/auth_provider.dart';
import 'profile_tiles_customer.dart';
import 'profile_tiles_provider.dart';

const _tag = 'ProfilePage';

/// Build version shown at the bottom of the profile page. Matches
/// `pubspec.yaml: version`. Long-press in `kDebugMode` opens the log viewer.
const _kAppVersionLabel = 'v1.0.0+1';

/// Shared profile shell. The header (avatar + name + phone) and the logout
/// tile are identical across roles; the middle tile list is delegated to a
/// role-specific builder.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final role = ref.watch(roleProvider);
    final authValue = ref.watch(authNotifierProvider).valueOrNull;
    final user =
        authValue is AuthAuthenticated ? authValue.user : null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(color: AppColors.ink),
        title: Text(
          s.profileTitle,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: ListView(
        children: [
          _ProfileHeader(
            fullName: user?.fullName ?? '—',
            phone: user?.phone ?? '—',
            isProvider: role == UserRole.provider,
            verificationLabel: s.profileVerification,
          ),
          const SizedBox(height: 8),
          if (role == UserRole.provider)
            const ProviderProfileTiles()
          else
            const CustomerProfileTiles(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: Text(
              s.profileLogout,
              style: const TextStyle(
                color: AppColors.danger,
                fontFamily: 'Cairo',
              ),
            ),
            onTap: () async {
              log.d(_tag, 'logout tap', data: {'role': role?.name});
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: kDebugMode
                  ? () {
                      log.d(_tag, 'long-press version → /debug/logs');
                      context.push('/debug/logs');
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _kAppVersionLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String phone;
  final bool isProvider;
  final String verificationLabel;

  const _ProfileHeader({
    required this.fullName,
    required this.phone,
    required this.isProvider,
    required this.verificationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandBlue,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 44, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isProvider) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verificationLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
