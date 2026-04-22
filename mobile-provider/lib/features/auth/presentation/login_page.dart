import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;
  bool _showResendOtp = false;
  String _dialCode = '+961';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _showResendOtp = false;
    });
    if (!_formKey.currentState!.validate()) return;

    final phone = '$_dialCode${_phoneController.text.trim()}';

    await ref.read(authNotifierProvider.notifier).login(
          phone: phone,
          password: _passwordController.text,
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
        bool showResend = false;

        if (err is DioException) {
          if (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.receiveTimeout ||
              err.type == DioExceptionType.sendTimeout) {
            message = s.errorNetwork;
          } else {
            final code = _extractErrorCode(err);
            switch (code) {
              case 'INVALID_CREDENTIALS':
                message = s.errorInvalidCredentials;
                break;
              case 'EMAIL_NOT_VERIFIED':
                message = s.errorAccountNotVerified;
                showResend = true;
                break;
            }
          }
        }

        setState(() {
          _errorMessage = message;
          _showResendOtp = showResend;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final phone = '$_dialCode${_phoneController.text.trim()}';
    final s = S.of(ref);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final current = ref.read(localeProvider);
              ref.read(localeProvider.notifier).state =
                  current.languageCode == 'ar'
                      ? const Locale('en')
                      : const Locale('ar');
            },
            child: Text(
              s.langToggle,
              style: const TextStyle(
                color: AppColors.brandBlue,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Brand header
                  Text(
                    s.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontFamily: 'Cairo',
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_showResendOtp) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => context.go(
                                '/otp?phone=${Uri.encodeComponent(phone)}',
                              ),
                              child: Text(
                                s.resendCode,
                                style: TextStyle(
                                  color: AppColors.brandBlue,
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Phone field with country code
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        height: 56,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _dialCode,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            items: const [
                              DropdownMenuItem(value: '+966', child: Text('+966 🇸🇦')),
                              DropdownMenuItem(value: '+971', child: Text('+971 🇦🇪')),
                              DropdownMenuItem(value: '+965', child: Text('+965 🇰🇼')),
                              DropdownMenuItem(value: '+973', child: Text('+973 🇧🇭')),
                              DropdownMenuItem(value: '+968', child: Text('+968 🇴🇲')),
                              DropdownMenuItem(value: '+974', child: Text('+974 🇶🇦')),
                              DropdownMenuItem(value: '+962', child: Text('+962 🇯🇴')),
                              DropdownMenuItem(value: '+961', child: Text('+961 🇱🇧')),
                              DropdownMenuItem(value: '+20', child: Text('+20 🇪🇬')),
                              DropdownMenuItem(value: '+212', child: Text('+212 🇲🇦')),
                              DropdownMenuItem(value: '+1', child: Text('+1 🇺🇸')),
                              DropdownMenuItem(value: '+44', child: Text('+44 🇬🇧')),
                              DropdownMenuItem(value: '+33', child: Text('+33 🇫🇷')),
                              DropdownMenuItem(value: '+49', child: Text('+49 🇩🇪')),
                              DropdownMenuItem(value: '+91', child: Text('+91 🇮🇳')),
                              DropdownMenuItem(value: '+92', child: Text('+92 🇵🇰')),
                              DropdownMenuItem(value: '+880', child: Text('+880 🇧🇩')),
                              DropdownMenuItem(value: '+63', child: Text('+63 🇵🇭')),
                            ],
                            onChanged: (v) => setState(() => _dialCode = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: s.phoneNumber,
                            icon: Icons.phone_outlined,
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return s.phoneRequired;
                            }
                            final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                            if (digits.length < 7) return s.phoneInvalid;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _inputDecoration(
                      label: s.password,
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return s.passwordRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            SnackBar(
                              content: Text(
                                S.read(ref).forgotPasswordSoon,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                      child: Text(
                        s.forgotPassword,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s.signIn),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(
                      s.noAccount,
                      style: TextStyle(
                        color: AppColors.brandBlue,
                        fontFamily: 'Cairo',
                        fontSize: 15,
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Cairo'),
      prefixIcon: Icon(icon, color: AppColors.brandBlue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      errorStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.danger),
    );
  }
}
