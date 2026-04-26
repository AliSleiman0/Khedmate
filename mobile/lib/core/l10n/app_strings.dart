import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

/// Type-safe string accessor. Use [S.of(ref)] in any ConsumerWidget.
///
/// Merged from the legacy customer + provider string files. On key collisions,
/// the customer wording is canonical; the provider-specific variant is exposed
/// behind a `provider…` prefix so provider screens can opt in explicitly.
class S {
  final bool isAr;
  const S._(this.isAr);

  static S of(WidgetRef ref) =>
      S._(ref.watch(localeProvider).languageCode == 'ar');

  /// Construct S from a plain bool — use in Riverpod notifiers where WidgetRef is unavailable.
  static S of2(bool isAr) => S._(isAr);

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
  String get providerTagline =>
      isAr ? 'بوابة مزودي الخدمة' : 'Provider Portal';

  // ── Welcome ─────────────────────────────────────────────────────────────────
  String get createAccount => isAr ? 'إنشاء حساب' : 'Create Account';
  String get signIn => isAr ? 'تسجيل الدخول' : 'Sign In';
  String get joinAsProvider => isAr ? 'أنا مزود خدمة' : 'Join as Provider';
  String get welcomeRoleQuestion =>
      isAr ? 'كيف تريد استخدام خدمتي؟' : 'How would you like to use Khudmati?';
  String get welcomeRoleCustomer =>
      isAr ? 'أحتاج خدمة' : 'I need a service';
  String get welcomeRoleCustomerSub =>
      isAr ? 'احجز مقدمي خدمات موثوقين في دقائق'
           : 'Book trusted providers in minutes';
  String get welcomeRoleProvider =>
      isAr ? 'أقدم خدمات' : 'I provide services';
  String get welcomeRoleProviderSub =>
      isAr ? 'استقبل طلبات العملاء وابدأ العمل'
           : 'Receive jobs and start earning';

  // ── Login ───────────────────────────────────────────────────────────────────
  String get welcomeBack => isAr ? 'مرحباً بك مجدداً' : 'Welcome Back';
  String get phoneNumber => isAr ? 'رقم الهاتف' : 'Phone Number';
  String get countryCode => isAr ? 'الرمز' : 'Code';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get noAccount =>
      isAr ? 'ليس لديك حساب؟ إنشاء حساب' : "Don't have an account? Register";
  String get forgotPassword => isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?';
  String get forgotPasswordSoon =>
      isAr ? 'قريباً — استعادة كلمة المرور' : 'Coming soon — Password Recovery';
  String get loginWithPhone => isAr ? 'رقم الهاتف' : 'Phone';
  String get loginWithEmail => isAr ? 'بريد إلكتروني' : 'Email';

  // ── Register ─────────────────────────────────────────────────────────────────
  String get registerTitle =>
      isAr ? 'إنشاء حساب جديد' : 'Create New Account';
  String get providerRegisterTitle =>
      isAr ? 'تسجيل مزود خدمة' : 'Provider Registration';
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
  String get serviceCategories =>
      isAr ? 'فئات الخدمة' : 'Service Categories';
  String get categoryRequired =>
      isAr ? 'يرجى اختيار فئة خدمة واحدة على الأقل'
           : 'Please select at least one service category';

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
  String get providerFullNameTooShort =>
      isAr ? 'الاسم يجب أن يكون حرفين على الأقل'
           : 'Name must be at least 2 characters';
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

  // ── No-internet blocker ─────────────────────────────────────────────────────
  String get noInternetTitle =>
      isAr ? 'لا يوجد اتصال بالإنترنت' : 'No Internet Connection';
  String get noInternetBody => isAr
      ? 'يحتاج خدمتي إلى اتصال بالإنترنت للعمل. يرجى التحقق من شبكة Wi-Fi أو بيانات الهاتف والمحاولة مرة أخرى.'
      : 'Khudmati needs an internet connection to work. Please check your Wi-Fi or mobile data and try again.';
  String get noInternetRetry => isAr ? 'إعادة المحاولة' : 'Retry';

  // ── Nav bar (customer) ──────────────────────────────────────────────────────
  String get navHome          => isAr ? 'الرئيسية' : 'Home';
  String get navBookings      => isAr ? 'حجوزاتي'  : 'My Bookings';
  String get navBook          => isAr ? 'احجز'      : 'Book';
  String get navNotifications => isAr ? 'إشعارات'  : 'Alerts';
  String get navProfile       => isAr ? 'حسابي'     : 'Profile';

  // ── Nav bar (provider) ──────────────────────────────────────────────────────
  String get navJobs     => isAr ? 'الطلبات'  : 'Jobs';
  String get navEarnings => isAr ? 'أرباحي'   : 'Earnings';

  // ── Home ─────────────────────────────────────────────────────────────────────
  String get homeTitle         => isAr ? 'خدمتي'            : 'Khudmati';
  String get homeSearchHint    => isAr ? 'ماذا تحتاج؟'       : 'What do you need?';
  String get homeSelectService => isAr ? 'اختر الخدمة'       : 'Select Service';
  String get homePendingRating => isAr ? 'لديك تقييم معلق'   : 'You have a pending rating';
  String get homeRateNow       => isAr ? 'قيّم الآن'         : 'Rate Now';

  // ── Home (redesigned — Direction C) ─────────────────────────────────────────
  String get homeLocationLabel  => isAr ? 'الموقع'                         : 'Location';
  String get homeLocationPrompt => isAr ? 'اختر موقعك'                     : 'Pick location';
  String get homeAskHeadline    => isAr ? 'ما الذي يحتاج إصلاح؟'            : 'What needs fixing?';
  String get homeAskSub         => isAr
      ? 'اكتب، تكلم، أو اختر من الأسفل. سنجد لك فنياً مناسباً.'
      : "Type, speak, or pick below. We'll match you to a trusted pro.";
  String get homeAskPlaceholder => isAr ? 'مثلاً: الحنفية تسرّب…'            : 'e.g. The tap is leaking…';
  String get homeSpeak          => isAr ? 'تكلم'                           : 'Speak';
  String get homeChipEmergency  => isAr ? 'طارئ'                           : 'Emergency';
  String get homeChipPreGuest   => isAr ? 'تنظيف قبل الضيوف'               : 'Pre-guest clean';
  String get homeChipAcCheck    => isAr ? 'فحص التكييف'                    : 'AC check-up';
  String get homeChipQuickPlumb => isAr ? 'سباكة سريعة'                    : 'Quick plumbing';
  String get homeBrowseServices => isAr ? 'تصفّح حسب الخدمة'               : 'Browse by service';
  String get homeBookAgain      => isAr ? 'احجز مجدداً'                     : 'Book again';
  String get homeHistoryLink    => isAr ? 'سجل الحجوزات'                    : 'History';
  String get homeSeeAll         => isAr ? 'عرض الكل'                       : 'See all';
  String get homeSummerPick     => isAr ? 'موسم الصيف'                     : 'Summer pick';
  String get homeAcService      => isAr ? 'صيانة وتنظيف التكييف'           : 'AC service & clean';
  String get homeAcServiceSub   => isAr ? 'حافظ على برودة البيت'           : 'Keep your home cool';
  String get homePopularBadge   => isAr ? 'الأشهر'                         : 'Popular';
  String get homeReferTitle     => isAr ? 'ادعُ صديقاً واربح رصيداً'        : 'Invite a friend, earn credit';
  String homeCategoriesCount(int n) => isAr ? '$n فئة' : '$n categories';
  String get homeNoResults => isAr ? 'لا توجد نتائج' : 'No results found';

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
  String get providerStatusInProgress =>
      isAr ? 'جارٍ التنفيذ' : 'In Progress';
  String get statusCompleted   => isAr ? 'مكتمل'               : 'Completed';
  String get statusPaid        => isAr ? 'مدفوع'               : 'Paid';
  String get statusExpired     => isAr ? 'منتهي'               : 'Expired';
  String get statusOnHold      => isAr ? 'محجوز (فترة النزاع)' : 'On Hold';
  String get statusTransferred => isAr ? 'تم التحويل'          : 'Transferred';
  String get statusDisputed    => isAr ? 'نزاع'                : 'Disputed';
  String get statusRefunded    => isAr ? 'مسترجع'              : 'Refunded';

  // ── Shared UI ────────────────────────────────────────────────────────────────
  String get retry      => isAr ? 'إعادة المحاولة' : 'Retry';
  String get backHome   => isAr ? 'العودة للرئيسية' : 'Back to Home';
  String get next       => isAr ? 'التالي'          : 'Next';
  String get back       => isAr ? 'السابق'          : 'Back';
  String get skip       => isAr ? 'تخطي'            : 'Skip';
  String get apply      => isAr ? 'تطبيق'           : 'Apply';
  String get okay       => isAr ? 'حسناً'          : 'Okay';
  String get camera     => isAr ? 'الكاميرا'       : 'Camera';
  String get gallery    => isAr ? 'معرض الصور'     : 'Gallery';
  String get backToJobs => isAr ? 'العودة للطلبات' : 'Back to Jobs';
  String get comingSoon => isAr ? 'قريباً' : 'Coming Soon';

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

  // ── Payment ──────────────────────────────────────────────────────────────────
  String get receiptSuccessTitle  => isAr ? 'تم الدفع بنجاح!'                                 : 'Payment Successful!';
  String get receiptProcessing    => isAr ? 'طلبك قيد المعالجة، سيتم إخطارك عند قبول المزود' : 'Your order is being processed. We will notify you when a provider accepts.';
  String get receiptAmountPaid    => isAr ? 'المبلغ المدفوع'                                   : 'Amount Paid';
  String get receiptOrderNo       => isAr ? 'رقم الطلب'                                       : 'Order Number';
  String get receiptPaymentMethod => isAr ? 'طريقة الدفع'                                     : 'Payment Method';
  String get receiptStatusLabel   => isAr ? 'الحالة'                                          : 'Status';
  String get receiptViewOrder     => isAr ? 'عرض الطلب'                                       : 'View Order';
  String get receiptReferralDiscount => isAr ? 'خصم الإحالة'   : 'Referral Discount';
  String get receiptCreditApplied    => isAr ? 'رصيد مستخدم'   : 'Credit Applied';
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
  String get trackRateExperience  => isAr ? 'قيّم تجربتك'                        : 'Rate Experience';
  String get trackLoadError       => isAr ? 'تعذر تحميل حالة الطلب'              : 'Could not load order status';
  String get trackProviderWorking => isAr ? 'المزود يعمل على إنجاز طلبك'         : 'Provider is working on your request';
  String get trackProviderArrived => isAr ? 'وصل المزود! جاري تنفيذ الخدمة'      : 'Provider arrived! Service in progress';
  String get trackLocationUpdating => isAr ? 'يتم تحديث الموقع...'               : 'Updating location...';
  String trackDistanceLeft(String km) => isAr ? 'المسافة المتبقية: $km كم'       : '$km km remaining';

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

  // ── Job detail / feed (provider) ─────────────────────────────────────────────
  String get jobsTitle           => isAr ? 'الطلبات'                    : 'Jobs';
  String get tabAvailable        => isAr ? 'المتاحة'                    : 'Available';
  String get tabActive           => isAr ? 'الجارية'                    : 'Active';
  String get tabCompleted        => isAr ? 'المنجزة'                    : 'Completed';
  String get jobsEmpty           => isAr ? 'لا توجد طلبات متاحة حالياً' : 'No available jobs right now';
  String get jobsLoadError       => isAr ? 'تعذر تحميل الطلبات'         : 'Could not load jobs';
  String get jobsNoneCompleted   => isAr ? 'لا توجد طلبات منجزة'        : 'No completed jobs';
  String get jobsActiveLoadError => isAr ? 'تعذر تحميل الطلبات الجارية' : 'Could not load active jobs';
  String get jobsActiveEmpty     => isAr ? 'لا توجد طلبات جارية'        : 'No active jobs';
  String distanceKm(double km)   => isAr ? '$km كم'                     : '$km km';

  String get jobDetailTitle  => isAr ? 'تفاصيل الطلب'        : 'Job Details';
  String get jobDescTitle    => isAr ? 'وصف الخدمة'           : 'Service Description';
  String get jobLocation     => isAr ? 'الموقع'               : 'Location';
  String get jobBeforePhotos => isAr ? 'صور قبل الخدمة'         : 'Before Photos';
  String get providerJobBeforePhotos =>
      isAr ? 'صور قبل العمل' : 'Before Photos';
  String get jobAfterPhotos        => isAr ? 'صور بعد الخدمة'         : 'After Photos';
  String get jobDisputeUnderReview => isAr ? 'الشكوى قيد المراجعة'    : 'Dispute Under Review';
  String get jobRaiseDispute       => isAr ? 'رفع شكوى'               : 'Raise Dispute';
  String get jobTimeLeft     => isAr ? 'الوقت المتبقي للقبول' : 'Time left to accept';
  String get jobExpired      => isAr ? 'انتهت مدة القبول'     : 'Acceptance period expired';
  String get jobAccept       => isAr ? 'قبول الطلب'           : 'Accept Job';
  String get jobReject       => isAr ? 'رفض'                  : 'Reject';
  String get jobNotAvailable => isAr ? 'الطلب لم يعد متاحاً'  : 'Job no longer available';

  // ── Active job detail (provider) ─────────────────────────────────────────────
  String get jobRefNo             => isAr ? 'رقم الطلب'                                      : 'Order No.';
  String get jobServiceLabel      => isAr ? 'الخدمة'                                         : 'Service';
  String get jobDescLabel         => isAr ? 'الوصف'                                          : 'Description';
  String get jobCustomerLabel     => isAr ? 'العميل'                                         : 'Customer';
  String get jobArriveStart       => isAr ? 'وصلت، بدء العمل'                                : 'Arrived, Start Work';
  String get jobFinish            => isAr ? 'إنهاء العمل'                                    : 'Finish Work';
  String get jobCompletedAwaitPay => isAr ? 'تم إنهاء العمل بنجاح، في انتظار تأكيد الدفع'   : 'Work completed! Awaiting payment confirmation.';
  String get jobLoadError         => isAr ? 'تعذر تحميل الطلب'                               : 'Could not load job';

  // ── Upload after photos (provider) ───────────────────────────────────────────
  String get uploadAfterTitle       => isAr ? 'صور إنجاز العمل'                                                                        : 'Completion Photos';
  String get uploadAfterInstruction => isAr ? 'الرجاء رفع صور توضح إنجاز العمل قبل إنهاء الخدمة. يجب رفع صورة واحدة على الأقل.' : 'Please upload photos showing the completed work. At least one photo is required.';
  String photoCountOf5(int n)       => isAr ? '$n / 5 صور'                                                                             : '$n / 5 photos';
  String get uploadAndFinish        => isAr ? 'رفع الصور وإنهاء الخدمة'        : 'Upload & Complete Job';
  String get photoTooLarge          => isAr ? 'الصورة أكبر من 5 ميغابايت'      : 'Image exceeds 5 MB';
  String get uploadFailed           => isAr ? 'فشل في رفع الصور، حاول مرة أخرى' : 'Upload failed. Please try again.';
  String get addPhoto               => isAr ? 'إضافة صورة'                      : 'Add Photo';

  // ── Earnings (provider) ──────────────────────────────────────────────────────
  String get earningsTitle      => isAr ? 'الأرباح'                              : 'Earnings';
  String get payoutAccount      => isAr ? 'حساب الدفع'                           : 'Payout Account';
  String get earningsThisMonth  => isAr ? 'هذا الشهر'                            : 'This Month';
  String get earningsPending    => isAr ? 'في الانتظار'                           : 'Pending';
  String get earningsTotal      => isAr ? 'إجمالي الأرباح'                       : 'Total Earnings';
  String get recentTransactions => isAr ? 'آخر المعاملات'                        : 'Recent Transactions';
  String get noTransactions     => isAr ? 'لا توجد معاملات بعد'                  : 'No transactions yet';
  String get earningsLoadError  => isAr ? 'تعذّر تحميل الأرباح'                  : 'Could not load earnings';
  String get stripeLink         => isAr ? 'ربط حساب الدفع'                       : 'Link Payout Account';
  String get stripeLinkSub      => isAr ? 'يرجى ربط حساب Stripe لاستلام أرباحك' : 'Link your Stripe account to receive payouts';
  String get stripeConnect      => isAr ? 'ربط'                                  : 'Connect';
  String get txGross            => isAr ? 'إجمالي'      : 'Gross';
  String get txFee              => isAr ? 'رسوم'        : 'Fee';
  String get txHeld             => isAr ? 'محجوز'       : 'Held';
  String get txReleased         => isAr ? 'محوّل'       : 'Released';
  String get txDisputed         => isAr ? 'نزاع'        : 'Disputed';
  String get txPaid             => isAr ? 'مدفوع'       : 'Paid';
  String get txRefunded         => isAr ? 'مسترجع'      : 'Refunded';

  // ── Payout status (provider) ─────────────────────────────────────────────────
  String get payoutTitle           => isAr ? 'حساب الدفع'           : 'Payout Account';
  String get payoutLoadError       => isAr ? 'تعذّر تحميل البيانات' : 'Could not load data';
  String get pendingBalance        => isAr ? 'الرصيد المعلّق'       : 'Pending Balance';
  String get pendingBalanceSub     => isAr ? 'طلبات مكتملة في فترة الانتظار' : 'Completed jobs in hold period';
  String get availableBalance      => isAr ? 'الرصيد المتاح'        : 'Available Balance';
  String get availableBalanceSub   => isAr ? 'جاهز للتحويل'         : 'Ready to transfer';
  String get stripeConnectTitle    => isAr ? 'حساب Stripe Connect'  : 'Stripe Connect Account';
  String get stripeConnected       => isAr ? 'تم ربط حساب Stripe'   : 'Stripe Account Connected';
  String get stripeConnectedSub    => isAr ? 'ستستلم أرباحك تلقائياً بعد انتهاء فترة الانتظار' : 'You will receive payouts automatically after the hold period.';
  String get payoutLinkTitle       => isAr ? 'ربط حساب الدفع'       : 'Link Payout Account';
  String get payoutLinkDesc        => isAr ? 'لاستلام أرباحك، يرجى ربط حسابك المصرفي عبر Stripe Connect. العملية آمنة وتستغرق بضع دقائق فقط.' : 'To receive payouts, link your bank account via Stripe Connect. The process is secure and takes a few minutes.';
  String get payoutLinkBtn         => isAr ? 'ربط حساب الدفع'       : 'Link Payout Account';
  String get payoutOnboardingError => isAr ? 'تعذّر فتح صفحة التسجيل، يرجى المحاولة مرة أخرى' : 'Could not open registration page. Please try again.';

  // ── Onboarding (provider) ────────────────────────────────────────────────────
  String get onboardingTitle        => isAr ? 'أكمل ملفك الشخصي'                      : 'Complete Your Profile';
  String onboardingError(String e)  => isAr ? 'حدث خطأ: $e'                            : 'An error occurred: $e';
  String get onboardingDone         => isAr ? 'حسابك جاهز!'                            : 'Your account is ready!';
  String get onboardingCanAccept    => isAr ? 'يمكنك الآن قبول الطلبات'                : 'You can now accept jobs';
  String get onboardingGoToJobs     => isAr ? 'انتقل إلى قائمة الطلبات'                : 'Go to Jobs';
  String get onboardingInstructions => isAr ? 'أكمل الخطوات التالية للتحقق من حسابك'   : 'Complete the steps below to verify your account';
  String get onboardingIdVerify     => isAr ? 'تحقق من الهوية'                         : 'ID Verification';
  String get onboardingSkillTest    => isAr ? 'اختبار المهارة'                         : 'Skill Test';
  String get onboardingPhoneVerify  => isAr ? 'التحقق من الهاتف'                       : 'Phone Verification';
  String get onboardingStepComplete => isAr ? 'مكتمل'       : 'Completed';
  String get onboardingStepPending  => isAr ? 'في الانتظار' : 'Pending';
  String get onboardingStepRejected => isAr ? 'مرفوض'       : 'Rejected';
  String get onboardingStepRequired => isAr ? 'مطلوب'       : 'Required';
  String get onboardingReason       => isAr ? 'السبب'       : 'Reason';

  // ── Skill test (provider) ────────────────────────────────────────────────────
  String get skillTestTitle              => isAr ? 'اختبار المهارة'                     : 'Skill Test';
  String get skillTestSelectCategory     => isAr ? 'اختر الفئة لبدء الاختبار'           : 'Select a category to start the test';
  String skillTestQuestion(int n, int t) => isAr ? 'السؤال $n من $t'                   : 'Question $n of $t';
  String get skillTestFinish             => isAr ? 'إنهاء الاختبار'                     : 'Finish Test';
  String get skillTestPassed             => isAr ? 'أحسنت! اجتزت الاختبار'             : 'Well done! You passed!';
  String get skillTestFailed             => isAr ? 'لم تجتز الاختبار'                   : 'You did not pass';
  String skillTestScore(int s, int t)    => isAr ? 'النتيجة: $s/$t'                    : 'Score: $s/$t';
  String get skillTestRetry              => isAr ? 'يمكنك إعادة المحاولة بعد 24 ساعة'  : 'You can retry after 24 hours';

  // ── ID upload (provider) ─────────────────────────────────────────────────────
  String get idUploadTitle       => isAr ? 'رفع وثائق الهوية'                                     : 'Upload ID Documents';
  String get idUploadInstruction => isAr ? 'ارفع صورة واضحة من بطاقة هويتك الوطنية أو جواز سفرك' : 'Upload a clear photo of your national ID or passport';
  String get idDocType           => isAr ? 'نوع الوثيقة'           : 'Document Type';
  String get idNationalId        => isAr ? 'بطاقة هوية وطنية'      : 'National ID';
  String get idPassport          => isAr ? 'جواز سفر'              : 'Passport';
  String get idResidencePermit   => isAr ? 'تصريح إقامة'           : 'Residence Permit';
  String get idFrontSide         => isAr ? 'الوجه الأمامي'         : 'Front Side';
  String get idBackSide          => isAr ? 'الوجه الخلفي'          : 'Back Side';
  String get idTapToSelect       => isAr ? 'اضغط لاختيار صورة'     : 'Tap to select image';
  String get idSubmit            => isAr ? 'إرسال للمراجعة'        : 'Submit for Review';
  String get idChooseSource      => isAr ? 'اختر مصدر الصورة'      : 'Choose Image Source';
  String get idSubmitSuccess     => isAr ? 'تم إرسال وثائقك، سيتم المراجعة خلال 24 ساعة' : 'Documents submitted. Review within 24 hours.';

  // ── Profile ──────────────────────────────────────────────────────────────────
  String get profileTitle         => isAr ? 'الملف الشخصي'    : 'My Profile';
  String get profileEdit          => isAr ? 'تعديل البيانات'  : 'Edit Profile';
  String get profileAddresses     => isAr ? 'عناويني المحفوظة' : 'Saved Addresses';
  String get profilePayment       => isAr ? 'طرق الدفع'       : 'Payment Methods';
  String get profileReferral      => isAr ? 'دعوة الأصدقاء'   : 'Invite Friends';
  String get profileNotifs        => isAr ? 'الإشعارات'        : 'Notifications';
  String get profileHelp          => isAr ? 'المساعدة والدعم'  : 'Help & Support';
  String get providerProfileHelp  => isAr ? 'المساعدة'         : 'Help';
  String get profileLogout        => isAr ? 'تسجيل الخروج'    : 'Log Out';
  String get profileDeleteAccount => isAr ? 'حذف الحساب'      : 'Delete Account';
  String get deleteAccountDialogTitle => isAr ? 'حذف الحساب نهائياً؟' : 'Delete account permanently?';
  String get deleteAccountDialogBody  => isAr
      ? 'سيتم حذف حسابك وجميع بياناتك بشكل نهائي. لا يمكن التراجع عن هذا الإجراء.'
      : 'Your account and all data will be permanently removed. This action cannot be undone.';
  String get deleteAccountConfirm => isAr ? 'حذف الحساب' : 'Delete account';
  String get deleteAccountCancel  => isAr ? 'إلغاء'       : 'Cancel';
  String get deleteAccountSuccess => isAr ? 'تم حذف الحساب' : 'Account deleted';
  String get deleteAccountError   => isAr
      ? 'تعذّر حذف الحساب. يرجى المحاولة لاحقاً.'
      : 'Unable to delete account. Please try again later.';
  String get deleteAccountHasActiveJobs => isAr
      ? 'لا يمكن حذف الحساب لديك طلب نشط. أكمل الطلب أو ألغه أولاً.'
      : 'You have an active job. Complete or cancel it before deleting your account.';
  String get deleteAccountHasActiveSubscription => isAr
      ? 'ألغِ اشتراك Power Provider أولاً ثم احذف الحساب.'
      : 'Cancel your Power Provider subscription first, then delete your account.';
  String get profileVerification  => isAr ? 'مستوى التوثيق'  : 'Verification Level';
  String get profileWorkHours     => isAr ? 'ساعات العمل'    : 'Work Hours';
  String get profileNotifications => isAr ? 'الإشعارات'      : 'Notifications';
  String profileJobCount(int n)   => isAr ? '$n طلب'         : '$n jobs';
  String get profileComingSoon    => isAr ? 'قريباً'          : 'Coming Soon';
  String get profileEditTitle     => isAr ? 'تعديل البيانات'  : 'Edit Profile';
  String get profileEditName      => isAr ? 'الاسم الكامل'   : 'Full Name';
  String get profileEditSave      => isAr ? 'حفظ التغييرات'  : 'Save Changes';
  String get profileEditSuccess   => isAr ? 'تم حفظ التغييرات' : 'Changes saved';

  // ── Edit Profile (customer) ──────────────────────────────────────────────────
  String get editProfileTitle => isAr ? 'تعديل البيانات'  : 'Edit Profile';
  String get editProfileName  => isAr ? 'الاسم الكامل'    : 'Full Name';
  String get editProfileEmail => isAr ? 'البريد الإلكتروني' : 'Email';
  String get editProfileSave  => isAr ? 'حفظ'              : 'Save';
  String get editProfilePhone => isAr ? 'رقم الهاتف (غير قابل للتعديل)' : 'Phone (read-only)';

  // ── Completed jobs tab (provider) ────────────────────────────────────────────
  String get tabCompletedEmpty  => isAr ? 'لا توجد طلبات منجزة بعد'     : 'No completed jobs yet';
  String get tabCompletedError  => isAr ? 'تعذر تحميل الطلبات المنجزة'  : 'Could not load completed jobs';
  String get completedJobDate   => isAr ? 'تاريخ الإنجاز'               : 'Completed on';
  String get completedJobAmount => isAr ? 'المبلغ الصافي'                : 'Net Amount';

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
  String get referralLoadError         => isAr ? 'تعذر التحميل'                                   : 'Could not load';
  String referralCredits(String amount) => isAr ? 'رصيدك الحالي: $amount ر.س'                    : 'Your credit: \$$amount';
  String referralFriendsCount(String n) => isAr ? 'دعوت $n أصدقاء حتى الآن ✓'                   : 'You have referred $n friends ✓';
  String get referralAutoApplied        => isAr ? 'يُطبَّق تلقائياً في حجزك القادم'               : 'Auto-applied to your next booking';
  String get referralYouGet             => isAr ? 'أنت تحصل على 20 ر.س رصيد في محفظتك'           : 'You get 20 SAR credit in your wallet';
  String get referralCreditAutoApplied  => isAr ? 'الرصيد يُطبَّق تلقائياً في حجزك القادم'        : 'Credit is auto-applied to your next booking';
  String get referralCopiedMsg          => isAr ? 'تم نسخ الرسالة — شاركها مع أصدقائك!'          : 'Message copied — share it with your friends!';

  // ── Rating (customer rates provider) ─────────────────────────────────────────
  String get ratingOnTime       => isAr ? 'وصل في الوقت المحدد' : 'Arrived on time';
  String get ratingCleanWork    => isAr ? 'عمل نظيف'            : 'Clean work';
  String get ratingFairPrice    => isAr ? 'سعر عادل'            : 'Fair price';
  String get ratingProfessional => isAr ? 'محترف'               : 'Professional';
  String get ratingRecommend    => isAr ? 'أنصح به'             : 'Recommended';
  String get ratingGood         => isAr ? 'ممتاز'               : 'Excellent';
  String get ratingBad          => isAr ? 'سيء'                 : 'Bad';
  String get ratingTellMore     => isAr ? 'أخبرنا أكثر'         : 'Tell us more';
  String get ratingSubmit       => isAr ? 'إرسال التقييم'       : 'Submit Rating';
  String ratingQuestion(String name) =>
      isAr ? 'كيف كانت تجربتك مع $name؟' : 'How was your experience with $name?';

  // ── Rating (provider rates customer) ─────────────────────────────────────────
  String get ratingCustomerQuestion => isAr ? 'كيف كان تعامل العميل؟' : 'How was the customer?';
  String get ratingSkip             => isAr ? 'تخطي'                  : 'Skip';
  String get ratingSubmitError      => isAr ? 'حدث خطأ، حاول مرة أخرى' : 'Something went wrong. Try again.';
  String get ratingEasyDeal         => isAr ? 'سهل التعامل'           : 'Easy to deal with';
  String get ratingAccurateDesc     => isAr ? 'وصف المشكلة بدقة'      : 'Described problem accurately';
  String get ratingPromptPay        => isAr ? 'دفع فوري'              : 'Paid promptly';
  String get rateCustomer           => isAr ? 'قيّم العميل'           : 'Rate Customer';

  // ── Notifications ────────────────────────────────────────────────────────────
  String get notifTitle   => isAr ? 'الإشعارات'            : 'Notifications';
  String get notifError   => isAr ? 'حدث خطأ'              : 'An error occurred';
  String get notifEmpty   => isAr ? 'لا توجد إشعارات بعد' : 'No notifications yet';
  String get notifViewJob => isAr ? 'عرض الطلب' : 'View Job';
  String get timeNow    => isAr ? 'الآن'                 : 'Just now';
  String timeMinutesAgo(int n) => isAr ? 'منذ $n دقيقة' : '$n minutes ago';
  String timeHoursAgo(int n)   => isAr ? 'منذ $n ساعة'  : '$n hours ago';
  String timeDaysAgo(int n)    => isAr ? 'منذ $n أيام'  : '$n days ago';

  // ── Chat ─────────────────────────────────────────────────────────────────────
  String get chatTitle     => isAr ? 'محادثة'              : 'Chat';
  String get chatProvider  => isAr ? 'المزود'              : 'Provider';
  String get chatCustomer  => isAr ? 'العميل'              : 'Customer';
  String get chatLoadError => isAr ? 'تعذر تحميل المحادثة' : 'Could not load chat';
  String get chatNoMessages => isAr ? 'لا توجد رسائل بعد' : 'No messages yet';
  String get chatToday      => isAr ? 'اليوم'              : 'Today';
  String get chatYesterday  => isAr ? 'أمس'                : 'Yesterday';
  String get chatInputHint  => isAr ? 'اكتب رسالة...'     : 'Type a message...';
  String get chatSendError  => isAr ? 'فشل إرسال الرسالة' : 'Failed to send message';

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

  // ── Navigation page (provider) ───────────────────────────────────────────────
  String get navPageTitle    => isAr ? 'طلب'              : 'Job';
  String get navPageEnRoute  => isAr ? 'في الطريق'        : 'En Route';
  String get navPageStarted  => isAr ? 'بدأت العمل'       : 'Started Work';
  String get navPageFinished => isAr ? 'انتهيت من العمل'  : 'Finished Work';
  String get navPageDone     => isAr ? 'مكتمل'            : 'Completed';
  String get navPageArrive   => isAr ? 'وصلت — بدء العمل' : 'Arrived — Start Work';

  // ── Stub pages (provider) ────────────────────────────────────────────────────
  String get jobsAvailableTitle     => isAr ? 'الطلبات المتاحة' : 'Available Jobs';
  String get jobsOnline             => isAr ? 'متصل'            : 'Online';
  String get jobsOffline            => isAr ? 'غير متصل'        : 'Offline';
  String get jobsGoOnline           => isAr ? 'فعّل التوافر لاستقبال الطلبات' : 'Go online to receive jobs';
  String get jobOrderPrefix         => isAr ? 'طلب'             : 'Job';
  String get jobTimeExpiredSnackbar => isAr ? 'انتهى الوقت — تم رفض الطلب تلقائيًا' : 'Time up — job auto-rejected';
  String get jobSeconds             => isAr ? 'ثانية'           : 'sec';
  String get jobUrgent              => isAr ? 'انتبه! الوقت ينفد' : 'Hurry! Time running out';
  String get jobTwoMinutes          => isAr ? 'لديك دقيقتان للرد' : 'You have 2 minutes to respond';
  String get jobDetailsCard         => isAr ? 'تفاصيل الطلب'   : 'Job Details';
  String get jobServiceStub         => isAr ? 'الخدمة'          : 'Service';
  String get jobLocationStub        => isAr ? 'الموقع'          : 'Location';
  String get jobDistanceStub        => isAr ? 'المسافة'         : 'Distance';
  String get jobDescStub            => isAr ? 'الوصف'           : 'Description';
  String get jobExpectedAmount      => isAr ? 'المبلغ المتوقع'  : 'Expected Amount';

  // ── Reminders (customer) ─────────────────────────────────────────────────────
  String get remindersTitle   => isAr ? 'تذكيرات الصيانة'      : 'Maintenance Reminders';
  String get remindersEmpty   => isAr ? 'لا توجد تذكيرات حالياً' : 'No reminders right now';
  String get remindersOverdue => isAr ? 'متأخرة'                : 'Overdue';
  String get remindersSnooze7 => isAr ? 'تأجيل 7 أيام'         : 'Snooze 7 days';
  String get remindersSnooze30 => isAr ? 'تأجيل 30 يوم'        : 'Snooze 30 days';
  String get remindersDismiss  => isAr ? 'إلغاء التذكير'        : 'Dismiss';
  String get remindersBookNow  => isAr ? 'احجز الآن'            : 'Book Now';
  String remindersDue(String date) => isAr ? 'موعد الصيانة: $date' : 'Due: $date';

  // ── Forgot / Reset Password (customer) ───────────────────────────────────────
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

  // ── Subscription (provider) ──────────────────────────────────────────────────
  String get subTitle              => isAr ? 'اشتراك Power Provider'         : 'Power Provider Subscription';
  String get subCurrentPlan        => isAr ? 'خطتك الحالية'                  : 'Your Current Plan';
  String get subStandard           => isAr ? 'مزود عادي'                     : 'Standard Provider';
  String get subPower              => isAr ? 'Power Provider'                 : 'Power Provider';
  String get subMonthlyFee         => isAr ? 'الرسوم الشهرية'                 : 'Monthly Fee';
  String get subCommission         => isAr ? 'نسبة العمولة'                   : 'Commission Rate';
  String get subPriority           => isAr ? 'أولوية في استقبال الطلبات'     : 'Job Priority Access';
  String get subNextBilling        => isAr ? 'تاريخ الفاتورة القادمة'         : 'Next Billing Date';
  String get subCancelsAt          => isAr ? 'ينتهي الاشتراك في'              : 'Subscription ends';
  String get subSubscribe          => isAr ? 'الاشتراك في Power Provider'     : 'Subscribe to Power Provider';
  String get subCancel             => isAr ? 'إلغاء الاشتراك'                 : 'Cancel Subscription';
  String get subCancelConfirmTitle => isAr ? 'إلغاء الاشتراك؟'                : 'Cancel Subscription?';
  String get subCancelConfirmBody  => isAr ? 'ستستمر في الاستفادة من المزايا حتى نهاية الفترة الحالية.' : 'You will keep your benefits until the end of the current billing period.';
  String get subCancelConfirmYes   => isAr ? 'نعم، إلغاء'                    : 'Yes, Cancel';
  String get subCancelConfirmNo    => isAr ? 'لا، تراجع'                     : 'No, Keep It';
  String get subActiveStatus       => isAr ? 'نشط'                           : 'Active';
  String get subPastDueStatus      => isAr ? 'متأخر في الدفع'                : 'Payment Past Due';
  String get subCancelledStatus    => isAr ? 'ملغى'                          : 'Cancelled';
  String get subBenefitsTitle      => isAr ? 'مزايا Power Provider'           : 'Power Provider Benefits';
  String get subBenefit1           => isAr ? 'عمولة 10% فقط (بدلاً من 15%)' : '10% commission (vs 15% standard)';
  String get subBenefit2           => isAr ? 'أولوية استقبال الطلبات بـ 30 ثانية' : '30-second priority job access';
  String get subBenefit3           => isAr ? 'شارة Power Provider على ملفك'  : 'Power Provider badge on your profile';
  String get subLoadError          => isAr ? 'تعذر تحميل بيانات الاشتراك'    : 'Could not load subscription data';
  String get subPaymentFailed      => isAr ? 'فشل الدفع، يرجى تحديث طريقة الدفع' : 'Payment failed. Please update your payment method.';
  String get subSuccess            => isAr ? 'تم الاشتراك بنجاح!'             : 'Successfully subscribed!';
  String get subCancelSuccess      => isAr ? 'تم إلغاء الاشتراك'              : 'Subscription cancelled';
  String get subErrorNotActive     => isAr ? 'يجب أن يكون حسابك نشطاً للاشتراك' : 'Your account must be Active to subscribe';
  String get subErrorAlready       => isAr ? 'لديك اشتراك نشط بالفعل'         : 'You already have an active subscription';
  String get subErrorPayment       => isAr ? 'فشل في معالجة طريقة الدفع'     : 'Failed to process payment method';
  String get subErrorStripe        => isAr ? 'حدث خطأ في نظام الدفع'          : 'Payment system error';

  // ── Analytics (provider) ─────────────────────────────────────────────────────
  String get analyticsTitle          => isAr ? 'إحصائياتي'                   : 'My Analytics';
  String get analyticsPeriod7d       => isAr ? '7 أيام'                      : '7 Days';
  String get analyticsPeriod30d      => isAr ? '30 يوم'                      : '30 Days';
  String get analyticsPeriod3m       => isAr ? '3 أشهر'                      : '3 Months';
  String get analyticsPeriodAll      => isAr ? 'الكل'                        : 'All Time';
  String get analyticsEarningsTitle  => isAr ? 'الأرباح'                     : 'Earnings';
  String get analyticsNetEarnings    => isAr ? 'الأرباح الصافية'              : 'Net Earnings';
  String get analyticsPending        => isAr ? 'في الانتظار'                  : 'Pending';
  String get analyticsVsPrev         => isAr ? 'مقارنة بالفترة السابقة'       : 'vs previous period';
  String get analyticsJobsTitle      => isAr ? 'إحصائيات الطلبات'             : 'Job Statistics';
  String get analyticsCompleted      => isAr ? 'طلبات منجزة'                 : 'Completed Jobs';
  String get analyticsAcceptRate     => isAr ? 'معدل القبول'                  : 'Acceptance Rate';
  String get analyticsAvgValue       => isAr ? 'متوسط قيمة الطلب'             : 'Avg Job Value';
  String get analyticsTopCategories  => isAr ? 'أكثر الفئات طلباً'            : 'Top Categories';
  String get analyticsRatingTitle    => isAr ? 'تقييماتي'                    : 'My Ratings';
  String get analyticsPositiveRate   => isAr ? 'نسبة الرضا'                   : 'Satisfaction Rate';
  String get analyticsTotalRatings   => isAr ? 'إجمالي التقييمات'              : 'Total Ratings';
  String get analyticsTopTags        => isAr ? 'أبرز نقاط القوة'              : 'Top Strengths';
  String get analyticsRatingTrend    => isAr ? 'آخر 10 تقييمات'               : 'Last 10 Ratings';
  String get analyticsLoadError      => isAr ? 'تعذر تحميل الإحصائيات'        : 'Could not load analytics';
  String get analyticsNoData         => isAr ? 'لا توجد بيانات بعد'           : 'No data yet';
  String get analyticsSAR            => isAr ? 'ر.س'                         : 'SAR';

  // ── Service category labels (provider skill test) ────────────────────────────
  String categoryLabel(String key) {
    const labels = {
      'plumbing':    ('Plumbing',    'سباكة'),
      'electrical':  ('Electrical',  'كهرباء'),
      'cleaning':    ('Cleaning',    'تنظيف'),
      'carpentry':   ('Carpentry',   'نجارة'),
      'painting':    ('Painting',    'دهان'),
    };
    final pair = labels[key];
    if (pair == null) return key;
    return isAr ? pair.$2 : pair.$1;
  }
}
