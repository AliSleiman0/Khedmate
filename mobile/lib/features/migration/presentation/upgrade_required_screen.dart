import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/back_chip.dart';

/// Defensive full-screen shown when any HTTP call returns `UPGRADE_REQUIRED`.
/// Under the Phase 10 hard-cutover strategy this should only ever fire on the
/// legacy customer / provider bundles — but if a token ever bleeds across
/// bundle ids (shared iCloud restore, device migration tools, etc.) this
/// ensures the unified app fails closed with a helpful screen instead of
/// a silent login error.
class UpgradeRequiredScreen extends ConsumerWidget {
  const UpgradeRequiredScreen({super.key, this.storeUrl});

  final String? storeUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final title = isAr ? 'يتوفر تحديث مطلوب' : 'Update Required';
    final body = isAr
        ? 'لقد أطلقنا تطبيق خدمتي الموحّد. يرجى تنزيل النسخة الجديدة للمتابعة.'
        : 'We launched the unified Khudmati app. Please download the new '
            'version to continue.';
    final cta = isAr ? 'تنزيل التطبيق' : 'Download App';

    final url = storeUrl ??
        (kIsWeb
            ? AppConfig.androidStoreUrl
            : (Platform.isIOS
                ? AppConfig.iosStoreUrl
                : AppConfig.androidStoreUrl));

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                size: 96,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openStore(url),
                  child: Text(
                    cta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Let the user retry in case the gate was transient
                  // (e.g. staging backend flipped back to off).
                  ref.read(upgradeRequiredProvider.notifier).state = null;
                },
                child: Text(
                  isAr ? 'إعادة المحاولة' : 'Retry',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
            ),
          ),
          const BackChip(
            background: Colors.white,
            iconColor: AppColors.brandBlue,
          ),
        ],
      ),
    );
  }

  Future<void> _openStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
