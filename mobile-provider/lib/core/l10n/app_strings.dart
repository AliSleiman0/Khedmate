import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

/// Type-safe string accessor. Use [S.of(ref)] in any ConsumerWidget.
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
  String get langToggle => isAr ? 'English' : 'عربي';

  // ── App identity ────────────────────────────────────────────────────────────
  String get appName => isAr ? 'خدمتي' : 'Khudmati';
  String get tagline =>
      isAr ? 'بوابة مزودي الخدمة' : 'Provider Portal';

  // ── Welcome ─────────────────────────────────────────────────────────────────
  String get joinAsProvider =>
      isAr ? 'أنا مزود خدمة' : 'Join as Provider';
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
      isAr ? 'تسجيل مزود خدمة' : 'Provider Registration';
  String get fullName => isAr ? 'الاسم الكامل' : 'Full Name';
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
      isAr ? 'الاسم يجب أن يكون حرفين على الأقل'
           : 'Name must be at least 2 characters';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email';
  String get emailRequired =>
      isAr ? 'البريد الإلكتروني مطلوب' : 'Email is required';
  String get emailInvalid =>
      isAr ? 'أدخل بريد إلكتروني صحيح' : 'Enter a valid email';
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
  String get navJobs          => isAr ? 'الطلبات'  : 'Jobs';
  String get navEarnings      => isAr ? 'أرباحي'   : 'Earnings';
  String get navNotifications => isAr ? 'إشعارات'  : 'Alerts';
  String get navProfile       => isAr ? 'حسابي'    : 'My Account';

  // ── Shared UI ────────────────────────────────────────────────────────────────
  String get retry      => isAr ? 'إعادة المحاولة' : 'Retry';
  String get next       => isAr ? 'التالي'         : 'Next';
  String get okay       => isAr ? 'حسناً'          : 'Okay';
  String get skip       => isAr ? 'تخطي'           : 'Skip';
  String get apply      => isAr ? 'تطبيق'          : 'Apply';
  String get camera     => isAr ? 'الكاميرا'       : 'Camera';
  String get gallery    => isAr ? 'معرض الصور'     : 'Gallery';
  String get backToJobs => isAr ? 'العودة للطلبات' : 'Back to Jobs';

  // ── Time labels ──────────────────────────────────────────────────────────────
  String get timeNow             => isAr ? 'الآن'           : 'Just now';
  String timeMinutesAgo(int n)   => isAr ? 'منذ $n دقيقة'   : '$n minutes ago';
  String timeHoursAgo(int n)     => isAr ? 'منذ $n ساعة'    : '$n hours ago';
  String timeDaysAgo(int n)      => isAr ? 'منذ $n أيام'    : '$n days ago';

  // ── Job statuses ─────────────────────────────────────────────────────────────
  String get statusAccepted   => isAr ? 'مقبول'          : 'Accepted';
  String get statusEnRoute    => isAr ? 'في الطريق'       : 'En Route';
  String get statusInProgress => isAr ? 'جارٍ التنفيذ'   : 'In Progress';
  String get statusCompleted  => isAr ? 'مكتمل'          : 'Completed';
  String get statusPaid       => isAr ? 'مدفوع'          : 'Paid';

  // ── Job feed ─────────────────────────────────────────────────────────────────
  String get jobsTitle           => isAr ? 'الطلبات'                    : 'Jobs';
  String get tabAvailable        => isAr ? 'المتاحة'                    : 'Available';
  String get tabActive           => isAr ? 'الجارية'                    : 'Active';
  String get tabCompleted        => isAr ? 'المنجزة'                    : 'Completed';
  String get jobsEmpty           => isAr ? 'لا توجد طلبات متاحة حالياً' : 'No available jobs right now';
  String get jobsLoadError       => isAr ? 'تعذر تحميل الطلبات'         : 'Could not load jobs';
  String get jobsNoneCompleted   => isAr ? 'لا توجد طلبات منجزة'        : 'No completed jobs';
  String get jobsActiveLoadError => isAr ? 'تعذر تحميل الطلبات الجارية' : 'Could not load active jobs';
  String get jobsActiveEmpty     => isAr ? 'لا توجد طلبات جارية'        : 'No active jobs';
  String distanceKm(double km)   => isAr ? '$km كم'                     : '${km} km';

  // ── Job detail (available job) ───────────────────────────────────────────────
  String get jobDetailTitle  => isAr ? 'تفاصيل الطلب'        : 'Job Details';
  String get jobDescTitle    => isAr ? 'وصف الخدمة'           : 'Service Description';
  String get jobLocation     => isAr ? 'الموقع'               : 'Location';
  String get jobBeforePhotos => isAr ? 'صور قبل العمل'        : 'Before Photos';
  String get jobTimeLeft     => isAr ? 'الوقت المتبقي للقبول' : 'Time left to accept';
  String get jobExpired      => isAr ? 'انتهت مدة القبول'     : 'Acceptance period expired';
  String get jobAccept       => isAr ? 'قبول الطلب'           : 'Accept Job';
  String get jobReject       => isAr ? 'رفض'                  : 'Reject';
  String get jobNotAvailable => isAr ? 'الطلب لم يعد متاحاً'  : 'Job no longer available';

  // ── Active job detail ────────────────────────────────────────────────────────
  String get jobRefNo             => isAr ? 'رقم الطلب'                                      : 'Order No.';
  String get jobServiceLabel      => isAr ? 'الخدمة'                                         : 'Service';
  String get jobDescLabel         => isAr ? 'الوصف'                                          : 'Description';
  String get jobCustomerLabel     => isAr ? 'العميل'                                         : 'Customer';
  String get jobArriveStart       => isAr ? 'وصلت، بدء العمل'                                : 'Arrived, Start Work';
  String get jobFinish            => isAr ? 'إنهاء العمل'                                    : 'Finish Work';
  String get jobCompletedAwaitPay => isAr ? 'تم إنهاء العمل بنجاح، في انتظار تأكيد الدفع'   : 'Work completed! Awaiting payment confirmation.';
  String get jobLoadError         => isAr ? 'تعذر تحميل الطلب'                               : 'Could not load job';

  // ── Upload after photos ──────────────────────────────────────────────────────
  String get uploadAfterTitle       => isAr ? 'صور إنجاز العمل'                                                                        : 'Completion Photos';
  String get uploadAfterInstruction => isAr ? 'الرجاء رفع صور توضح إنجاز العمل قبل إنهاء الخدمة. يجب رفع صورة واحدة على الأقل.' : 'Please upload photos showing the completed work. At least one photo is required.';
  String photoCountOf5(int n)       => isAr ? '$n / 5 صور'                                                                             : '$n / 5 photos';
  String get uploadAndFinish        => isAr ? 'رفع الصور وإنهاء الخدمة'        : 'Upload & Complete Job';
  String get photoTooLarge          => isAr ? 'الصورة أكبر من 5 ميغابايت'      : 'Image exceeds 5 MB';
  String get uploadFailed           => isAr ? 'فشل في رفع الصور، حاول مرة أخرى' : 'Upload failed. Please try again.';
  String get addPhoto               => isAr ? 'إضافة صورة'                      : 'Add Photo';

  // ── Earnings ─────────────────────────────────────────────────────────────────
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

  // ── Payout status ────────────────────────────────────────────────────────────
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

  // ── Onboarding ───────────────────────────────────────────────────────────────
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

  // ── Skill test ───────────────────────────────────────────────────────────────
  String get skillTestTitle              => isAr ? 'اختبار المهارة'                     : 'Skill Test';
  String get skillTestSelectCategory     => isAr ? 'اختر الفئة لبدء الاختبار'           : 'Select a category to start the test';
  String skillTestQuestion(int n, int t) => isAr ? 'السؤال $n من $t'                   : 'Question $n of $t';
  String get skillTestFinish             => isAr ? 'إنهاء الاختبار'                     : 'Finish Test';
  String get skillTestPassed             => isAr ? 'أحسنت! اجتزت الاختبار'             : 'Well done! You passed!';
  String get skillTestFailed             => isAr ? 'لم تجتز الاختبار'                   : 'You did not pass';
  String skillTestScore(int s, int t)    => isAr ? 'النتيجة: $s/$t'                    : 'Score: $s/$t';
  String get skillTestRetry              => isAr ? 'يمكنك إعادة المحاولة بعد 24 ساعة'  : 'You can retry after 24 hours';

  // ── ID upload ────────────────────────────────────────────────────────────────
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
  String get profileTitle         => isAr ? 'الملف الشخصي'  : 'My Profile';
  String get profileEdit          => isAr ? 'تعديل البيانات' : 'Edit Profile';
  String get profileVerification  => isAr ? 'مستوى التوثيق'  : 'Verification Level';
  String get profilePayment       => isAr ? 'بيانات الدفع'   : 'Payment Info';
  String get profileWorkHours     => isAr ? 'ساعات العمل'    : 'Work Hours';
  String get profileNotifications => isAr ? 'الإشعارات'      : 'Notifications';
  String get profileHelp          => isAr ? 'المساعدة'       : 'Help';
  String get profileLogout        => isAr ? 'تسجيل الخروج'   : 'Log Out';
  String profileJobCount(int n)   => isAr ? '$n طلب'         : '$n jobs';
  String get profileComingSoon    => isAr ? 'قريباً'          : 'Coming Soon';
  String get profileEditTitle     => isAr ? 'تعديل البيانات'  : 'Edit Profile';
  String get profileEditName      => isAr ? 'الاسم الكامل'   : 'Full Name';
  String get profileEditSave      => isAr ? 'حفظ التغييرات'  : 'Save Changes';
  String get profileEditSuccess   => isAr ? 'تم حفظ التغييرات' : 'Changes saved';

  // ── Completed jobs tab ────────────────────────────────────────────────────────
  String get tabCompletedEmpty  => isAr ? 'لا توجد طلبات منجزة بعد'     : 'No completed jobs yet';
  String get tabCompletedError  => isAr ? 'تعذر تحميل الطلبات المنجزة'  : 'Could not load completed jobs';
  String get completedJobDate   => isAr ? 'تاريخ الإنجاز'               : 'Completed on';
  String get completedJobAmount => isAr ? 'المبلغ الصافي'                : 'Net Amount';

  // ── Notifications ────────────────────────────────────────────────────────────
  String get notifTitle => isAr ? 'الإشعارات'            : 'Notifications';
  String get notifError => isAr ? 'حدث خطأ'              : 'An error occurred';
  String get notifEmpty => isAr ? 'لا توجد إشعارات بعد'  : 'No notifications yet';

  // ── Chat ─────────────────────────────────────────────────────────────────────
  String get chatTitle     => isAr ? 'محادثة'                 : 'Chat';
  String get chatCustomer  => isAr ? 'العميل'                 : 'Customer';
  String get chatLoadError => isAr ? 'تعذر تحميل المحادثة'    : 'Could not load chat';
  String get chatNoMessages => isAr ? 'لا توجد رسائل بعد'    : 'No messages yet';
  String get chatToday      => isAr ? 'اليوم'                 : 'Today';
  String get chatYesterday  => isAr ? 'أمس'                   : 'Yesterday';
  String get chatInputHint  => isAr ? 'اكتب رسالة...'        : 'Type a message...';
  String get chatSendError  => isAr ? 'فشل إرسال الرسالة'     : 'Failed to send message';

  // ── Rating (provider rates customer) ────────────────────────────────────────
  String get ratingCustomerQuestion => isAr ? 'كيف كان تعامل العميل؟' : 'How was the customer?';
  String get ratingGood             => isAr ? 'ممتاز'                 : 'Excellent';
  String get ratingBad              => isAr ? 'سيء'                   : 'Bad';
  String get ratingTellMore         => isAr ? 'أخبرنا أكثر'           : 'Tell us more';
  String get ratingSubmit           => isAr ? 'إرسال التقييم'          : 'Submit Rating';
  String get ratingSkip             => isAr ? 'تخطي'                  : 'Skip';
  String get ratingSubmitError      => isAr ? 'حدث خطأ، حاول مرة أخرى' : 'Something went wrong. Try again.';
  String get ratingEasyDeal         => isAr ? 'سهل التعامل'           : 'Easy to deal with';
  String get ratingAccurateDesc     => isAr ? 'وصف المشكلة بدقة'      : 'Described problem accurately';
  String get ratingPromptPay        => isAr ? 'دفع فوري'              : 'Paid promptly';
  String get rateCustomer           => isAr ? 'قيّم العميل'           : 'Rate Customer';

  // ── OTP ──────────────────────────────────────────────────────────────────────
  String get otpTitle           => isAr ? 'التحقق من الهاتف'                      : 'Phone Verification';
  String get otpSubtitle        => isAr ? 'أدخل الرمز المرسل إلى'                 : 'Enter the code sent to';
  String get otpResendError     => isAr ? 'تعذر إعادة إرسال الرمز. حاول مرة أخرى' : 'Could not resend code. Try again.';
  String get otpExpired         => isAr ? 'انتهت صلاحية الرمز'                    : 'Code expired';
  String get otpRequestNew      => isAr ? 'يرجى طلب رمز جديد'                     : 'Please request a new code';
  String get otpInvalid         => isAr ? 'الرمز غير صحيح'                        : 'Invalid code';
  String otpResendIn(int s)     => isAr ? 'إعادة الإرسال بعد ${s}s'               : 'Resend in ${s}s';
  String otpAttemptsLeft(int n) => isAr ? 'المحاولات المتبقية: $n'                : 'Attempts remaining: $n';

  // ── Login additions ──────────────────────────────────────────────────────────
  String get forgotPassword     => isAr ? 'نسيت كلمة المرور؟'             : 'Forgot Password?';
  String get forgotPasswordSoon => isAr ? 'قريباً — استعادة كلمة المرور' : 'Coming soon — Password Recovery';

  // ── Navigation page ──────────────────────────────────────────────────────────
  String get navPageTitle    => isAr ? 'طلب'              : 'Job';
  String get navPageEnRoute  => isAr ? 'في الطريق'        : 'En Route';
  String get navPageStarted  => isAr ? 'بدأت العمل'       : 'Started Work';
  String get navPageFinished => isAr ? 'انتهيت من العمل'  : 'Finished Work';
  String get navPageDone     => isAr ? 'مكتمل'            : 'Completed';
  String get navPageArrive   => isAr ? 'وصلت — بدء العمل' : 'Arrived — Start Work';

  // ── Stub pages ───────────────────────────────────────────────────────────────
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

  // ── Subscription ──────────────────────────────────────────────────────────────
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

  // ── Analytics ─────────────────────────────────────────────────────────────────
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

  // ── Service category labels ──────────────────────────────────────────────────
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
