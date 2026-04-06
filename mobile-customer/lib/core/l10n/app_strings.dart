import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

/// Type-safe string accessor. Use [S.of(ref)] in any ConsumerWidget.
class S {
  final bool isAr;
  const S._(this.isAr);

  static S of(WidgetRef ref) =>
      S._(ref.watch(localeProvider).languageCode == 'ar');

  /// Use inside callbacks / non-widget contexts where ref.watch isn't available.
  static S read(WidgetRef ref) =>
      S._(ref.read(localeProvider).languageCode == 'ar');

  // ── Language toggle ─────────────────────────────────────────────────────────
  /// Label of the OTHER language (tap to switch).
  String get langToggle => isAr ? 'English' : 'عربي';

  // ── App identity ────────────────────────────────────────────────────────────
  String get appName => isAr ? 'خدمتي' : 'Khudmati';
  String get tagline =>
      isAr ? 'خدمتك في راحة يدك' : 'Your service, at your fingertips';

  // ── Welcome ─────────────────────────────────────────────────────────────────
  String get createAccount => isAr ? 'إنشاء حساب' : 'Create Account';
  String get signIn => isAr ? 'تسجيل الدخول' : 'Sign In';

  // ── Login ───────────────────────────────────────────────────────────────────
  String get welcomeBack => isAr ? 'مرحباً بك مجدداً' : 'Welcome Back';
  String get phoneNumber => isAr ? 'رقم الهاتف' : 'Phone Number';
  String get countryCode => isAr ? 'الرمز' : 'Code';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get noAccount =>
      isAr ? 'ليس لديك حساب؟ إنشاء حساب' : "Don't have an account? Register";

  // ── Register ─────────────────────────────────────────────────────────────────
  String get registerTitle =>
      isAr ? 'إنشاء حساب جديد' : 'Create New Account';
  String get fullName => isAr ? 'الاسم الكامل' : 'Full Name';
  String get emailOptional =>
      isAr ? 'البريد الإلكتروني (اختياري)' : 'Email (optional)';
  String get confirmPassword =>
      isAr ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get createAccountButton =>
      isAr ? 'إنشاء الحساب' : 'Create Account';
  String get alreadyHaveAccount =>
      isAr ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'Already have an account? Sign In';

  // ── Validation ───────────────────────────────────────────────────────────────
  String get phoneRequired =>
      isAr ? 'رقم الهاتف مطلوب' : 'Phone number is required';
  String get phoneInvalid =>
      isAr ? 'أدخل رقم هاتف صحيح' : 'Enter a valid phone number';
  String get passwordRequired =>
      isAr ? 'كلمة المرور مطلوبة' : 'Password is required';
  String get passwordTooShort =>
      isAr ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
           : 'Password must be at least 8 characters';
  String get fullNameRequired =>
      isAr ? 'الاسم الكامل مطلوب' : 'Full name is required';
  String get fullNameTooShort =>
      isAr ? 'الاسم يجب أن يكون 3 أحرف على الأقل'
           : 'Name must be at least 3 characters';
  String get emailInvalid =>
      isAr ? 'أدخل بريد إلكتروني صحيح' : 'Enter a valid email';
  String get confirmPasswordRequired =>
      isAr ? 'تأكيد كلمة المرور مطلوب' : 'Please confirm your password';
  String get passwordsMismatch =>
      isAr ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';

  // ── API / network errors ─────────────────────────────────────────────────────
  String get errorGeneric =>
      isAr ? 'حدث خطأ. حاول مرة أخرى' : 'Something went wrong. Try again.';
  String get errorNetwork =>
      isAr ? 'تحقق من اتصالك بالإنترنت' : 'Check your internet connection';
  String get errorInvalidCredentials =>
      isAr ? 'رقم الهاتف أو كلمة المرور غير صحيحة'
           : 'Phone or password is incorrect';
  String get errorAccountNotVerified =>
      isAr ? 'لم يتم التحقق من حسابك' : 'Your account is not verified';
  String get resendCode =>
      isAr ? 'إعادة إرسال الرمز' : 'Resend Code';
  String get errorPhoneAlreadyRegistered =>
      isAr ? 'هذا الرقم مسجل مسبقاً' : 'This phone number is already registered';
}
