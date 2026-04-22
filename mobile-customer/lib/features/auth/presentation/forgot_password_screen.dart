import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _dialCode = '+966';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = '$_dialCode${_phoneController.text.trim()}';
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.forgotPassword(phone: phone);
      if (!mounted) return;
      context.push('/reset-password?phone=${Uri.encodeComponent(phone)}');
    } on DioException {
      setState(() => _errorMessage = S.read(ref).errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        title: Text(
          s.forgotPasswordTitle,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 72,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  s.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: AppColors.danger, fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Phone with dial code
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: s.phoneNumber,
                          labelStyle: const TextStyle(fontFamily: 'Cairo'),
                          prefixIcon:
                              const Icon(Icons.phone_outlined, color: AppColors.brandBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.brandBlue, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return s.phoneRequired;
                          final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 7) return s.phoneInvalid;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo'),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s.forgotPasswordSend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
