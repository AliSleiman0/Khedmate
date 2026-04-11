import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../data/auth_repository.dart';
import 'auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  static const _maxAttempts = 5;
  static const _timerDuration = 60;

  int _remainingSeconds = _timerDuration;
  int _remainingAttempts = _maxAttempts;
  bool _isLocked = false;
  bool _canResend = false;
  String? _errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _timerDuration;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _canResend = true;
        });
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _errorMessage = null;
      _isLocked = false;
      _remainingAttempts = _maxAttempts;
      _pinController.clear();
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resendOtp(widget.phone);
      _startTimer();
    } catch (_) {
      setState(() => _errorMessage = S.read(ref).otpResendError);
    }
  }

  Future<void> _submitOtp(String otp) async {
    if (_isLocked) return;
    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).verifyOtp(
          phone: widget.phone,
          otp: otp,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.when(
      data: (state) {
        if (state is AuthAuthenticated) {
          context.go('/jobs');
        }
      },
      loading: () {},
      error: (err, _) {
        final s = S.read(ref);
        String message = s.errorGeneric;
        bool enableResendImmediately = false;

        if (err is DioException) {
          final code = _extractErrorCode(err);
          switch (code) {
            case 'OTP_EXPIRED':
              message = s.otpExpired;
              enableResendImmediately = true;
              break;
            case 'MAX_ATTEMPTS_EXCEEDED':
              message = s.otpRequestNew;
              setState(() => _isLocked = true);
              enableResendImmediately = true;
              break;
            case 'INVALID_OTP':
              message = s.otpInvalid;
              setState(() {
                _remainingAttempts =
                    (_remainingAttempts - 1).clamp(0, _maxAttempts);
              });
              break;
            default:
              if (err.type == DioExceptionType.connectionError ||
                  err.type == DioExceptionType.receiveTimeout ||
                  err.type == DioExceptionType.sendTimeout) {
                message = s.errorNetwork;
              }
          }
          if (enableResendImmediately) {
            _timer?.cancel();
            setState(() {
              _remainingSeconds = 0;
              _canResend = true;
            });
          }
        }

        setState(() => _errorMessage = message);
        _pinController.clear();
        _pinFocusNode.requestFocus();
      },
    );
  }

  String _extractErrorCode(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        return (data['code'] as String?) ?? (data['error'] as String?) ?? '';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.brandBlue,
        fontFamily: 'Cairo',
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.brandBlue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        border: Border.all(color: AppColors.danger, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: Text(
            s.otpTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sms_outlined,
                  size: 64,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  s.otpSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandBlue,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 32),

                // OTP input
                Pinput(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  errorPinTheme: errorPinTheme,
                  enabled: !_isLocked && !isLoading,
                  autofocus: true,
                  onCompleted: _submitOtp,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Loading indicator
                if (isLoading)
                  const CircularProgressIndicator(color: AppColors.brandBlue),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Remaining attempts
                if (!_isLocked && _remainingAttempts < _maxAttempts)
                  Text(
                    s.otpAttemptsLeft(_remainingAttempts),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 24),

                // Countdown / Resend
                if (!_canResend)
                  Text(
                    s.otpResendIn(_remainingSeconds),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _resendOtp,
                    child: Text(
                      s.resendCode,
                      style: const TextStyle(
                        color: AppColors.brandBlue,
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
