import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import 'referral_provider.dart';

class ReferralScreen extends ConsumerWidget {
  final String? prefilledCode;
  const ReferralScreen({super.key, this.prefilledCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(referralNotifierProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'دعوة الأصدقاء',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: asyncState.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (e, _) => _ErrorState(
            onRefresh: () =>
                ref.read(referralNotifierProvider.notifier).refresh(),
          ),
          data: (state) => _ReferralBody(state: state, prefilledCode: prefilledCode),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------
class _ReferralBody extends ConsumerStatefulWidget {
  final ReferralState state;
  final String? prefilledCode;
  const _ReferralBody({required this.state, this.prefilledCode});

  @override
  ConsumerState<_ReferralBody> createState() => _ReferralBodyState();
}

class _ReferralBodyState extends ConsumerState<_ReferralBody> {
  final _codeController = TextEditingController();
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from deep link if provided — auto-expand the code input
    if (widget.prefilledCode != null && widget.prefilledCode!.isNotEmpty) {
      _codeController.text = widget.prefilledCode!.toUpperCase();
      _showCodeInput = true;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralNotifierProvider).valueOrNull ?? widget.state;
    final info = state.info;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'شارك كودك، كسب رصيداً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Referral code display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        info?.code ?? '--------',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.brandBlue),
                        onPressed: () {
                          if (info == null) return;
                          Clipboard.setData(ClipboardData(text: info.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الكود',
                                  style: TextStyle(fontFamily: 'Cairo')),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Share button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: info == null
                        ? null
                        : () => _shareCode(context, info.shareUrl, info.code),
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'مشاركة',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Reward explanation ─────────────────────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'كيف يعمل البرنامج؟',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RewardRow(
                    icon: Icons.percent,
                    color: AppColors.amber,
                    text: 'صديقك يحصل على 15% خصم في أول حجز',
                  ),
                  const SizedBox(height: 8),
                  _RewardRow(
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.success,
                    text: 'أنت تحصل على 20 ر.س رصيد في محفظتك',
                  ),
                  const SizedBox(height: 8),
                  _RewardRow(
                    icon: Icons.check_circle_outline,
                    color: AppColors.brandBlue,
                    text: 'الرصيد يُطبَّق تلقائياً في حجزك القادم',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Credit balance card ────────────────────────────────────────
          if (info != null && info.creditBalance > 0)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رصيدك الحالي: ${info.creditBalance.toStringAsFixed(2)} ر.س',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const Text(
                          'يُطبَّق تلقائياً في حجزك القادم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (info != null && info.creditBalance > 0) const SizedBox(height: 16),

          // ── Friends count ──────────────────────────────────────────────
          if (info != null && info.referralsCompleted > 0)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, color: AppColors.brandBlue),
                    const SizedBox(width: 12),
                    Text(
                      'دعوت ${info.referralsCompleted} أصدقاء حتى الآن ✓',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (info != null && info.referralsCompleted > 0) const SizedBox(height: 16),

          // ── Enter referral code (collapsible) ──────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _showCodeInput = !_showCodeInput),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'هل لديك كود دعوة؟',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Icon(
                          _showCodeInput
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppColors.brandBlue,
                        ),
                      ],
                    ),
                  ),
                  if (_showCodeInput) ...[
                    const SizedBox(height: 12),
                    _ApplyCodeSection(
                      controller: _codeController,
                      isLoading: state.isApplyingCode,
                      error: state.applyError,
                      successMessage: state.applySuccessMessage,
                      onSubmit: () => ref
                          .read(referralNotifierProvider.notifier)
                          .applyCode(_codeController.text),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCode(
      BuildContext context, String shareUrl, String code) async {
    // Use url_launcher to attempt sharing via WhatsApp or fallback to copy
    final message =
        'استخدم كودي $code على تطبيق خدمتي واحصل على خصم 15% في أول حجز! $shareUrl';
    final uri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم نسخ الرسالة — شاركها مع أصدقائك!',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Apply code section widget
// ---------------------------------------------------------------------------
class _ApplyCodeSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final VoidCallback onSubmit;

  const _ApplyCodeSection({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    this.error,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (successMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              successMessage!,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.success,
                  fontSize: 13),
            ),
          ),
        if (successMessage != null) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: 3,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'KHUD1A2B',
                  hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      letterSpacing: 2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.brandBlue, width: 2),
                  ),
                  errorText: error,
                ),
                maxLength: 10,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تطبيق',
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------
class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RewardRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ErrorState({required this.onRefresh});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('تعذر التحميل',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
}
