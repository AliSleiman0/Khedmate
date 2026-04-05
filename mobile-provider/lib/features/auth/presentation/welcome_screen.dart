import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.brandBlue,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Logo / brand name
                const Text(
                  'خدمتي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline — provider-specific
                const Text(
                  'بوابة مزودي الخدمة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFFD6EAF8),
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
                // Provider CTA
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  child: const Text('أنا مزود خدمة'),
                ),
                const SizedBox(height: 32),
                // Customer link
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'للعملاء: قم بتحميل تطبيق خدمتي للعملاء',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                  child: const Text(
                    'هل أنت عميل؟',
                    style: TextStyle(
                      color: Color(0xFFD6EAF8),
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Login link
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: Color(0xFFD6EAF8),
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
