import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/signalr_service.dart';
import 'booking_provider.dart';

class _ConfirmationStatus {
  final bool isSearching;
  final bool isAccepted;
  final bool isExpired;
  final String? providerName;
  final String? providerPhone;
  final double? providerRating;

  const _ConfirmationStatus({
    this.isSearching = true,
    this.isAccepted = false,
    this.isExpired = false,
    this.providerName,
    this.providerPhone,
    this.providerRating,
  });

  _ConfirmationStatus copyWith({
    bool? isSearching,
    bool? isAccepted,
    bool? isExpired,
    String? providerName,
    String? providerPhone,
    double? providerRating,
  }) =>
      _ConfirmationStatus(
        isSearching: isSearching ?? this.isSearching,
        isAccepted: isAccepted ?? this.isAccepted,
        isExpired: isExpired ?? this.isExpired,
        providerName: providerName ?? this.providerName,
        providerPhone: providerPhone ?? this.providerPhone,
        providerRating: providerRating ?? this.providerRating,
      );
}

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  _ConfirmationStatus _status = const _ConfirmationStatus();

  @override
  void initState() {
    super.initState();
    _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    final service = ref.read(signalRServiceProvider);
    try {
      await service.connect();
    } catch (_) {
      return;
    }

    final booking = ref.read(bookingNotifierProvider).valueOrNull;
    final jobId = booking?.createdJobId;
    if (jobId == null) return;

    await service.invoke('JoinJobGroup', [jobId]);

    service.on('JobAccepted', (args) {
      if (!mounted) return;
      try {
        final data = args?[0] as Map<String, dynamic>?;
        if (data == null) return;
        if (data['jobId'].toString() != jobId) return;

        setState(() {
          _status = _ConfirmationStatus(
            isSearching: false,
            isAccepted: true,
            providerName: data['providerName'] as String?,
            providerPhone: data['providerPhone'] as String?,
            providerRating: (data['providerRating'] as num?)?.toDouble(),
          );
        });
      } catch (_) {}
    });

    service.on('JobExpired', (args) {
      if (!mounted) return;
      try {
        final data = args?[0] as Map<String, dynamic>?;
        if (data == null) return;
        if (data['jobId'].toString() != jobId) return;

        setState(() {
          _status = const _ConfirmationStatus(
              isSearching: false, isExpired: true);
        });
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingNotifierProvider).valueOrNull;
    final refNumber = booking?.referenceNumber ?? '-';
    final jobId = booking?.createdJobId;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _status.isAccepted
                  ? _AcceptedBody(
                      refNumber: refNumber,
                      jobId: jobId,
                      status: _status,
                    )
                  : _status.isExpired
                      ? _ExpiredBody(
                          onRetry: () {
                            ref
                                .read(bookingNotifierProvider.notifier)
                                .reset();
                            context.go('/customer/booking/category');
                          },
                        )
                      : _SearchingBody(refNumber: refNumber, jobId: jobId),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchingBody extends ConsumerWidget {
  final String refNumber;
  final String? jobId;

  const _SearchingBody({required this.refNumber, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AnimatedCheckmark(),
        const SizedBox(height: 32),
        Text(
          s.confirmTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandBlue),
            ),
            const SizedBox(width: 10),
            Text(
              s.confirmSearching,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _RefBadge(refNumber: refNumber),
        const SizedBox(height: 40),
        if (jobId != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/customer/tracking/$jobId'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.confirmViewDetails,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ref.read(bookingNotifierProvider.notifier).reset();
              context.go('/customer/home');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(color: AppColors.brandBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.backHome,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _AcceptedBody extends ConsumerWidget {
  final String refNumber;
  final String? jobId;
  final _ConfirmationStatus status;

  const _AcceptedBody({
    required this.refNumber,
    required this.jobId,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: Colors.green, size: 90),
        const SizedBox(height: 20),
        Text(
          s.confirmAcceptedTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (status.providerName != null) ...[
          Text(
            status.providerName!,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.amber, size: 18),
              Text(
                ' ${status.providerRating?.toStringAsFixed(1) ?? '-'}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _RefBadge(refNumber: refNumber),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: jobId != null
                ? () => context.go('/customer/tracking/$jobId')
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.confirmTrackProvider,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ref.read(bookingNotifierProvider.notifier).reset();
              context.go('/customer/home');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(color: AppColors.brandBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.backHome,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 17)),
          ),
        ),
      ],
    );
  }
}

class _ExpiredBody extends ConsumerWidget {
  final VoidCallback onRetry;

  const _ExpiredBody({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_off_outlined,
            size: 90, color: AppColors.danger),
        const SizedBox(height: 20),
        Text(
          s.confirmExpiredTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          s.confirmExpiredSub,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.retry,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _RefBadge extends ConsumerWidget {
  final String refNumber;

  const _RefBadge({required this.refNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            s.receiptOrderNo,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            refNumber,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCheckmark extends StatefulWidget {
  @override
  State<_AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<_AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green.shade300, width: 3),
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: Colors.green.shade500,
          size: 72,
        ),
      ),
    );
  }
}
