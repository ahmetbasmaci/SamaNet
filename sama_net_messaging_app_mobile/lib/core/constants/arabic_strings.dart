/// Arabic strings for the application
/// Contains all text content in Arabic language
class ArabicStrings {
  // App Info
  static const String appTitle = 'سما نت للمراسلة';
  static const String appSubtitle = 'تواصل مع أصدقائك وعائلتك';

  // Authentication
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب جديد';
  static const String logout = 'تسجيل الخروج';
  static const String nameOrPhone = 'الاسم أو رقم الهاتف';
  static const String password = 'كلمة المرور';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String createNewAccount = 'إنشاء حساب جديد';
  static const String or = 'أو';

  // Validation Messages
  static const String nameOrPhoneRequired = 'الاسم أو رقم الهاتف مطلوب';
  static const String enterValidNameOrPhone = 'يرجى إدخال اسم أو رقم هاتف صحيح';
  static const String passwordRequired = 'كلمة المرور مطلوبة';
  static const String passwordTooShort = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  // Navigation
  static const String chats = 'المحادثات';
  static const String contacts = 'جهات الاتصال';
  static const String profile = 'الملف الشخصي';

  // Messages
  static const String forgotPasswordComingSoon = 'ميزة استعادة كلمة المرور قريباً';
  static const String mainScreenPlaceholder = 'الشاشة الرئيسية\n(سيتم تطبيق قائمة المحادثات والتنقل)';
  static const String registerPagePlaceholder = 'صفحة التسجيل\n(سيتم تطبيقها)';

  // Loading and Status
  static const String loading = 'جاري التحميل...';
  static const String connecting = 'جاري الاتصال...';

  // Common Actions
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String ok = 'موافق';
  static const String send = 'إرسال';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';

  // Error Messages
  static const String errorOccurred = 'حدث خطأ';
  static const String connectionError = 'خطأ في الاتصال';
  static const String invalidCredentials = 'بيانات الدخول غير صحيحة';
  static const String serverError = 'خطأ في الخادم';
  static const String fieldRequired = 'هذا الحقل مطلوب';
  static const String messageCannotBeEmpty = 'لا يمكن أن تكون الرسالة فارغة';
  static const String messageTooLong = 'الرسالة طويلة جداً (الحد الأقصى 1000 حرف)';
  static const String loginFailed = 'فشل تسجيل الدخول';
  static const String registrationFailed = 'فشل التسجيل';

  // Specific login error messages
  static const String wrongUsernameOrPassword = 'اسم المستخدم أو كلمة المرور خاطئة';
  static const String accountNotFound = 'لم يتم العثور على الحساب';
  static const String accountDisabled = 'الحساب غير مفعل';
  static const String networkConnectionError = 'تحقق من اتصال الإنترنت';
  static const String serverUnavailable = 'الخادم غير متاح حالياً';
  static const String requestTimeout = 'انتهت مهلة الطلب، يرجى المحاولة مرة أخرى';
  static const String unexpectedError = 'حدث خطأ غير متوقع';
  static const String emptyUsername = 'يرجى إدخال اسم المستخدم';
  static const String emptyPassword = 'يرجى إدخال كلمة المرور';
  static const String usernameMinLength = 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
  static const String passwordMinLength = 'كلمة المرور يجب أن تكون 3 أحرف على الأقل';
  static const String invalidUsernameFormat = 'اسم المستخدم يحتوي على أحرف غير مسموحة';
  static const String loginSuccessful = 'تم تسجيل الدخول بنجاح';
  static const String pleaseTryAgain = 'يرجى المحاولة مرة أخرى';

  // Search
  static const String search = 'بحث';
  static const String searchByPhone = 'البحث برقم الهاتف';
  static const String enterPhoneNumber = 'أدخل رقم الهاتف';
  static const String searchUsers = 'البحث عن المستخدمين';
  static const String noUsersFound = 'لم يتم العثور على مستخدمين';
  static const String userNotFound = 'المستخدم غير موجود';
  static const String searchResults = 'نتائج البحث';
  static const String startChat = 'بدء محادثة';

  // Messages and Chat
  static const String typeMessage = 'اكتب رسالة...';
  static const String sendMessage = 'إرسال';
  static const String noMessages = 'لا توجد رسائل';
  static const String online = 'متصل';
  static const String offline = 'غير متصل';
  static const String typing = 'يكتب...';
  static const String delivered = 'تم التسليم';
  static const String read = 'تم القراءة';
  static const String sent = 'تم الإرسال';
  static const String messageDeleted = 'تم حذف الرسالة';
  static const String selectImage = 'اختر صورة';
  static const String selectFile = 'اختر ملف';
  static const String camera = 'الكاميرا';
  static const String gallery = 'المعرض';
  static const String attachment = 'مرفق';

  // Date and Time
  static const String today = 'اليوم';
  static const String yesterday = 'أمس';
  static const String justNow = 'الآن';
  static const List<String> weekDays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
}
