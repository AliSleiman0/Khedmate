import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../booking/presentation/booking_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _raiseDisputeProvider = StateNotifierProvider.autoDispose
    .family<_RaiseDisputeNotifier, _RaiseDisputeState, String>(
  (ref, jobId) => _RaiseDisputeNotifier(ref.read(apiClientProvider), jobId),
);

class _RaiseDisputeState {
  final bool isLoading;
  final bool success;
  final String? errorCode;

  const _RaiseDisputeState({
    this.isLoading = false,
    this.success = false,
    this.errorCode,
  });

  _RaiseDisputeState copyWith({
    bool? isLoading,
    bool? success,
    String? errorCode,
    bool clearError = false,
  }) =>
      _RaiseDisputeState(
        isLoading: isLoading ?? this.isLoading,
        success: success ?? this.success,
        errorCode: clearError ? null : errorCode ?? this.errorCode,
      );
}

class _RaiseDisputeNotifier extends StateNotifier<_RaiseDisputeState> {
  final ApiClient _client;
  final String _jobId;

  _RaiseDisputeNotifier(this._client, this._jobId)
      : super(const _RaiseDisputeState());

  Future<void> submit(String complaint) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _client.dio.post(
        '/bookings/jobs/$_jobId/dispute',
        data: {'complaint': complaint},
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      String? code;
      try {
        final data = (e as dynamic).response?.data as Map<String, dynamic>?;
        code = data?['error'] as String?;
      } catch (_) {}
      state = state.copyWith(isLoading: false, errorCode: code ?? 'UNKNOWN_ERROR');
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RaiseDisputeScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String referenceNumber;

  const RaiseDisputeScreen({
    super.key,
    required this.jobId,
    required this.referenceNumber,
  });

  @override
  ConsumerState<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends ConsumerState<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  static const int _maxChars = 1000;
  static const int _minChars = 20;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _errorMessage(String code, S s) {
    switch (code) {
      case 'DISPUTE_WINDOW_CLOSED':
        return s.disputeDeadline;
      case 'DISPUTE_ALREADY_EXISTS':
        return s.disputeAlreadyRaised;
      case 'DISPUTE_NOT_ALLOWED_IN_CURRENT_STATUS':
        return s.disputeInvalidStatus;
      default:
        return s.disputeGenericError;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(_raiseDisputeProvider(widget.jobId).notifier)
        .submit(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    ref.listen(_raiseDisputeProvider(widget.jobId), (_, next) {
      if (next.success) {
        _showSuccessSheet(context);
      } else if (next.errorCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage(next.errorCode!, S.read(ref)),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final state = ref.watch(_raiseDisputeProvider(widget.jobId));
    final charCount = _controller.text.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.disputeTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.brandBlue.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${s.historyOrderNo}: ${widget.referenceNumber}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Explainer text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Text(
                      'إذا لم تكن راضياً عن الخدمة، يرجى وصف المشكلة أدناه. سيقوم فريقنا بمراجعة حالتك خلال 24 ساعة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Complaint field
                  const Text(
                    'تفاصيل الشكوى',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller,
                    maxLength: _maxChars,
                    maxLines: 8,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        Text(
                      '$currentLength / $_maxChars حرف',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: currentLength < _minChars
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().length < _minChars) {
                        return 'يجب أن تحتوي الشكوى على $_minChars حرفاً على الأقل.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'اشرح مشكلتك بالتفصيل…',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.brandBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: state.isLoading || charCount < _minChars
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        disabledBackgroundColor:
                            AppColors.brandBlue.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'إرسال الشكوى',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم رفع شكواك بنجاح',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'سيتواصل معك فريق الدعم خلال 24 ساعة.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close sheet
                    Navigator.of(context).pop(); // pop raise-dispute screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    S.read(ref).disputeOkay,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
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
