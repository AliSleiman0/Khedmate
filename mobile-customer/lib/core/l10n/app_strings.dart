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
  String get forgotPassword => isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?';
  String get loginWithPhone => isAr ? 'رقم الهاتف' : 'Phone';
  String get loginWithEmail => isAr ? 'بريد إلكتروني' : 'Email';

  // ── Register ─────────────────────────────────────────────────────────────────
  String get registerTitle =>
      isAr ? 'إنشاء حساب جديد' : 'Create New Account';
  String get fullName => isAr ? 'الاسم الكامل' : 'Full Name';
  String get emailOptional =>
      isAr ? 'البريد الإلكتروني (اختياري)' : 'Email (optional)';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email';
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
  String get emailRequired =>
      isAr ? 'البريد الإلكتروني مطلوب' : 'Email is required';
  String get errorEmailAlreadyUsed =>
      isAr ? 'هذا البريد الإلكتروني مسجل مسبقاً' : 'This email is already registered';
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

  // ── Nav bar ──────────────────────────────────────────────────────────────────
  String get navHome          => isAr ? 'الرئيسية' : 'Home';
  String get navBookings      => isAr ? 'حجوزاتي'  : 'My Bookings';
  String get navBook          => isAr ? 'احجز'      : 'Book';
  String get navNotifications => isAr ? 'إشعارات'  : 'Alerts';
  String get navProfile       => isAr ? 'حسابي'     : 'Profile';

  // ── Home ─────────────────────────────────────────────────────────────────────
  String get homeTitle         => isAr ? 'خدمتي'            : 'Khudmati';
  String get homeSearchHint    => isAr ? 'ماذا تحتاج؟'       : 'What do you need?';
  String get homeSelectService => isAr ? 'اختر الخدمة'       : 'Select Service';
  String get homePendingRating => isAr ? 'لديك تقييم معلق'   : 'You have a pending rating';
  String get homeRateNow       => isAr ? 'قيّم الآن'         : 'Rate Now';

  // ── Service categories ────────────────────────────────────────────────────────
  String get catCleaning   => isAr ? 'تنظيف'   : 'Cleaning';
  String get catPlumbing   => isAr ? 'سباكة'   : 'Plumbing';
  String get catElectrical => isAr ? 'كهرباء'  : 'Electrical';
  String get catMoving     => isAr ? 'نقل عفش' : 'Moving';
  String get catPainting   => isAr ? 'دهانات'  : 'Painting';
  String get catAC         => isAr ? 'تكييف'   : 'AC Maintenance';
  String get catCarpentry  => isAr ? 'نجارة'   : 'Carpentry';
  String get catOther      => isAr ? 'أخرى'    : 'Other';

  // ── Job / payment statuses ────────────────────────────────────────────────────
  String get statusPending     => isAr ? 'معلّق'               : 'Pending';
  String get statusAccepted    => isAr ? 'مقبول'               : 'Accepted';
  String get statusEnRoute     => isAr ? 'في الطريق'           : 'En Route';
  String get statusInProgress  => isAr ? 'جاري التنفيذ'        : 'In Progress';
  String get statusCompleted   => isAr ? 'مكتمل'               : 'Completed';
  String get statusPaid        => isAr ? 'مدفوع'               : 'Paid';
  String get statusExpired     => isAr ? 'منتهي'               : 'Expired';
  String get statusOnHold      => isAr ? 'محجوز (فترة النزاع)' : 'On Hold';
  String get statusTransferred => isAr ? 'تم التحويل'          : 'Transferred';
  String get statusDisputed    => isAr ? 'نزاع'                : 'Disputed';
  String get statusRefunded    => isAr ? 'مسترجع'              : 'Refunded';

  // ── Shared UI ────────────────────────────────────────────────────────────────
  String get retry    => isAr ? 'إعادة المحاولة' : 'Retry';
  String get backHome => isAr ? 'العودة للرئيسية' : 'Back to Home';
  String get next     => isAr ? 'التالي'          : 'Next';
  String get back     => isAr ? 'السابق'          : 'Back';
  String get skip     => isAr ? 'تخطي'            : 'Skip';
  String get apply    => isAr ? 'تطبيق'           : 'Apply';

  // ── Booking ──────────────────────────────────────────────────────────────────
  String get catScreenTitle        => isAr ? 'احجز خدمة'                          : 'Book a Service';
  String get catSelectType         => isAr ? 'اختر نوع الخدمة'                    : 'Select Service Type';
  String get descScreenTitle       => isAr ? 'تفاصيل الخدمة'                      : 'Service Details';
  String get descHint              => isAr ? 'صِف المشكلة أو الخدمة المطلوبة'     : 'Describe the problem or required service';
  String get descAiImproved        => isAr ? 'الوصف المحسّن بالذكاء الاصطناعي'    : 'AI-Improved Description';
  String get descAiDismiss         => isAr ? 'تجاهل'                              : 'Dismiss';
  String get descAiUse             => isAr ? 'استخدم هذا الوصف'                   : 'Use This Description';
  String get descAiError           => isAr ? 'تعذر تحسين النص، حاول مجدداً'       : 'Could not improve text. Try again.';
  String get descAiImproving       => isAr ? 'جارٍ التحسين...'                    : 'Improving...';
  String get descAiButton          => isAr ? 'تحسين بالذكاء الاصطناعي'            : 'Improve with AI';
  String get descTooShort          => isAr ? 'الوصف قصير جداً، أضف تفاصيل أكثر'  : 'Description too short, add more details';
  String get descPhotos            => isAr ? 'صور (اختياري)'                      : 'Photos (optional)';
  String get locTitle              => isAr ? 'حدد موقع الخدمة'                    : 'Set Service Location';
  String get locConfirm            => isAr ? 'تأكيد الموقع'                       : 'Confirm Location';
  String get locAddress            => isAr ? 'العنوان'                            : 'Address';
  String get locMyLocation         => isAr ? 'موقعي الحالي'                        : 'My Location';
  String get locPermissionDenied   => isAr ? 'لم يتم منح إذن الموقع'             : 'Location permission denied';
  String get summaryTitle          => isAr ? 'مراجعة الطلب'                       : 'Review Order';
  String get summaryYourDetails    => isAr ? 'تفاصيل طلبك'                        : 'Your Order Details';
  String get summaryServiceType    => isAr ? 'نوع الخدمة'                         : 'Service Type';
  String get summaryDescription    => isAr ? 'الوصف'                              : 'Description';
  String get summaryLocationLabel  => isAr ? 'الموقع'                             : 'Location';
  String get summaryPhotos         => isAr ? 'الصور'                              : 'Photos';
  String get summaryPaymentDetails => isAr ? 'تفاصيل الدفع'                       : 'Payment Details';
  String get summaryPaymentFailed  => isAr ? 'فشل الدفع، يرجى المحاولة مرة أخرى' : 'Payment failed. Please try again.';
  String get confirmTitle          => isAr ? 'تم تأكيد حجزك!'                     : 'Booking Confirmed!';
  String get confirmSearching      => isAr ? 'جاري البحث عن أقرب مزود خدمة متاح' : 'Searching for the nearest available provider';
  String get confirmViewDetails    => isAr ? 'عرض تفاصيل الطلب'                   : 'View Order Details';
  String get bookingConfirmBtn     => isAr ? 'تأكيد الحجز'                        : 'Confirm Booking';

  // ── Payment ──────────────────────────────────────────────────────────────────
  String get receiptSuccessTitle  => isAr ? 'تم الدفع بنجاح!'                                 : 'Payment Successful!';
  String get receiptProcessing    => isAr ? 'طلبك قيد المعالجة، سيتم إخطارك عند قبول المزود' : 'Your order is being processed. We will notify you when a provider accepts.';
  String get receiptAmountPaid    => isAr ? 'المبلغ المدفوع'                                   : 'Amount Paid';
  String get receiptOrderNo       => isAr ? 'رقم الطلب'                                       : 'Order Number';
  String get receiptPaymentMethod => isAr ? 'طريقة الدفع'                                     : 'Payment Method';
  String get receiptStatusLabel   => isAr ? 'الحالة'                                          : 'Status';
  String get receiptViewOrder     => isAr ? 'عرض الطلب'                                       : 'View Order';
  String get payStatusTitle       => isAr ? 'حالة الدفع'                                      : 'Payment Status';
  String get payLoadError         => isAr ? 'تعذّر تحميل بيانات الدفع'                        : 'Could not load payment data';
  String get payAmountPaid        => isAr ? 'المبلغ المدفوع'                                   : 'Amount Paid';
  String get payFees              => isAr ? 'رسوم الخدمة'                                     : 'Service Fees';
  String get payFeesIncl          => isAr ? 'شامل رسوم الخدمة (20%)'                          : 'Including service fee (20%)';
  String get payReleaseDate       => isAr ? 'تاريخ الإفراج'                                    : 'Release Date';
  String get payNoData            => isAr ? 'لا توجد بيانات دفع لهذا الطلب'                   : 'No payment data for this order';

  // ── Tracking ─────────────────────────────────────────────────────────────────
  String get trackAccepted     => isAr ? 'تم قبول طلبك'             : 'Order Accepted';
  String get trackEnRoute      => isAr ? 'المزود في الطريق إليك'    : 'Provider is on the way';
  String get trackInProgress   => isAr ? 'جاري تنفيذ الخدمة'        : 'Service in Progress';
  String get trackCompleted    => isAr ? 'تم إنجاز الخدمة!'         : 'Service Completed!';
  String get trackPaid         => isAr ? 'تمت عملية الدفع!'         : 'Payment Done!';
  String get trackDefault      => isAr ? 'جاري المتابعة...'         : 'Tracking...';
  String get trackAcceptedSub  => isAr ? 'المزود يستعد للتوجه إليك' : 'Provider is preparing to head your way';
  String get trackEnRouteSub   => isAr ? 'يتوقع الوصول قريباً'      : 'Expected to arrive soon';
  String get trackInProgSub    => isAr ? 'يُرجى البقاء متاحاً'      : 'Please remain available';
  String get trackCompletedSub => isAr ? 'شكراً لاستخدامك خدمتي'   : 'Thank you for using Khudmati';
  String get trackPaidSub      => isAr ? 'قيّم تجربتك مع المزود'   : 'Rate your experience with the provider';
  String get trackOrderNo      => isAr ? 'رقم الطلب: '              : 'Order #';
  String get trackProvider     => isAr ? 'مزود الخدمة'              : 'Service Provider';
  String get trackYourLocation => isAr ? 'موقعك'                    : 'Your Location';

  // ── History ──────────────────────────────────────────────────────────────────
  String get historyTitle       => isAr ? 'سجل الطلبات'          : 'Order History';
  String get historyLoadError   => isAr ? 'تعذر تحميل السجل'     : 'Could not load history';
  String get historyEmpty       => isAr ? 'لا توجد طلبات سابقة'  : 'No previous orders';
  String get historyDetailTitle => isAr ? 'تفاصيل الطلب'         : 'Order Details';
  String get historyOrderNo     => isAr ? 'رقم الطلب'            : 'Order Number';
  String get historyService     => isAr ? 'الخدمة'               : 'Service';
  String get historyDate        => isAr ? 'التاريخ'              : 'Date';
  String get historyAddress     => isAr ? 'العنوان'              : 'Address';
  String get historyProvider    => isAr ? 'المزود'               : 'Provider';
  String get historyBefore      => isAr ? 'صور قبل العمل'        : 'Before Photos';
  String get historyAfter       => isAr ? 'صور بعد العمل'        : 'After Photos';
  String get jobDetailLoadError => isAr ? 'تعذر تحميل تفاصيل الطلب' : 'Could not load order details';
  String get jobDetailCategory  => isAr ? 'الفئة'                : 'Category';
  String get jobDetailDate      => isAr ? 'تاريخ الطلب'          : 'Order Date';

  // ── Profile ──────────────────────────────────────────────────────────────────
  String get profileTitle     => isAr ? 'الملف الشخصي'    : 'My Profile';
  String get profileEdit      => isAr ? 'تعديل البيانات'  : 'Edit Profile';
  String get profileAddresses => isAr ? 'عناويني المحفوظة' : 'Saved Addresses';
  String get profilePayment   => isAr ? 'طرق الدفع'       : 'Payment Methods';
  String get profileReferral  => isAr ? 'دعوة الأصدقاء'   : 'Invite Friends';
  String get profileNotifs    => isAr ? 'الإشعارات'        : 'Notifications';
  String get profileHelp      => isAr ? 'المساعدة والدعم'  : 'Help & Support';
  String get profileLogout    => isAr ? 'تسجيل الخروج'    : 'Log Out';

  // ── Referral ─────────────────────────────────────────────────────────────────
  String get referralTitle        => isAr ? 'دعوة الأصدقاء'                                : 'Invite Friends';
  String get referralTagline      => isAr ? 'شارك كودك، كسب رصيداً'                        : 'Share your code, earn credit';
  String get referralCopied       => isAr ? 'تم نسخ الكود'                                 : 'Code Copied';
  String get referralShare        => isAr ? 'مشاركة'                                       : 'Share';
  String get referralHowItWorks   => isAr ? 'كيف يعمل البرنامج؟'                           : 'How does it work?';
  String get referralFriendGets   => isAr ? 'صديقك يحصل على 15% خصم في أول حجز'           : 'Your friend gets 15% off their first booking';
  String get referralHasCode      => isAr ? 'هل لديك كود دعوة؟'                            : 'Do you have a referral code?';
  String get referralEnterCode    => isAr ? 'أدخل كود صديقك للحصول على خصم 15% في أول حجز' : "Enter your friend's code to get 15% off your first booking";
  String get referralSuccess      => isAr ? 'تم تطبيق الخصم! ستحصل على 15% خصم في حجزك الأول' : 'Discount applied! You get 15% off your first booking';
  String get referralNotFound     => isAr ? 'الكود غير موجود'                               : 'Code not found';
  String get referralAlreadyUsed  => isAr ? 'لقد طبّقت كود دعوة مسبقاً'                   : 'You have already applied a referral code';
  String get referralSelfReferral => isAr ? 'لا يمكنك استخدام كودك الخاص'                   : 'You cannot use your own referral code';

  // ── Rating ───────────────────────────────────────────────────────────────────
  String get ratingOnTime       => isAr ? 'وصل في الوقت المحدد' : 'Arrived on time';
  String get ratingCleanWork    => isAr ? 'عمل نظيف'            : 'Clean work';
  String get ratingFairPrice    => isAr ? 'سعر عادل'            : 'Fair price';
  String get ratingProfessional => isAr ? 'محترف'               : 'Professional';
  String get ratingRecommend    => isAr ? 'أنصح به'             : 'Recommended';
  String get ratingGood         => isAr ? 'ممتاز'               : 'Excellent';
  String get ratingBad          => isAr ? 'سيء'                 : 'Bad';
  String get ratingTellMore     => isAr ? 'أخبرنا أكثر'         : 'Tell us more';
  String ratingQuestion(String name) =>
      isAr ? 'كيف كانت تجربتك مع $name؟' : 'How was your experience with $name?';

  // ── Notifications ────────────────────────────────────────────────────────────
  String get notifTitle => isAr ? 'الإشعارات'            : 'Notifications';
  String get notifError => isAr ? 'حدث خطأ'              : 'An error occurred';
  String get notifEmpty => isAr ? 'لا توجد إشعارات بعد' : 'No notifications yet';
  String get timeNow    => isAr ? 'الآن'                 : 'Just now';
  String timeMinutesAgo(int n) => isAr ? 'منذ $n دقيقة' : '$n minutes ago';
  String timeHoursAgo(int n)   => isAr ? 'منذ $n ساعة'  : '$n hours ago';
  String timeDaysAgo(int n)    => isAr ? 'منذ $n أيام'  : '$n days ago';

  // ── Chat ─────────────────────────────────────────────────────────────────────
  String get chatTitle     => isAr ? 'محادثة'              : 'Chat';
  String get chatProvider  => isAr ? 'المزود'              : 'Provider';
  String get chatLoadError => isAr ? 'تعذر تحميل المحادثة' : 'Could not load chat';

  // ── Dispute ──────────────────────────────────────────────────────────────────
  String get disputeTitle         => isAr ? 'رفع شكوى'                                         : 'Raise Dispute';
  String get disputeOkay          => isAr ? 'حسناً'                                             : 'Okay';
  String get disputeDeadline      => isAr ? 'انتهت مهلة رفع الشكوى. تم تحرير الدفعة للمزود.'  : 'Dispute deadline passed. Payment released to provider.';
  String get disputeAlreadyRaised => isAr ? 'تم رفع شكوى مسبقاً لهذا الطلب.'                  : 'A dispute was already raised for this order.';
  String get disputeInvalidStatus => isAr ? 'لا يمكن رفع شكوى للطلبات بهذه الحالة.'            : 'Cannot raise a dispute for orders in this status.';
  String get disputeGenericError  => isAr ? 'حدث خطأ. يرجى المحاولة مرة أخرى.'                 : 'An error occurred. Please try again.';

  // ── OTP ──────────────────────────────────────────────────────────────────────
  String get otpTitle      => isAr ? 'التحقق من الهاتف'                        : 'Phone Verification';
  String get otpSubtitle   => isAr ? 'أدخل الرمز المرسل إلى'                   : 'Enter the code sent to';
  String get otpResendError => isAr ? 'تعذر إعادة إرسال الرمز. حاول مرة أخرى' : 'Could not resend code. Try again.';
  String get otpExpired    => isAr ? 'انتهت صلاحية الرمز'                      : 'Code expired';
  String get otpRequestNew => isAr ? 'يرجى طلب رمز جديد'                       : 'Please request a new code';
  String get otpInvalid    => isAr ? 'الرمز غير صحيح'                          : 'Invalid code';
  String otpResendIn(int s)     => isAr ? 'إعادة الإرسال بعد ${s}s'            : 'Resend in ${s}s';
  String otpAttemptsLeft(int n) => isAr ? 'المحاولات المتبقية: $n'             : 'Attempts remaining: $n';

  // ── Booking summary (additional) ─────────────────────────────────────────────
  String get showMore              => isAr ? 'عرض المزيد'                                      : 'Show more';
  String get showLess              => isAr ? 'عرض أقل'                                         : 'Show less';
  String get summaryEnterAmount    => isAr ? 'أدخل الأجر المتفق عليه'                          : 'Enter agreed amount';
  String get summaryAmountHelper   => isAr ? 'يتم الاتفاق على السعر مع المزود قبل تأكيد الحجز' : 'Price is agreed with the provider before confirming';
  String get summaryAmountInvalid  => isAr ? 'يرجى إدخال مبلغ صحيح'                           : 'Please enter a valid amount';
  String get summaryPayButton      => isAr ? 'ادفع وأكد الحجز'                                 : 'Pay & Confirm';
  String get summarySecurePayment  => isAr ? 'الدفع مؤمّن بواسطة Stripe'                       : 'Secured by Stripe';
  String get summaryReferralDiscount => isAr ? 'خصم الدعوة'                                   : 'Referral Discount';
  String get summaryWalletCredit   => isAr ? 'رصيد المحفظة'                                    : 'Wallet Credit';
  String get summaryTotalDue       => isAr ? 'الإجمالي المستحق'                                : 'Total Due';

  // ── Booking confirmation (additional) ─────────────────────────────────────────
  String get confirmExpiredTitle  => isAr ? 'لم يتم قبول طلبك'                              : 'Order Not Accepted';
  String get confirmExpiredSub    => isAr ? 'لم يتم قبول طلبك، يرجى المحاولة مرة أخرى'     : 'No provider accepted your order. Please try again.';
  String get confirmAcceptedTitle => isAr ? 'تم قبول طلبك!'                                 : 'Order Accepted!';
  String get confirmTrackProvider => isAr ? 'تتبع المزود'                                   : 'Track Provider';

  // ── Tracking (additional) ─────────────────────────────────────────────────────
  String get trackRateExperience  => isAr ? 'قيّم تجربتك'                        : 'Rate Experience';
  String get trackLoadError       => isAr ? 'تعذر تحميل حالة الطلب'              : 'Could not load order status';
  String get trackProviderWorking => isAr ? 'المزود يعمل على إنجاز طلبك'         : 'Provider is working on your request';
  String get trackProviderArrived => isAr ? 'وصل المزود! جاري تنفيذ الخدمة'      : 'Provider arrived! Service in progress';
  String get trackLocationUpdating => isAr ? 'يتم تحديث الموقع...'               : 'Updating location...';
  String trackDistanceLeft(String km) => isAr ? 'المسافة المتبقية: $km كم'       : '$km km remaining';

  // ── Job detail (additional) ───────────────────────────────────────────────────
  String get jobBeforePhotos       => isAr ? 'صور قبل الخدمة'         : 'Before Photos';
  String get jobAfterPhotos        => isAr ? 'صور بعد الخدمة'         : 'After Photos';
  String get jobDisputeUnderReview => isAr ? 'الشكوى قيد المراجعة'    : 'Dispute Under Review';
  String get jobRaiseDispute       => isAr ? 'رفع شكوى'               : 'Raise Dispute';

  // ── Referral (additional) ─────────────────────────────────────────────────────
  String get referralLoadError         => isAr ? 'تعذر التحميل'                                   : 'Could not load';
  String referralCredits(String amount) => isAr ? 'رصيدك الحالي: $amount ر.س'                    : 'Your credit: \$$amount';
  String referralFriendsCount(String n) => isAr ? 'دعوت $n أصدقاء حتى الآن ✓'                   : 'You have referred $n friends ✓';
  String get referralAutoApplied        => isAr ? 'يُطبَّق تلقائياً في حجزك القادم'               : 'Auto-applied to your next booking';
  String get referralYouGet             => isAr ? 'أنت تحصل على 20 ر.س رصيد في محفظتك'           : 'You get 20 SAR credit in your wallet';
  String get referralCreditAutoApplied  => isAr ? 'الرصيد يُطبَّق تلقائياً في حجزك القادم'        : 'Credit is auto-applied to your next booking';
  String get referralCopiedMsg          => isAr ? 'تم نسخ الرسالة — شاركها مع أصدقائك!'          : 'Message copied — share it with your friends!';

  // ── Rating (additional) ───────────────────────────────────────────────────────
  String get ratingSubmit => isAr ? 'إرسال التقييم' : 'Submit Rating';

  // ── Reminders ────────────────────────────────────────────────────────────────
  String get remindersTitle   => isAr ? 'تذكيرات الصيانة'      : 'Maintenance Reminders';
  String get remindersEmpty   => isAr ? 'لا توجد تذكيرات حالياً' : 'No reminders right now';
  String get remindersOverdue => isAr ? 'متأخرة'                : 'Overdue';
  String get remindersSnooze7 => isAr ? 'تأجيل 7 أيام'         : 'Snooze 7 days';
  String get remindersSnooze30 => isAr ? 'تأجيل 30 يوم'        : 'Snooze 30 days';
  String get remindersDismiss  => isAr ? 'إلغاء التذكير'        : 'Dismiss';
  String get remindersBookNow  => isAr ? 'احجز الآن'            : 'Book Now';
  String remindersDue(String date) => isAr ? 'موعد الصيانة: $date' : 'Due: $date';

  // ── Edit Profile ─────────────────────────────────────────────────────────────
  String get editProfileTitle => isAr ? 'تعديل البيانات'  : 'Edit Profile';
  String get editProfileName  => isAr ? 'الاسم الكامل'    : 'Full Name';
  String get editProfileEmail => isAr ? 'البريد الإلكتروني' : 'Email';
  String get editProfileSave  => isAr ? 'حفظ'              : 'Save';  String get editProfilePhone => isAr ? 'رقم الهاتف (غير قابل للتعديل)' : 'Phone (read-only)';

  // ── Forgot / Reset Password ───────────────────────────────────────────────
  String get forgotPasswordTitle    => isAr ? 'استعادة كلمة المرور' : 'Forgot Password';
  String get forgotPasswordSubtitle => isAr ? 'أدخل رقم هاتفك وسنرسل لك رمزاً للتحقق' : 'Enter your phone number and we\'ll send you a verification code';
  String get forgotPasswordSend     => isAr ? 'إرسال الرمز' : 'Send Code';
  String get resetPasswordTitle     => isAr ? 'تعيين كلمة مرور جديدة' : 'Set New Password';
  String resetPasswordSubtitle(String phone) =>
      isAr ? 'أدخل الرمز المرسل إلى $phone' : 'Enter the code sent to $phone';
  String get resetPasswordOtpLabel  => isAr ? 'رمز التحقق' : 'Verification Code';
  String get resetPasswordNew       => isAr ? 'كلمة المرور الجديدة' : 'New Password';
  String get resetPasswordConfirm   => isAr ? 'تأكيد وحفظ' : 'Confirm & Save';
  String get resetPasswordSuccess   => isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully';
  String get resetPasswordMaxAttempts => isAr ? 'تجاوزت الحد الأقصى للمحاولات. اطلب رمزاً جديداً.' : 'Too many attempts. Please request a new code.';
  // ── Shared ───────────────────────────────────────────────────────────────────
  String get comingSoon => isAr ? 'قريباً' : 'Coming Soon';

  // ── Notifications (additional) ───────────────────────────────────────────────
  String get notifViewJob => isAr ? 'عرض الطلب' : 'View Job';

  // ── Home (additional) ────────────────────────────────────────────────────────
  String get homeNoResults => isAr ? 'لا توجد نتائج' : 'No results found';

  // ── Receipt (additional) ─────────────────────────────────────────────────────
  String get receiptReferralDiscount => isAr ? 'خصم الإحالة'   : 'Referral Discount';
  String get receiptCreditApplied    => isAr ? 'رصيد مستخدم'   : 'Credit Applied';
}
