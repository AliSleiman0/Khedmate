import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/widgets/app_back_button.dart';
import 'auth_provider.dart';

const _tag = 'RegisterScreen';

// Service category keys (resolved to localized labels via S.categoryLabel).
const _providerServiceCategories = [
  'plumbing',
  'electrical',
  'cleaning',
  'carpentry',
  'painting',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  final Set<String> _selectedCategories = {};
  String _dialCode = '+961';

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      log.d(_tag, 'submit blocked', data: {'reason': 'validation_failed'});
      return;
    }

    final isProvider = ref.read(roleProvider) == UserRole.provider;
    if (isProvider && _selectedCategories.isEmpty) {
      log.d(_tag, 'submit blocked', data: {'reason': 'no_categories'});
      setState(() => _errorMessage = S.read(ref).categoryRequired);
      return;
    }

    log.d(_tag, 'submit', data: {
      'role': isProvider ? 'provider' : 'customer',
      'categoryCount': isProvider ? _selectedCategories.length : null,
    });

    final phone = '$_dialCode${_phoneController.text.trim()}';

    await ref.read(authNotifierProvider.notifier).register(
          fullName: _fullNameController.text.trim(),
          phone: phone,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          serviceCategories: isProvider ? _selectedCategories.toList() : null,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.when(
      data: (state) {
        if (state is AuthOtpPending) {
          log.i(_tag, 'nav next', data: {'target': '/otp'});
          context.go('/otp?phone=${Uri.encodeComponent(state.phone)}');
        }
      },
      loading: () {},
      error: (err, _) {
        final s = S.read(ref);
        String message = s.errorGeneric;
        if (err is DioException) {
          if (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.receiveTimeout ||
              err.type == DioExceptionType.sendTimeout) {
            message = s.errorNetwork;
          } else {
            final code = _extractErrorCode(err);
            if (code == 'PHONE_ALREADY_REGISTERED') {
              message = s.errorPhoneAlreadyRegistered;
            } else if (code == 'EMAIL_ALREADY_REGISTERED') {
              message = s.errorEmailAlreadyUsed;
            }
          }
        }
        setState(() => _errorMessage = message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final s = S.of(ref);
    final isProvider = ref.watch(roleProvider) == UserRole.provider;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        leading: const AppBackButton(),
        title: Text(
          s.registerTitle,
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              final current = ref.read(localeProvider);
              ref.read(localeProvider.notifier).setLocale(
                    current.languageCode == 'ar'
                        ? const Locale('en')
                        : const Locale('ar'),
                  );
            },
            child: Text(
              s.langToggle,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: s.fullName,
                    icon: Icons.person_outline,
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return s.fullNameRequired;
                    }
                    if (v.trim().length < 3) {
                      return s.fullNameTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialCodeDropdown(),
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
                          final digits =
                              v.trim().replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 7) return s.phoneInvalid;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: s.email,
                    icon: Icons.email_outlined,
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return s.emailRequired;
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(v.trim())) return s.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.passwordRequired;
                    if (v.length < 8) return s.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _inputDecoration(
                    label: s.confirmPassword,
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return s.confirmPasswordRequired;
                    }
                    if (v != _passwordController.text) {
                      return s.passwordsMismatch;
                    }
                    return null;
                  },
                ),

                if (isProvider) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Text(
                            s.serviceCategories,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        for (final key in _providerServiceCategories)
                          CheckboxListTile(
                            value: _selectedCategories.contains(key),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedCategories.add(key);
                                } else {
                                  _selectedCategories.remove(key);
                                }
                              });
                            },
                            title: Text(
                              s.categoryLabel(key),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                              ),
                            ),
                            activeColor: AppColors.brandBlue,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

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
                      : Text(s.createAccountButton),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    s.alreadyHaveAccount,
                    style: const TextStyle(
                      color: AppColors.brandBlue,
                      fontFamily: 'Cairo',
                      fontSize: 14,
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

  Widget _dialCodeDropdown() {
    return Container(
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
