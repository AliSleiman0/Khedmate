import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../providers/locale_provider.dart';

/// Full-screen takeover shown when the backend returns `UPGRADE_REQUIRED`.
/// Part of the Phase 10 hard-cutover: this legacy provider build is retired
/// in favour of the unified `com.khudmati.app`.
class UpgradeRequiredScreen extends ConsumerWidget {
  const UpgradeRequiredScreen({super.key, required this.storeUrl});

  final String storeUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final title = isAr ? 'تطبيق خدمتي الجديد' : 'The New Khudmati App';
    final body = isAr
        ? 'لقد دمجنا تطبيقَي العميل والمزوّد في تطبيق واحد. يُرجى تنزيل '
            'تطبيق خدمتي الجديد للمتابعة — أرباحك، تقييماتك، واشتراكك '
            'محفوظة.'
        : "We've merged the customer and provider apps into one. Please "
            "download the new Khudmati app to continue — your earnings, "
            "ratings, and subscription are preserved.";
    final cta = isAr ? 'تنزيل التطبيق الجديد' : 'Download New App';

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch_rounded,
                  size: 96, color: Colors.white),
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
                  onPressed: () async {
                    final uri = Uri.parse(storeUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    cta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
