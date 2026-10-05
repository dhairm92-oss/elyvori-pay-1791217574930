import '../../../core/l10n/strings.dart';

/// Elyvori Pay texts (Arabic / English follow the app language).
abstract final class WS {
  static String t(String ar, String en) => isArabic ? ar : en;

  // onboarding
  static String get onb1Title => t('محفظتك في جيبك', 'Your wallet, in your pocket');
  static String get onb1Body => t('أرسل واستقبل الأموال خلال ثوانٍ، بالشيكل والدولار والدينار.', 'Send and receive money in seconds — ILS, USD and JOD.');
  static String get onb2Title => t('آمنة بالكامل', 'Secure by design');
  static String get onb2Body => t('رمز سري لكل عملية، بصمة، وقفل تلقائي — أموالك محمية دائماً.', 'A PIN for every payment, fingerprint and auto-lock — your money stays protected.');
  static String get onb3Title => t('ادفع بـ QR', 'Pay with QR');
  static String get onb3Body => t('امسح الرمز وادفع، أو اعرض رمزك ليدفع لك الآخرون.', 'Scan to pay, or show your code to get paid.');
  static String get createWallet => t('إنشاء محفظة', 'Create a wallet');
  static String get haveWallet => t('لدي محفظة', 'I have a wallet');
  static String get next => t('التالي', 'Next');
  static String get skip => t('تخطي', 'Skip');

  // auth
  static String get phoneTitle => t('رقم جوالك', 'Your phone number');
  static String get phoneHint => t('سنرسل لك رمز تحقق برسالة SMS.', 'We will send you a verification code by SMS.');
  static String get phoneLoginHint => t('أدخل الرقم المسجّل في محفظتك.', 'Enter the number of your wallet.');
  static String get phone => t('رقم الجوال (مثال 0591234567)', 'Phone (e.g. 0591234567)');
  static String get continueLabel => t('متابعة', 'Continue');
  static String get otpTitle => t('رمز التحقق', 'Verification code');
  static String otpHint(String phone) => t('أدخل الرمز المكوّن من 6 أرقام المرسل إلى $phone', 'Enter the 6-digit code sent to $phone');
  static String sandboxCode(String code) => t('وضع تجريبي — الرمز: $code', 'Sandbox mode — code: $code');
  static String get resend => t('إعادة الإرسال', 'Resend');
  static String get profileTitle => t('عرّفنا بنفسك', 'Tell us about you');
  static String get fullName => t('الاسم الكامل', 'Full name');
  static String get emailOptional => t('البريد الإلكتروني (اختياري)', 'Email (optional)');
  static String get createPin => t('أنشئ رمزك السري', 'Create your PIN');
  static String get createPinHint => t('6 أرقام تستخدمها لكل عملية دفع ولفتح المحفظة.', '6 digits for every payment and to unlock the wallet.');
  static String get confirmPin => t('أكّد رمزك السري', 'Confirm your PIN');
  static String get pinMismatch => t('الرمزان غير متطابقين، حاول مجدداً.', 'The PINs do not match, try again.');
  static String get enterPin => t('أدخل رمزك السري', 'Enter your PIN');
  static String get unlockTitle => t('مرحباً بعودتك', 'Welcome back');
  static String get useBiometric => t('استخدم البصمة', 'Use fingerprint');
  static String get biometricReason => t('افتح Elyvori Pay', 'Unlock Elyvori Pay');
  static String get enableBiometric => t('تفعيل الدخول بالبصمة', 'Unlock with fingerprint');
  static String get notYou => t('ليس أنت؟ تسجيل الخروج', 'Not you? Sign out');

  // home
  static String get totalBalance => t('رصيدك', 'Your balance');
  static String get send => t('إرسال', 'Send');
  static String get request => t('طلب', 'Request');
  static String get receive => t('استلام', 'Receive');
  static String get scan => t('مسح QR', 'Scan QR');
  static String get topUp => t('شحن', 'Top up');
  static String get withdraw => t('سحب', 'Withdraw');
  static String get recent => t('آخر الحركات', 'Recent activity');
  static String get seeAll => t('عرض الكل', 'See all');
  static String get noTransactions => t('لا توجد حركات بعد — اشحن محفظتك وابدأ.', 'No transactions yet — top up and get started.');
  static String get sandboxBanner => t('وضع تجريبي: الأموال للاختبار فقط', 'Sandbox: test money only');
  static String pendingRequests(int n) => t('لديك $n طلب دفع بانتظارك', 'You have $n payment request(s) waiting');

  // send / request
  static String get sendTitle => t('إرسال أموال', 'Send money');
  static String get requestTitle => t('طلب أموال', 'Request money');
  static String get recipient => t('رقم جوال المستلم', "Recipient's phone");
  static String get requestFrom => t('اطلب من (رقم الجوال)', 'Request from (phone)');
  static String get amount => t('المبلغ', 'Amount');
  static String get noteField => t('ملاحظة (اختياري)', 'Note (optional)');
  static String get review => t('مراجعة', 'Review');
  static String get confirmTitle => t('تأكيد العملية', 'Confirm');
  static String get to => t('إلى', 'To');
  static String get from => t('من', 'From');
  static String get fee => t('الرسوم', 'Fee');
  static String get total => t('الإجمالي', 'Total');
  static String get confirmAndPay => t('تأكيد ودفع', 'Confirm & pay');
  static String get sendRequest => t('إرسال الطلب', 'Send request');
  static String get success => t('تمت العملية بنجاح', 'Payment successful');
  static String get requestSent => t('تم إرسال الطلب', 'Request sent');
  static String get done => t('تم', 'Done');
  static String get copy => t('نسخ', 'Copy');
  static String get copied => t('تم النسخ', 'Copied');
  static String get reference => t('المرجع', 'Reference');
  static String get date => t('التاريخ', 'Date');
  static String get status => t('الحالة', 'Status');

  // receive / scan
  static String get receiveTitle => t('استلام الأموال', 'Receive money');
  static String get receiveHint => t('اعرض هذا الرمز ليمسحه المرسل، أو شارك رقمك.', 'Show this code to the sender, or share your number.');
  static String get scanTitle => t('امسح رمز الدفع', 'Scan a payment code');
  static String get scanHint => t('وجّه الكاميرا نحو رمز Elyvori Pay', 'Point the camera at an Elyvori Pay code');
  static String get scanUnsupported => t('المسح غير متاح هنا — أدخل الرقم يدوياً.', 'Scanning is not available here — enter the number instead.');

  // requests
  static String get requestsTitle => t('طلبات الدفع', 'Payment requests');
  static String get incoming => t('واردة', 'Incoming');
  static String get outgoing => t('صادرة', 'Outgoing');
  static String get pay => t('ادفع', 'Pay');
  static String get decline => t('رفض', 'Decline');
  static String get cancel => t('إلغاء', 'Cancel');
  static String get noRequests => t('لا توجد طلبات.', 'No requests.');
  static String requestStatus(String s) => switch (s) {
        'pending' => t('بانتظار الدفع', 'Pending'),
        'paid' => t('مدفوع', 'Paid'),
        'declined' => t('مرفوض', 'Declined'),
        'cancelled' => t('ملغى', 'Cancelled'),
        _ => s,
      };

  // card top-up (Stripe)
  static String get cardTopUp => t('شحن بالبطاقة', 'Top up by card');
  static String get sandboxTopUp => t('شحن تجريبي (أموال اختبار)', 'Test top-up (sandbox money)');
  static String get cardHint => t('الدفع آمن عبر Stripe — إليفوري ما بتشوف ولا بتحفظ بيانات بطاقتك.', 'Secure payment by Stripe — Elyvori never sees or stores your card.');
  static String get waitingPayment => t('بانتظار تأكيد الدفع…', 'Waiting for the payment…');
  static String get waitingPaymentHint => t('كمّل الدفع بالصفحة اللي انفتحت، وارجع هون — الرصيد بيتحدّث لحاله.', 'Finish paying on the page that opened, then come back — your balance updates by itself.');
  static String get testCard => t('وضع اختبار: البطاقة 4242 4242 4242 4242، أي تاريخ مستقبلي وأي CVC.', 'Test mode: card 4242 4242 4242 4242, any future date, any CVC.');
  static String get reopenPayment => t('افتح صفحة الدفع', 'Open payment page');
  static String get paymentNotCompleted => t('ما اكتمل الدفع — ما انخصم إشي.', 'The payment did not complete — nothing was charged.');

  /// Server notes -> the app language.
  static String note(String? d) => switch (d) {
        'Sandbox top-up' => t('شحن تجريبي', 'Test top-up'),
        'Sandbox withdrawal' => t('سحب تجريبي', 'Test withdrawal'),
        'Card top-up' => t('شحن بالبطاقة', 'Card top-up'),
        _ => d ?? '',
      };

  // top up / withdraw
  static String get topUpTitle => t('شحن المحفظة', 'Top up');
  static String get topUpHint => t('وضع تجريبي: يضاف المبلغ فوراً كأموال اختبار.', 'Sandbox: the amount is added instantly as test money.');
  static String get withdrawTitle => t('سحب إلى البنك', 'Withdraw to bank');
  static String get withdrawHint => t('وضع تجريبي: الرسوم 1% (2 كحد أدنى، 20 كحد أقصى).', 'Sandbox: 1% fee (min 2, max 20).');

  // history / receipt
  static String get historyTitle => t('سجل الحركات', 'Transactions');
  static String get all => t('الكل', 'All');
  static String txType(String type) => switch (type) {
        'transfer' => t('تحويل', 'Transfer'),
        'topup' => t('شحن', 'Top up'),
        'withdraw' => t('سحب', 'Withdrawal'),
        'request_pay' => t('دفع طلب', 'Request payment'),
        'purchase' => t('شراء خدمة', 'Purchase'),
        'reversal' => t('استرجاع', 'Reversal'),
        _ => type,
      };
  static String get receiptTitle => t('إيصال', 'Receipt');
  static String get reversed => t('مسترجعة', 'Reversed');
  static String get completed => t('مكتملة', 'Completed');

  // settings
  static String get settingsTitle => t('الإعدادات', 'Settings');
  static String get devices => t('الأجهزة المسجّلة', 'Signed-in devices');
  static String get thisDevice => t('هذا الجهاز', 'This device');
  static String get signOutDevice => t('إخراج', 'Sign out');
  static String get changePin => t('تغيير الرمز السري', 'Change PIN');
  static String get currentPin => t('الرمز الحالي', 'Current PIN');
  static String get newPin => t('الرمز الجديد', 'New PIN');
  static String get pinChanged => t('تم تغيير الرمز السري', 'PIN changed');
  static String get limits => t('حدود الحساب', 'Account limits');
  static String get perTx => t('لكل عملية', 'Per payment');
  static String get daily => t('يومياً', 'Daily');
  static String get monthly => t('شهرياً', 'Monthly');
  static String get kyc => t('مستوى التحقق', 'Verification level');
  static String get signOut => t('تسجيل الخروج', 'Sign out');
  static String get support => t('الدعم', 'Support');
  static String get version => t('الإصدار 1.0.0', 'Version 1.0.0');

  /// Server error codes -> friendly sentences.
  static String error(String code) => switch (code) {
        'invalid_phone' => t('رقم الجوال غير صحيح.', 'Invalid phone number.'),
        'invalid_code' => t('الرمز غير صحيح أو انتهت صلاحيته.', 'The code is wrong or expired.'),
        'too_many_codes' => t('طلبت رموزاً كثيرة، حاول بعد 10 دقائق.', 'Too many codes, try again in 10 minutes.'),
        'phone_taken' => t('هذا الرقم لديه محفظة — سجّل الدخول.', 'This number already has a wallet — sign in.'),
        'pin_too_simple' => t('الرمز سهل جداً، اختر رمزاً آخر.', 'That PIN is too simple, choose another.'),
        'pin_must_be_6_digits' => t('الرمز يجب أن يكون 6 أرقام.', 'The PIN must be 6 digits.'),
        'wrong_pin' => t('الرمز السري غير صحيح.', 'Wrong PIN.'),
        'wrong_phone_or_pin' => t('رقم الجوال أو الرمز السري غير صحيح.', 'Wrong phone or PIN.'),
        'pin_locked' => t('تم قفل المحفظة 15 دقيقة بعد محاولات خاطئة.', 'Wallet locked for 15 minutes after wrong tries.'),
        'insufficient_funds' => t('الرصيد غير كافٍ.', 'Insufficient balance.'),
        'over_transaction_limit' => t('المبلغ أكبر من حد العملية الواحدة.', 'Above your per-payment limit.'),
        'over_daily_limit' => t('تجاوزت حدك اليومي.', 'Daily limit reached.'),
        'over_monthly_limit' => t('تجاوزت حدك الشهري.', 'Monthly limit reached.'),
        'too_many_payments_try_later' => t('عمليات كثيرة خلال وقت قصير، حاول بعد قليل.', 'Too many payments, try again shortly.'),
        'recipient_not_found' => t('لا توجد محفظة نشطة بهذا الرقم.', 'No active wallet with that number.'),
        'cannot_pay_yourself' => t('لا يمكنك الدفع لنفسك.', "You can't pay yourself."),
        'invalid_amount' => t('المبلغ غير صحيح.', 'Invalid amount.'),
        'account_frozen' => t('المحفظة مجمّدة، تواصل مع الدعم.', 'Wallet frozen, contact support.'),
        'request_closed' => t('هذا الطلب لم يعد متاحاً.', 'This request is no longer open.'),
        'session_ended' || 'unauthorized' => t('انتهت الجلسة، سجّل الدخول مجدداً.', 'Session ended, please sign in again.'),
        'offline' => t('لا يوجد اتصال بالإنترنت.', 'No internet connection.'),
        'stripe_unavailable' => t('الدفع بالبطاقة مش متاح هلق، جرّب بعد شوي.', 'Card payments are not available right now.'),
        'stripe_live_key_blocked' => t('الدفع الحقيقي مقفل لحد ما يتفعّل الترخيص.', 'Real-money payments are locked for now.'),
        'amount_too_small' => t('أقل مبلغ للشحن 2.', 'The minimum top-up is 2.'),
        'kyc_required' => t('لازم توثّق حسابك قبل الشحن بالبطاقة.', 'Verify your account before topping up by card.'),
        _ => t('حدث خطأ، حاول مجدداً.', 'Something went wrong, try again.'),
      };
}
