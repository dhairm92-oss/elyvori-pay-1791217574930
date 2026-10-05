/// UI texts in the app's own language. Elyvori sets [appLanguage] when it
/// generates the app ('ar' for Arabic requests, 'en' otherwise).
const String appLanguage = 'ar';

bool get isArabic => appLanguage == 'ar';

abstract final class S {
  // ---------------------------------------------------------------- common
  static String get add => isArabic ? 'إضافة' : 'Add';
  static String get search => isArabic ? 'بحث' : 'Search';
  static String get save => isArabic ? 'حفظ' : 'Save';
  static String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  static String get tryAgain => isArabic ? 'إعادة المحاولة' : 'Try again';
  static String get somethingWrong => isArabic ? 'حدث خطأ ما.' : 'Something went wrong.';
  static String get nothingYet => isArabic ? 'لا يوجد شيء هنا بعد.' : 'Nothing here yet.';
  static String get savedOffline =>
      isArabic ? 'كل بياناتك محفوظة على جهازك وتعمل بدون إنترنت.' : 'Everything is saved on your device and works offline.';
  static String get offlineSafe =>
      isArabic ? 'أنت غير متصل — بياناتك آمنة على هذا الجهاز.' : 'Offline — your data is safe on this device.';
  static String get noModules => isArabic ? 'لا توجد أقسام بعد.' : 'No modules yet.';

  static String newRecord(String title) => isArabic ? '$title — إضافة جديدة' : 'New $title';
  static String editRecord(String title) => isArabic ? '$title — تعديل' : 'Edit $title';
  static String emptyList(String title) => isArabic
      ? 'لا يوجد شيء في «$title» بعد. اضغط «إضافة» لإضافة أول عنصر.'
      : 'No ${title.toLowerCase()} yet. Tap “Add” to create the first one.';

  static String requiredField(String field) => isArabic ? 'حقل «$field» مطلوب.' : '$field is required.';
  static String mustBeNumber(String field) => isArabic ? 'يجب أن يكون «$field» رقماً.' : '$field must be a number.';
  static String mustBeDate(String field) => isArabic ? 'يجب أن يكون «$field» تاريخاً صحيحاً.' : '$field must be a date.';
  static String mustBeEmail(String field) =>
      isArabic ? 'يجب أن يكون «$field» بريداً إلكترونياً صحيحاً.' : '$field must be a valid email.';
  static String mustBePhone(String field) =>
      isArabic ? 'يجب أن يكون «$field» رقم هاتف صحيحاً.' : '$field must be a valid phone number.';

  // ---------------------------------------------------------------- splash
  static String get splashPreparing => isArabic ? 'جاري تجهيز التطبيق…' : 'Preparing the app…';
  static String get splashLoading => isArabic ? 'جاري تحميل بياناتك…' : 'Loading your data…';
  static String get splashReady => isArabic ? 'جاهز ✨' : 'Ready ✨';

  // ---------------------------------------------------------------- auth
  static String get signInSubtitle => isArabic ? 'سجّل الدخول إلى مركز التحكم' : 'Sign in to your command center';
  static String get welcomeBack => isArabic ? 'أهلاً بعودتك 👋' : 'Welcome back 👋';
  static String get signInHint => isArabic ? 'سجّل الدخول لمتابعة عملك' : 'Sign in to continue';
  static String get createAccount => isArabic ? 'إنشاء حساب' : 'Create account';
  static String get createAccountHint => isArabic
      ? 'ابدأ خلال ثوانٍ — بياناتك محفوظة ومتزامنة على كل أجهزتك'
      : 'Start in seconds — your data is synced on all your devices';
  static String get name => isArabic ? 'الاسم' : 'Name';
  static String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  static String get password => isArabic ? 'كلمة المرور' : 'Password';
  static String get confirmPassword => isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';
  static String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign in';
  static String get signUp => isArabic ? 'إنشاء الحساب' : 'Sign up';
  static String get orContinueWith => isArabic ? 'أو تابع باستخدام' : 'or continue with';
  static String get noAccount => isArabic ? 'ليس لديك حساب؟' : "Don't have an account?";
  static String get haveAccount => isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  static String get forgotPassword => isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?';
  static String get resetPassword => isArabic ? 'استعادة كلمة المرور' : 'Reset password';
  static String get resetHint =>
      isArabic ? 'أدخل بريدك وسنرسل لك رمزاً من 6 أرقام.' : 'Enter your email and we will send you a 6-digit code.';
  static String get sendCode => isArabic ? 'إرسال الرمز' : 'Send code';
  static String get codeSent => isArabic
      ? 'إذا كان البريد مسجلاً، وصلك رمز. تحقق من بريدك (والرسائل غير المرغوبة).'
      : 'If the email is registered, a code is on its way. Check your inbox (and spam).';
  static String get code => isArabic ? 'الرمز (6 أرقام)' : 'Code (6 digits)';
  static String get newPassword => isArabic ? 'كلمة المرور الجديدة' : 'New password';
  static String get changePassword => isArabic ? 'تغيير كلمة المرور' : 'Change password';
  static String get waitingBrowser => isArabic
      ? 'أكمل تسجيل الدخول في المتصفح ثم ارجع إلى التطبيق…'
      : 'Finish signing in in the browser, then come back to the app…';
  static String get invalidEmail => isArabic ? 'يرجى إدخال بريد إلكتروني صحيح.' : 'Please enter a valid email.';
  static String get shortPassword =>
      isArabic ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.' : 'The password must be at least 6 characters.';
  static String get passwordsDontMatch => isArabic ? 'كلمتا المرور غير متطابقتين.' : 'The passwords do not match.';
  static String get nameRequired => isArabic ? 'يرجى إدخال اسمك.' : 'Please enter your name.';
  static String get codeInvalid => isArabic ? 'الرمز غير صحيح أو انتهت صلاحيته.' : 'The code is wrong or has expired.';

  /// Turns the server's error codes into friendly sentences.
  static String serverError(String code) {
    switch (code) {
      case 'email_taken':
        return isArabic ? 'هذا البريد مسجّل مسبقاً — سجّل الدخول بدلاً من ذلك.' : 'This email already has an account — sign in instead.';
      case 'wrong_credentials':
        return isArabic ? 'البريد أو كلمة المرور غير صحيحة.' : 'Wrong email or password.';
      case 'invalid_email':
        return invalidEmail;
      case 'weak_password':
        return shortPassword;
      case 'invalid_code':
        return codeInvalid;
      case 'oauth_failed':
        return isArabic ? 'لم يكتمل تسجيل الدخول. حاول مرة أخرى.' : 'Sign-in did not finish. Please try again.';
      case 'oauth_timeout':
        return isArabic ? 'انتهت المهلة قبل إكمال تسجيل الدخول.' : 'Timed out before the sign-in finished.';
      case 'offline':
        return isArabic ? 'لا يوجد اتصال بالإنترنت.' : 'No internet connection.';
      default:
        return code.isEmpty || code.contains('_') ? somethingWrong : code;
    }
  }

  // ---------------------------------------------------------------- shell
  static String get tabHome => isArabic ? 'الرئيسية' : 'Home';
  static String get tabDashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  static String get tabProfile => isArabic ? 'حسابي' : 'Profile';

  // ---------------------------------------------------------------- home
  static String greeting(int hour) {
    if (hour < 12) return isArabic ? 'صباح الخير' : 'Good morning';
    if (hour < 18) return isArabic ? 'مساء الخير' : 'Good afternoon';
    return isArabic ? 'مساء الخير' : 'Good evening';
  }

  static String get modules => isArabic ? 'الأقسام' : 'Sections';
  static String get recentActivity => isArabic ? 'آخر النشاطات' : 'Recent activity';
  static String get noActivity =>
      isArabic ? 'لا توجد نشاطات بعد — ابدأ بإضافة أول عنصر.' : 'No activity yet — add your first item.';
  static String get totalItems => isArabic ? 'إجمالي العناصر' : 'Total items';
  static String get thisWeek => isArabic ? 'هذا الأسبوع' : 'This week';
  static String get today => isArabic ? 'اليوم' : 'Today';
  static String itemsCount(int n) => isArabic ? '$n عنصر' : '$n ${n == 1 ? 'item' : 'items'}';

  // ---------------------------------------------------------------- dashboard
  static String get dashboardTitle => isArabic ? 'لوحة التحكم' : 'Dashboard';
  static String get dashboardHint => isArabic ? 'نظرة شاملة على نشاطك' : 'Your activity at a glance';
  static String get activity7Days => isArabic ? 'النشاط خلال آخر 7 أيام' : 'Activity — last 7 days';
  static String get distribution => isArabic ? 'التوزيع حسب القسم' : 'By section';
  static String get sectionsCount => isArabic ? 'الأقسام' : 'Sections';
  static String get noDataYet => isArabic ? 'ستظهر الرسوم البيانية بعد إضافة بيانات.' : 'Charts appear once you add data.';

  /// Monday first (DateTime.monday == 1).
  static List<String> get weekdaysShort => isArabic
      ? const ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ---------------------------------------------------------------- profile
  static String get profileTitle => isArabic ? 'حسابي' : 'My account';
  static String get editName => isArabic ? 'تعديل الاسم' : 'Edit name';
  static String get syncTitle => isArabic ? 'المزامنة السحابية' : 'Cloud sync';
  static String get syncNow => isArabic ? 'مزامنة الآن' : 'Sync now';
  static String get syncing => isArabic ? 'جاري المزامنة…' : 'Syncing…';
  static String get synced => isArabic ? 'متزامن' : 'Synced';
  static String get syncFailed => isArabic ? 'تعذّرت المزامنة — سنحاول تلقائياً' : 'Sync failed — will retry automatically';
  static String get localOnly => isArabic ? 'محفوظ على الجهاز' : 'Saved on device';
  static String get neverSynced => isArabic ? 'لم تتم المزامنة بعد' : 'Not synced yet';
  static String lastSync(String when) => isArabic ? 'آخر مزامنة: $when' : 'Last sync: $when';
  static String pendingChanges(int n) => isArabic ? 'تغييرات بانتظار الرفع: $n' : 'Changes waiting to upload: $n';
  static String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  static String get signOutConfirm => isArabic ? 'هل تريد تسجيل الخروج من هذا الجهاز؟' : 'Sign out of this device?';
  static String get about => isArabic ? 'حول التطبيق' : 'About';
  static String get version => isArabic ? 'الإصدار 1.0.0' : 'Version 1.0.0';
  static String get builtWith => isArabic ? 'صُنع بواسطة Elyvori' : 'Built with Elyvori';
  static String get guest => isArabic ? 'ضيف' : 'Guest';
  static String get privacyPolicy => isArabic ? 'سياسة الخصوصية' : 'Privacy policy';
  static String get deleteAccount => isArabic ? 'حذف الحساب نهائياً' : 'Delete account permanently';
  static String get deleteAccountConfirm => isArabic
      ? 'سيتم حذف حسابك وكل بياناتك من السحابة ومن هذا الجهاز نهائياً، ولا يمكن التراجع. هل أنت متأكد؟'
      : 'Your account and all its data will be permanently deleted from the cloud and this device. This cannot be undone. Are you sure?';
  static String get delete => isArabic ? 'حذف' : 'Delete';

  // ---------------------------------------------------------------- time
  static String timeAgo(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'just now';
    if (diff.inMinutes < 60) return isArabic ? 'قبل ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isArabic ? 'قبل ${diff.inHours} س' : '${diff.inHours}h ago';
    if (diff.inDays < 30) return isArabic ? 'قبل ${diff.inDays} يوم' : '${diff.inDays}d ago';
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return '${time.year}-$m-$d';
  }
}
