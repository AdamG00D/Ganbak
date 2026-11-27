// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'حسناً';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get stopSavingTitle => 'توقف حفظ المحادثات؟';

  @override
  String get stopSavingBody =>
      'المحادثات المحفوظة هتتمسح من تخزين الموبايل (ما عدا اللي اخترت تحفظها بنفسك من جوه المحادثة).';

  @override
  String get stopSavingConfirm => 'وقّف الحفظ';

  @override
  String get savingOnToast => 'المحادثات هتتحفظ على الموبايل (مشفّرة)';

  @override
  String get savingOffToast => 'المحادثات مش هتتحفظ';

  @override
  String get lockOnToast => 'القفل اتفعّل';

  @override
  String get lockOffToast => 'القفل اتشال';

  @override
  String get bioConfirmTitle => 'تأكيد البصمة';

  @override
  String get bioConfirmSubtitle => 'عشان تفتح Wasl بيها';

  @override
  String get wipeTitle => 'مسح كل المحادثات؟';

  @override
  String get wipeBody =>
      'كل الرسايل والملفات المحفوظة هتتمسح من موبايلك نهائياً. بروفايلك والجروبات اللي إنت فيها هيفضلوا.';

  @override
  String get wipeConfirm => 'امسح الكل';

  @override
  String get wipeDone => 'اتمسح كل حاجة';

  @override
  String get blockedTitle => 'المحظورين';

  @override
  String get blockedEmpty => 'مفيش حد محظور.';

  @override
  String get blockedNone => 'مفيش حد';

  @override
  String personShort(Object id) {
    return 'شخص ($id)';
  }

  @override
  String get unblock => 'إلغاء الحظر';

  @override
  String get editProfileHint => 'تعديل الاسم والصورة واللون';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get saveChats => 'حفظ المحادثات على الموبايل';

  @override
  String get saveChatsOn =>
      'الرسايل بتتحفظ مشفّرة وبتلاقيها لما تفتح التطبيق تاني.';

  @override
  String get saveChatsOff =>
      'مقفول: المحادثات بتتمسح لما تقفل التطبيق. تقدر تحفظ محادثة معينة من جواها.';

  @override
  String get appLock => 'قفل التطبيق برقم سري';

  @override
  String get appLockOn => 'متفعّل — اضغط عشان تشيله';

  @override
  String get appLockOff => 'اختياري. من غيره التطبيق بيفتح على طول.';

  @override
  String get unlockWithFingerprint => 'فتح بالبصمة';

  @override
  String get autoLock => 'القفل التلقائي';

  @override
  String get autoLockSub => 'بعد ما تسيب التطبيق';

  @override
  String get lockNow => 'على طول';

  @override
  String get lockMinute => 'دقيقة';

  @override
  String get lock5 => '5 دقايق';

  @override
  String get lock15 => '15 دقيقة';

  @override
  String get wipeAll => 'مسح كل المحادثات';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'غامق';

  @override
  String get appColor => 'لون التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get languageAuto => 'تلقائي';

  @override
  String get languageAutoHint =>
      'تلقائي: زي لغة الموبايل (عربي لو الموبايل عربي، غير كده إنجليزي).';

  @override
  String get about => 'عن التطبيق';

  @override
  String aboutTagline(Object license) {
    return 'شات من غير إنترنت • مفتوح المصدر ($license)';
  }

  @override
  String get sourceCode => 'الكود على GitHub';

  @override
  String get linkCopied => 'اتنسخ اللينك';

  @override
  String get noBrowser => 'مفيش متصفح يفتح اللينك — اتنسخ بداله';

  @override
  String get howNoInternetTitle => 'من غير إنترنت ولا سيرفر';

  @override
  String get howNoInternetBody =>
      'الموبايلات بتكلم بعض مباشرة بالبلوتوث أو على نفس الواي فاي / الهوت سبوت. مفيش حساب ولا رقم موبايل.';

  @override
  String get howMeshTitle => 'شبكة Mesh';

  @override
  String get howMeshBody =>
      'كل موبايل عليه Wasl بيوصّل للي حواليه، فرسالتك تقدر تعدّي على كذا موبايل لحد ما توصل لحد بعيد عنك.';

  @override
  String get howEncryptionTitle => 'تشفير تلقائي';

  @override
  String get howEncryptionBody =>
      'الشات الخاص مشفّر من طرف لطرف بمفاتيح بتتولّد لوحدها — من غير كلمة سر. الموبايلات اللي في النص بتوصّل بس ومبتقراش حاجة.';

  @override
  String get howBothTitle => 'الاتنين مع بعض';

  @override
  String get howBothBody =>
      'لو شغّلت الواي فاي والبلوتوث سوا موبايلك بيبقى كوبري: اللي على هوت سبوت يوصل للي على هوت سبوت تاني عن طريق البلوتوث. المكالمات والفيديو بيفضلوا جوه نفس الشبكة.';

  @override
  String get howGroupsTitle => 'الجروبات';

  @override
  String get howGroupsBody =>
      'عام: أي حد قريب يدخل ويقرا. بكلمة سر أو بطلب انضمام: محدش يقرا غير الأعضاء. الجروب بيفضل ظاهر طول ما فيه عضو قريب.';

  @override
  String get howAdminTitle => 'إدارة الجروب';

  @override
  String get howAdminBody =>
      'صاحب الجروب بيعيّن مديرين، والمدير يشيل أعضاء ويمسح رسايلهم. في جروب \"بطلب انضمام\" المفتاح بيتغير لما حد يتشال فمبيقراش الجديد؛ في العام وبكلمة السر الإزالة حظر بتطبّقه التطبيقات.';

  @override
  String get howNotifTitle => 'الإشعارات';

  @override
  String get howNotifBody =>
      'الإشعار فيه اسم اللي بعت ونص الرسالة. لو مفعّل قفل التطبيق بيبقى \"رسالة جديدة\" بس، وعلى شاشة قفل الموبايل النص مبيظهرش أبداً. تقدر تكتم أي محادثة.';

  @override
  String get howSaveTitle => 'الحفظ اختياري';

  @override
  String get howSaveBody =>
      'الافتراضي إن المحادثات مبتتحفظش وبتتمسح مع قفل التطبيق. لو فعّلت الحفظ بتتخزن مشفّرة على موبايلك بس.';

  @override
  String get howSafetyTitle => 'رمز الأمان';

  @override
  String get howSafetyBody =>
      'لو عايز تتأكد 100% إنك بتكلم الشخص الصح، قارنوا رمز الأمان (6 أرقام) من قايمة المحادثة. اختياري.';

  @override
  String get pinWrong => 'الرقم غلط';

  @override
  String get pinMismatch => 'الرقمين مش زي بعض — ابدأ تاني';

  @override
  String get pinEnterCurrent => 'اكتب الرقم السري الحالي';

  @override
  String get pinChoose => 'اختار رقم سري (4 لـ 8 أرقام)';

  @override
  String get pinRepeat => 'اكتبه تاني للتأكيد';

  @override
  String get colorWasl => 'وصل';

  @override
  String get colorIndigo => 'نيلي';

  @override
  String get colorTeal => 'فيروزي';

  @override
  String get colorEmerald => 'أخضر';

  @override
  String get colorCoral => 'مرجاني';

  @override
  String get colorAmber => 'كهرماني';

  @override
  String get colorSky => 'سماوي';

  @override
  String get colorPink => 'وردي';

  @override
  String get colorGraphite => 'رمادي';

  @override
  String get errRejectedTitle => 'الطرف التاني رفض الاتصال';

  @override
  String get errRejectedHint =>
      'اطلب منه يقبل الطلب لما يظهر عنده، وجرّب تاني.';

  @override
  String get errPeerGoneTitle => 'الجهاز التاني مش ظاهر دلوقتي';

  @override
  String get errPeerGoneHint =>
      'اتأكد إنه لسه فاتح شاشة الدردشة وقريب منك (أقل من 10 متر تقريباً).';

  @override
  String get errReconnectTitle => 'معرفناش نرجّع الاتصال';

  @override
  String get errReconnectHint =>
      'غالباً الجهاز التاني بعد أو قفل الشاشة. افتحوا الدردشة على الجهازين وابدأوا تاني.';

  @override
  String get errNoNetworkTitle => 'مش متوصل بأي شبكة';

  @override
  String get errNoNetworkHint =>
      'شغّل الواي فاي واتوصل بشبكة، أو افتح نقطة اتصال (Hotspot) من الإعدادات وخلّي التاني يتوصل بيها.';

  @override
  String get errHandshakeTitle => 'معرفناش نأمّن الاتصال';

  @override
  String get errHandshakeHint =>
      'حصل خطأ أثناء تبادل مفاتيح التشفير. تأكد إن الجهازين عليهم آخر نسخة من Wasl وجرّب تاني.';

  @override
  String get errNoPlayTitle => 'الدردشة القريبة محتاجة خدمات Google Play';

  @override
  String get errNoPlayHint =>
      'الجهاز ده مفيهوش خدمات Google أو محتاجة تحديث. حدّث \"خدمات Google Play\" من المتجر، أو استخدم الدردشة عبر الواي فاي.';

  @override
  String get errPermissionTitle => 'ناقص إذن';

  @override
  String get errPermissionHint =>
      'التطبيق محتاج إذن \"الأجهزة القريبة\" عشان يلاقي الجهاز التاني. اسمح بيه وجرّب تاني.';

  @override
  String get errRadioTitle => 'البلوتوث أو الواي فاي مش مستجيب';

  @override
  String get errRadioHint =>
      'اقفل البلوتوث وافتحه تاني (ولو ينفع الواي فاي كمان)، وبعدين جرّب. لو المشكلة استمرت اعمل ريستارت للموبايل.';

  @override
  String get errAlreadyConnectedTitle => 'فيه اتصال قديم لسه مفتوح';

  @override
  String get errAlreadyConnectedHint =>
      'اقفل شاشة الدردشة على الجهازين وافتحها تاني.';

  @override
  String get errTimeoutTitle => 'الاتصال أخد وقت أطول من اللازم';

  @override
  String get errTimeoutHint => 'قرّب الجهازين من بعض وجرّب تاني.';

  @override
  String get errGenericTitle => 'حصلت مشكلة في الاتصال';

  @override
  String get errGenericHint =>
      'جرّب تقفل الدردشة وتفتحها تاني على الجهازين. لو المشكلة فضلت، اقفل البلوتوث وافتحه.';

  @override
  String get errRefusedTitle => 'الجهاز التاني مش مستني اتصال';

  @override
  String get errRefusedHint =>
      'اتأكد إنه داس \"استضافة\" وإن العنوان مكتوب صح.';

  @override
  String get errNoReplyTitle => 'مفيش رد من العنوان ده';

  @override
  String get errNoReplyHint =>
      'الجهازين لازم يكونوا على نفس شبكة الواي فاي (أو واحد فاتح Hotspot والتاني متوصل بيه). بعض الراوترات العامة بتمنع الأجهزة تكلم بعض.';

  @override
  String get errUnreachableTitle => 'مش متوصل بشبكة';

  @override
  String get errUnreachableHint =>
      'شغّل الواي فاي واتوصل بنفس الشبكة اللي عليها الجهاز التاني.';

  @override
  String get errFailedTitle => 'تعذّر الاتصال';

  @override
  String get errFailedHint => 'اتأكد من العنوان وإن الجهازين على نفس الشبكة.';

  @override
  String get errLanStartTitle => 'معرفناش نبدأ على الشبكة';

  @override
  String get errLanStartHint =>
      'اقفل التطبيق وافتحه تاني. لو المشكلة فضلت اعمل ريستارت للواي فاي.';

  @override
  String get copiedSecure => 'تم النسخ — هيتمسح من الحافظة بعد 30 ثانية';

  @override
  String get notDelivered => 'موصلتش';

  @override
  String get lockBioTitle => 'افتح Wasl';

  @override
  String get lockBioSubtitle => 'بصمتك بدل الرقم السري';

  @override
  String get lockIncomingCall => 'مكالمة واردة — افتح القفل';

  @override
  String get lockEnterPin => 'اكتب الرقم السري';

  @override
  String get lockWrongPin => 'الرقم غلط — جرّب تاني';

  @override
  String get unknownName => 'مجهول';

  @override
  String get otherSide => 'الطرف الآخر';

  @override
  String get hello => 'أهلاً';

  @override
  String get transportHeadline => 'هتتكلم\nإزاي النهارده؟';

  @override
  String get transportSub => 'من غير إنترنت في الحالتين، وكل حاجة مشفّرة.';

  @override
  String get bluetooth => 'بلوتوث';

  @override
  String get bluetoothDesc =>
      'للناس القريبة منك من غير أي شبكة. الرسايل بتعدّي من موبايل لموبايل فبتوصل لأبعد.';

  @override
  String get tagNoNetwork => 'من غير شبكة';

  @override
  String get wifi => 'واي فاي';

  @override
  String get wifiDesc =>
      'نفس الواي فاي أو هوت سبوت من موبايل. أسرع بكتير، وفيه فيديو ومكالمات صوت وصورة.';

  @override
  String get tagFaster => 'أسرع';

  @override
  String get tagCalls => 'مكالمات';

  @override
  String get tagVideo => 'فيديو';

  @override
  String get both => 'الاتنين مع بعض';

  @override
  String get bothDesc =>
      'موبايلك يبقى كوبري: يوصّل اللي على الواي فاي أو الهوت سبوت باللي على البلوتوث، فكذا شبكة تبقى شبكة واحدة.';

  @override
  String get tagBridge => 'كوبري';

  @override
  String get tagRange => 'أوسع مدى';

  @override
  String get tagBattery => 'بطارية أكتر';

  @override
  String get photoUnusable => 'معرفناش نستخدم الصورة دي — جرّب صورة تانية';

  @override
  String get galleryFailed => 'معرفناش نفتح المعرض';

  @override
  String get nameTooShort => 'اكتب اسم من حرفين على الأقل';

  @override
  String get profileSaveFailed => 'معرفناش نحفظ البروفايل';

  @override
  String get profile => 'البروفايل';

  @override
  String get appTitle => 'وَصْل';

  @override
  String get createProfile => 'اعمل بروفايلك';

  @override
  String get createProfileSub =>
      'اسم وصورة يشوفهم الناس اللي حواليك. من غير رقم موبايل ولا إيميل ولا إنترنت — كل حاجة على موبايلك بس.';

  @override
  String get removePhoto => 'شيل الصورة';

  @override
  String get yourName => 'اسمك';

  @override
  String get profileColor => 'لون البروفايل';

  @override
  String get orCartoon => 'أو اختار أفاتار كرتوني';

  @override
  String get letsStart => 'يلا نبدأ';

  @override
  String get save => 'حفظ';

  @override
  String get reqNearbyTitle => 'إذن الأجهزة القريبة';

  @override
  String get reqNearbyWhy =>
      'عشان Wasl يلاقي الموبايلات القريبة ويتصل بيها بالبلوتوث. مش بيستخدم موقعك.';

  @override
  String get reqWifiTitle => 'إذن أجهزة الواي فاي القريبة';

  @override
  String get reqWifiWhy =>
      'بيخلي الرسايل تتنقل أسرع بالواي فاي المباشر لما الجهازين قريبين.';

  @override
  String get reqLocationTitle => 'إذن الموقع';

  @override
  String reqLocationWhy(Object version) {
    return 'أندرويد $version بيشترط إذن الموقع لأي بحث عن أجهزة قريبة. Wasl مش بيقرا موقعك ولا بيحفظه.';
  }

  @override
  String get android11OrOlder => '11 وأقدم';

  @override
  String get reqBluetoothTitle => 'تشغيل البلوتوث';

  @override
  String get reqBluetoothWhy => 'الجهازين بيلاقوا بعض عن طريق البلوتوث.';

  @override
  String get reqGpsTitle => 'تشغيل خدمة الموقع (GPS)';

  @override
  String get reqGpsWhy =>
      'في الإصدار ده من أندرويد البحث عن الأجهزة مش بيشتغل غير والموقع شغال.';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get allow => 'اسمح';

  @override
  String get turnOn => 'شغّل';

  @override
  String get callIncomingVideo => 'مكالمة فيديو واردة';

  @override
  String get callIncomingVoice => 'مكالمة صوتية واردة';

  @override
  String get callRinging => 'بيرن...';

  @override
  String get callConnecting => 'جاري التوصيل...';

  @override
  String get callEnded => 'المكالمة خلصت';

  @override
  String get cameraOff => 'الكاميرا مقفولة';

  @override
  String get me => 'أنا';

  @override
  String get e2eEncrypted => 'مشفّرة من طرف لطرف';

  @override
  String get decline => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get flipCamera => 'قلب الكاميرا';

  @override
  String get camera => 'الكاميرا';

  @override
  String get mute => 'كتم';

  @override
  String get muted => 'مكتوم';

  @override
  String get speaker => 'السماعة';

  @override
  String get earpiece => 'الأذن';

  @override
  String get callBusy => 'فيه مكالمة شغالة بالفعل';

  @override
  String get notConnectedNow => 'مش متصل دلوقتي';

  @override
  String get callNoAnswer => 'مفيش رد';

  @override
  String get callConnectFailed => 'معرفناش نوصّل المكالمة';

  @override
  String get callStartFailed => 'معرفناش نشغّل المكالمة';

  @override
  String get callMediaFailed => 'معرفناش نشغّل الميكروفون/الكاميرا';

  @override
  String get callRejected => 'اترفضت';

  @override
  String get callMissed => 'فاتتك مكالمة';

  @override
  String get callPeerRejected => 'الطرف التاني رفض المكالمة';

  @override
  String get callPeerBusy => 'الطرف التاني في مكالمة تانية';

  @override
  String get callPeerHungUp => 'الطرف التاني قفل المكالمة';

  @override
  String get callProblem => 'حصلت مشكلة في المكالمة';

  @override
  String get callIceFailed => 'الاتصال فشل — اتأكدوا إنكم على نفس الشبكة';

  @override
  String get micDeniedForever =>
      'إذن الميكروفون مرفوض — فعّله من إعدادات التطبيق';

  @override
  String get micNeededCall => 'محتاجين إذن الميكروفون عشان المكالمة';

  @override
  String get camDeniedForever =>
      'إذن الكاميرا مرفوض — فعّله من إعدادات التطبيق';

  @override
  String get camNeededCall => 'محتاجين إذن الكاميرا عشان مكالمة الفيديو';

  @override
  String get callDropped => 'الاتصال قطع';

  @override
  String get chatEnded => 'المحادثة انتهت';

  @override
  String get micNeededRecord => 'محتاجين إذن الميكروفون عشان نسجّل';

  @override
  String get micStartFailed => 'معرفناش نشغّل الميكروفون';

  @override
  String get holdToRecord => 'اضغط على الميكروفون واستمر ضاغط عشان تسجّل';

  @override
  String get recordFailed => 'التسجيل مكملش — جرّب تاني';

  @override
  String get emojiNoRecents => 'الإيموجي اللي بتستخدمها هتظهر هنا';

  @override
  String get emojiSearch => 'دوّر على إيموجي (بالإنجليزي)';

  @override
  String get keyboard => 'الكيبورد';

  @override
  String get emoji => 'إيموجي';

  @override
  String get messageHint => 'رسالة';

  @override
  String get waitingConnection => 'مستني الاتصال...';

  @override
  String get attachments => 'مرفقات';

  @override
  String get photoHoldVideo => 'صورة (اضغط مطولاً للفيديو)';

  @override
  String get photo => 'صورة';

  @override
  String get delete => 'امسح';

  @override
  String get slideToCancel => 'اسحب للإلغاء';

  @override
  String get theOtherSide => 'الطرف التاني';

  @override
  String get forwarded => 'محوّلة';

  @override
  String get edited => 'معدّلة';

  @override
  String get you => 'انت';

  @override
  String compareSafety(Object name) {
    return 'قارن رمز الأمان مع $name';
  }

  @override
  String get compareSafetyHint =>
      'تأكيد إضافي (اختياري): لو نفس الرقم ظاهر على الموبايل التاني يبقى متأكدين ١٠٠٪ إن محدش في النص.';

  @override
  String get different => 'مختلف';

  @override
  String get matches => 'متطابق';

  @override
  String get attachDocument => 'مستند';

  @override
  String get attachCamera => 'كاميرا';

  @override
  String get attachGallery => 'المعرض';

  @override
  String get attachAudio => 'صوت';

  @override
  String get videoWifiOnlyHint =>
      'الفيديو متاح في دردشة الواي فاي / الهوت سبوت (البلوتوث أبطأ من كده).';

  @override
  String get video => 'فيديو';

  @override
  String get videoWifiOnly => 'الفيديو متاح في دردشة الواي فاي بس';

  @override
  String get cameraPermission =>
      'محتاجين إذن الكاميرا — فعّله من إعدادات التطبيق';

  @override
  String get cameraFailed => 'معرفناش نفتح الكاميرا';

  @override
  String get videoWifiOnlyPhotosSent =>
      'الفيديو متاح في دردشة الواي فاي بس — اتبعتت الصور بس';

  @override
  String get videoCompressFailed => 'معرفناش نضغط الفيديو — هيتبعت زي ما هو';

  @override
  String get preparingVideo => 'بنجهّز الفيديو';

  @override
  String get preparingVideoBody =>
      'بنصغّره عشان يشتغل على أي موبايل ويتبعت أسرع.';

  @override
  String get filesFailed => 'معرفناش نفتح الملفات';

  @override
  String fileTooBig(Object size) {
    return 'الملف أكبر من $size';
  }

  @override
  String get readFileFailed => 'معرفناش نقرا الملف';

  @override
  String get sendFailedRetry => 'موصلش — ابعته تاني';

  @override
  String get fileIncomplete => 'الملف موصلش كامل';

  @override
  String get file => 'ملف';

  @override
  String waitingReconnectPct(Object pct) {
    return 'مستني الاتصال يرجع... $pct%';
  }

  @override
  String pctOfSize(Object pct, Object size) {
    return '$pct% من $size';
  }

  @override
  String waitingConnectionPct(Object pct) {
    return 'مستني الاتصال... $pct%';
  }

  @override
  String get cancelSending => 'إلغاء الإرسال';

  @override
  String get cancelReceiving => 'إلغاء الاستلام';

  @override
  String get saveToDownloads => 'حفظ في التنزيلات';

  @override
  String get noAppToOpen =>
      'مفيش تطبيق على الموبايل يفتح النوع ده — احفظه أو شاركه';

  @override
  String get storagePermission => 'محتاجين إذن التخزين عشان نحفظ الملف';

  @override
  String get savedToDownloads => 'اتحفظ في التنزيلات ← Wasl';

  @override
  String get saveFileFailed => 'معرفناش نحفظ الملف';

  @override
  String get tapToOpen => 'اضغط عشان تفتحه';

  @override
  String get photosPermission => 'محتاجين إذن الوصول للصور';

  @override
  String get savedToGallery => 'اتحفظ في المعرض';

  @override
  String get openWithOtherApp => 'افتح بتطبيق تاني';

  @override
  String get saveToGallery => 'حفظ في المعرض';

  @override
  String get share => 'مشاركة';

  @override
  String get videoCantPlay =>
      'الفيديو وصل سليم، بس المشغّل اللي جوه التطبيق مش قادر يشغّل النوع ده.';

  @override
  String get saveItToGallery => 'احفظه في المعرض';

  @override
  String get groupNobodyReachable => 'مفيش حد من الجروب واصلين له دلوقتي';

  @override
  String get videoWifiOnlyShort => 'الفيديو متاح في الواي فاي بس';

  @override
  String get fileEmpty => 'الملف فاضي';

  @override
  String get notAValidVideo => 'الملف ده مش فيديو سليم — اختاره تاني من المعرض';

  @override
  String groupMaxSize(Object size) {
    return 'أقصى حجم في الجروبات $size';
  }

  @override
  String get sendFileFailed => 'معرفناش نبعت الملف';

  @override
  String get connectionStoppedEarly => 'الاتصال وقف قبل ما يكمل';

  @override
  String memberJoined(Object name) {
    return '$name دخل الجروب';
  }

  @override
  String memberLeft(Object name) {
    return '$name خرج من الجروب';
  }

  @override
  String get arrivedIncomplete => 'وصل ناقص';

  @override
  String get arrivedCorrupt => 'وصل مختلف عن الأصلي';

  @override
  String get sendingStoppedEarly => 'الإرسال وقف قبل ما يكمل';

  @override
  String joinAccepted(Object group) {
    return 'اتقبلت في \"$group\" 🎉';
  }

  @override
  String joinRejected(Object group) {
    return 'طلبك لدخول \"$group\" اترفض';
  }

  @override
  String get leaveTitle => 'تقفل الاتصال؟';

  @override
  String get leaveBodyUnsaved =>
      'هتبقى مش ظاهر للناس، والمحادثات اللي مش محفوظة هتتمسح.';

  @override
  String get leaveBody => 'هتبقى مش ظاهر للناس لحد ما تدخل تاني.';

  @override
  String get disconnect => 'اقفل';

  @override
  String get newChat => 'محادثة جديدة';

  @override
  String get newGroup => 'جروب جديد';

  @override
  String get tabChats => 'المحادثات';

  @override
  String get tabGroups => 'الجروبات';

  @override
  String get tabNearby => 'القريبين';

  @override
  String get back => 'رجوع';

  @override
  String get preparing => 'بنجهّز...';

  @override
  String get searchingPeople => 'بندوّر على ناس حواليك';

  @override
  String peopleNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص قريب',
      few: '$count أشخاص قريبين',
      two: '$count أشخاص قريبين',
      one: '$count شخص قريب',
    );
    return '$_temp0';
  }

  @override
  String get tryAgain => 'حاول تاني';

  @override
  String get openWifi => 'افتح الواي فاي';

  @override
  String get yesterday => 'أمس';

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get pin => 'تثبيت فوق';

  @override
  String get unmuteNotifications => 'إلغاء كتم الإشعارات';

  @override
  String get muteNotifications => 'كتم الإشعارات';

  @override
  String get unsaveChat => 'إلغاء حفظ المحادثة';

  @override
  String get saveChat => 'حفظ المحادثة على الموبايل';

  @override
  String get leaveGroup => 'الخروج من الجروب';

  @override
  String get deleteChat => 'حذف المحادثة';

  @override
  String get chatSavedToast => 'المحادثة بتتحفظ على الموبايل';

  @override
  String get chatUnsavedToast => 'المحادثة مبقتش بتتحفظ';

  @override
  String leaveGroupTitle(Object name) {
    return 'الخروج من \"$name\"؟';
  }

  @override
  String deleteChatTitle(Object name) {
    return 'حذف المحادثة مع $name؟';
  }

  @override
  String get messagesErasedBody => 'الرسايل هتتمسح من موبايلك.';

  @override
  String get leave => 'خروج';

  @override
  String get deleteAction => 'حذف';

  @override
  String get typing => 'بيكتب...';

  @override
  String nameTyping(Object name) {
    return '$name بيكتب...';
  }

  @override
  String groupOfMode(Object mode) {
    return 'جروب $mode';
  }

  @override
  String get tapToStart => 'اضغط وابدأ الكلام';

  @override
  String youPrefix(Object text) {
    return 'إنت: $text';
  }

  @override
  String get noChatsTitle => 'لسه مفيش محادثات';

  @override
  String get noChatsBody =>
      'اختار حد أو جروب من القريبين وابدأ الكلام. التشفير بيتعمل تلقائي من غير كلمة سر.';

  @override
  String get startNewChat => 'ابدأ محادثة جديدة';

  @override
  String get noGroupsTitle => 'مفيش جروبات حواليك';

  @override
  String get noGroupsBody =>
      'اعمل جروب عام لأي حد قريب، أو خاص بكلمة سر أو بموافقتك. الجروب بيظهر للكل طول ما فيه عضو قريب.';

  @override
  String get createGroup => 'اعمل جروب';

  @override
  String get myGroups => 'جروباتي';

  @override
  String get groupsAround => 'جروبات حواليك';

  @override
  String groupsAroundCount(Object count) {
    return 'جروبات حواليك ($count)';
  }

  @override
  String membersNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أعضاء قريبين',
      one: '$count عضو قريب',
    );
    return '$_temp0';
  }

  @override
  String get waiting => 'مستني';

  @override
  String get requestJoin => 'اطلب';

  @override
  String get join => 'ادخل';

  @override
  String get ipFormat => 'اكتب العنوان بالشكل ده: 192.168.1.5';

  @override
  String get ipConnected => 'اتوصلنا — هيظهر في القايمة دلوقتي';

  @override
  String get searchWifiHint =>
      'أي حد فاتح Wasl على نفس الواي فاي (أو متوصل بالهوت سبوت بتاعك) هيظهر هنا لوحده.';

  @override
  String get searchBtHint =>
      'أي حد قريب فاتح Wasl على البلوتوث هيظهر هنا لوحده. البحث بياخد من ثواني لدقيقة.';

  @override
  String peopleTapToTalk(Object count) {
    return 'أشخاص — اضغط على أي حد عشان تكلمه ($count)';
  }

  @override
  String get meshHint =>
      'الأجهزة بتوصّل لبعض: ممكن تكلم حد بعيد عنك عن طريق موبايلات في النص، ومحدش منهم يقدر يقرا رسايلك.';

  @override
  String get connectByAddress => 'اتصال بالعنوان';

  @override
  String connectByAddressHint(Object addresses) {
    return 'لو الشبكة مانعة الاكتشاف التلقائي (زي بعض شبكات الكافيهات). عنوانك: $addresses';
  }

  @override
  String get listSeparator => ' ، ';

  @override
  String get otherDeviceAddress => 'عنوان الجهاز التاني';

  @override
  String get connect => 'اتصل';

  @override
  String get someoneMissing => 'حد مش ظاهر؟ اتصل بعنوانه';

  @override
  String get connectedDirectly => 'متصل بيك مباشرة';

  @override
  String viaRelays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أجهزة',
      two: 'جهازين',
      one: 'جهاز واحد',
    );
    return 'عن طريق $_temp0 في النص';
  }

  @override
  String get oneStepTitle => 'خطوة واحدة قبل ما نبدأ';

  @override
  String get oneStepBody =>
      'البلوتوث بيشتغل من غير إنترنت، وعشان الموبايلات تلاقي بعض محتاجين الحاجات دي:';

  @override
  String get permissionBlockedHint =>
      'الإذن ده اترفض قبل كده — فعّله من الإعدادات ← الأذونات.';

  @override
  String get modeOpen => 'عام';

  @override
  String get modePassword => 'بكلمة سر';

  @override
  String get modeAsk => 'بطلب انضمام';

  @override
  String get groupNameNeeded => 'اكتب اسم للجروب';

  @override
  String get passwordTooShort => 'كلمة السر 4 حروف على الأقل';

  @override
  String get createGroupFailed => 'معرفناش نعمل الجروب';

  @override
  String get modeOpenExplain => 'أي حد قريب يشوف الجروب ويدخل على طول.';

  @override
  String get modePasswordExplain =>
      'الجروب ظاهر، بس محدش يدخل ولا يقرا غير اللي معاه كلمة السر.';

  @override
  String get modeAskExplain => 'اللي عايز يدخل يبعتلك طلب، وإنت توافق أو ترفض.';

  @override
  String get groupName => 'اسم الجروب';

  @override
  String get groupPassword => 'كلمة سر الجروب';

  @override
  String get createGroupButton => 'إنشاء الجروب';

  @override
  String get joinGroupFailed => 'معرفناش ندخل الجروب';

  @override
  String get requestPendingTitle => 'الطلب لسه مستني';

  @override
  String get requestPendingBody => 'صاحب الجروب لسه مردّش على طلبك.';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get keepWaiting => 'هستنى';

  @override
  String requestJoinTitle(Object name) {
    return 'طلب انضمام لـ \"$name\"';
  }

  @override
  String get requestJoinBody =>
      'هنبعت طلب لصاحب الجروب، وأول ما يوافق هتدخل تلقائياً.';

  @override
  String get sendRequest => 'ابعت الطلب';

  @override
  String get requestSent => 'الطلب اتبعت — مستنيين الموافقة';

  @override
  String get privateGroupPassword =>
      'الجروب ده خاص — اكتب كلمة السر عشان تدخل.';

  @override
  String get password => 'كلمة السر';

  @override
  String get enter => 'دخول';

  @override
  String get roleOwner => 'صاحب الجروب';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get member => 'عضو';

  @override
  String get onlineNow => 'متصل دلوقتي';

  @override
  String get privateMessage => 'رسالة خاصة';

  @override
  String get privateMessageSub => 'مشفّرة بينكم انتوا الاتنين بس';

  @override
  String get voiceCall => 'مكالمة صوتية';

  @override
  String get mention => 'منشن';

  @override
  String get removeAdmin => 'شيله من الإدارة';

  @override
  String get makeAdmin => 'خليه مدير';

  @override
  String get removeFromGroup => 'شيله من الجروب';

  @override
  String get unban => 'رجّعه للجروب';

  @override
  String get block => 'حظر';

  @override
  String get blockSub => 'مش هتشوف رسايله في أي مكان';

  @override
  String kickTitle(Object name) {
    return 'تشيل $name من الجروب؟';
  }

  @override
  String get kickAsk =>
      'مفتاح الجروب هيتغير، فمش هيقدر يقرا أي رسالة جديدة ولا يدخل تاني غير بموافقة.';

  @override
  String get kickPassword =>
      'رسايله مش هتظهر لحد ومش هيقدر يبعت. بس هو لسه عارف كلمة السر — لو عايز تمنعه يقرا خالص اعمل جروب جديد بكلمة تانية.';

  @override
  String get kickOpen =>
      'رسايله مش هتظهر لحد ومش هيقدر يبعت. الجروب العام أي حد قريب يقدر يقراه.';

  @override
  String get kickConfirm => 'شيله';

  @override
  String kicked(Object name) {
    return '$name اتشال من الجروب';
  }

  @override
  String unbanned(Object name) {
    return '$name يقدر يدخل الجروب تاني';
  }

  @override
  String blockTitle(Object name) {
    return 'حظر $name؟';
  }

  @override
  String get blockBody =>
      'مش هيقدر يبعتلك رسايل ولا هتشوف رسايله في الجروبات. تقدر تلغي الحظر من الإعدادات.';

  @override
  String get groupInfo => 'معلومات الجروب';

  @override
  String get notInGroup => 'مبقتش في الجروب ده';

  @override
  String get rename => 'تغيير الاسم';

  @override
  String get youOwnIt => 'إنت صاحبه';

  @override
  String ownedBy(Object name) {
    return 'صاحبه $name';
  }

  @override
  String joinRequests(Object count) {
    return 'طلبات انضمام ($count)';
  }

  @override
  String get removedBefore => 'اتشال من الجروب قبل كده';

  @override
  String onlineCount(Object count) {
    return 'متصلين دلوقتي ($count)';
  }

  @override
  String get youName => 'إنت';

  @override
  String get ownerHint =>
      'اضغط على أي عضو: رسالة خاصة، تخليه مدير، أو تشيله من الجروب. إنت صاحب الجروب ومحدش يقدر يشيلك.';

  @override
  String get adminHint =>
      'إنت مدير: تقدر تشيل الأعضاء، تمسح رسايلهم، وتغيّر اسم الجروب.';

  @override
  String get memberHint =>
      'اضغط على أي عضو عشان تكلمه شات خاص — مشفّر بينكم انتوا الاتنين بس، حتى باقي الجروب مش بيشوفه.';

  @override
  String bannedCount(Object count) {
    return 'اتشالوا من الجروب ($count)';
  }

  @override
  String get letBack => 'رجّعه';

  @override
  String get groupMessagesErased => 'رسايل الجروب هتتمسح من موبايلك.';

  @override
  String get callStartNow => 'معرفناش نبدأ المكالمة دلوقتي';

  @override
  String get messageGone => 'الرسالة دي مبقتش موجودة';

  @override
  String get noForwardTarget => 'مفيش محادثة متصلة دلوقتي تحوّل ليها';

  @override
  String get forwardTo => 'تحويل لـ';

  @override
  String get group => 'جروب';

  @override
  String get privateChat => 'محادثة خاصة';

  @override
  String forwardedTo(Object name) {
    return 'اتحوّلت لـ $name';
  }

  @override
  String get statusSending => 'بتتبعت...';

  @override
  String get statusSentGroup => 'اتبعتت';

  @override
  String get statusSent => 'اتبعتت ولسه موصلتش';

  @override
  String get statusDeliveredGroup => 'حد قراها';

  @override
  String get statusDelivered => 'وصلت';

  @override
  String get statusReadGroup => 'كل المتصلين قروها';

  @override
  String get statusRead => 'اتقرت';

  @override
  String get statusFailed => 'متبعتتش';

  @override
  String get messageInfo => 'معلومات الرسالة';

  @override
  String readByCount(Object count) {
    return 'قروها ($count)';
  }

  @override
  String get nobodyYet => 'لسه محدش';

  @override
  String onlineNotReadCount(Object count) {
    return 'متصلين ولسه مقروهاش ($count)';
  }

  @override
  String get codeMismatchTitle => 'الرمز مختلف؟';

  @override
  String get codeMismatchBody =>
      'ده معناه إن ممكن حد منتحل شخصية الطرف التاني. متبعتش حاجة حساسة، واحظره من القايمة لو مش متأكد منه.';

  @override
  String get unsaveChatTitle => 'إلغاء حفظ المحادثة؟';

  @override
  String get unsaveChatBody =>
      'الرسايل هتتمسح من تخزين الموبايل، وهتفضل قدامك لحد ما تقفل التطبيق بس.';

  @override
  String get unsaveConfirm => 'إلغاء الحفظ';

  @override
  String get chatSavedEncryptedToast => 'المحادثة بتتحفظ على الموبايل (مشفّرة)';

  @override
  String get clearTitle => 'مسح الرسايل؟';

  @override
  String get clearBody => 'الرسايل هتتمسح من عندك بس.';

  @override
  String get clear => 'مسح';

  @override
  String get blockDirectBody =>
      'مش هيقدر يبعتلك رسايل ولا هيظهر في القريبين. تقدر تلغي الحظر من الإعدادات.';

  @override
  String get deleteChatQ => 'حذف المحادثة؟';

  @override
  String get deleteChatBody => 'المحادثة ورسايلها هتتمسح من موبايلك.';

  @override
  String get otherEmoji => 'إيموجي تاني';

  @override
  String get reply => 'رد';

  @override
  String get forward => 'تحويل';

  @override
  String get copy => 'نسخ';

  @override
  String privateMessageTo(Object name) {
    return 'رسالة خاصة لـ $name';
  }

  @override
  String mentionName(Object name) {
    return 'منشن لـ $name';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get deleteForBoth => 'حذف عندي وعنده';

  @override
  String get deleteForAll => 'حذف عند الكل';

  @override
  String get deleteForAllAdmin => 'حذف عند الكل (إنت مدير)';

  @override
  String get deleteForMe => 'حذف عندي بس';

  @override
  String get editMessage => 'تعديل الرسالة';

  @override
  String typingOne(Object name) {
    return '$name بيكتب';
  }

  @override
  String typingTwo(Object a, Object b) {
    return '$a و$b بيكتبوا';
  }

  @override
  String typingMany(Object count) {
    return '$count بيكتبوا';
  }

  @override
  String get chatClosed => 'المحادثة اتقفلت';

  @override
  String get noMembersNearby => 'مفيش حد من الأعضاء قريب دلوقتي';

  @override
  String membersOnline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أعضاء متصلين دلوقتي',
      one: '$count عضو متصلين دلوقتي',
    );
    return '$_temp0';
  }

  @override
  String get blocked => 'محظور';

  @override
  String get encryptedVerified => 'مشفّرة • الرمز متأكد';

  @override
  String get securing => 'بنأمّن الاتصال...';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get videoCall => 'مكالمة فيديو';

  @override
  String get joinRequestsTooltip => 'طلبات انضمام';

  @override
  String get searchChat => 'بحث في المحادثة';

  @override
  String get membersAndInfo => 'الأعضاء ومعلومات الجروب';

  @override
  String get safetyCodeOptional => 'رمز الأمان (اختياري)';

  @override
  String get clearMessages => 'مسح الرسايل';

  @override
  String peerOfflineWifi(Object name) {
    return '$name مش على الشبكة دلوقتي. أول ما يفتح التطبيق على نفس الواي فاي هتقدر تكلمه.';
  }

  @override
  String peerOfflineBt(Object name) {
    return '$name مش قريب دلوقتي. أول ما يقرب ويفتح التطبيق هتقدر تكلمه.';
  }

  @override
  String get noDeviceNearby =>
      'مفيش أي جهاز قريب دلوقتي — الرسايل بتتبعت لما يبقى فيه حد واصلين له.';

  @override
  String get cancelSendingQ => 'إلغاء الإرسال؟';

  @override
  String get cancelReceivingQ => 'إلغاء الاستلام؟';

  @override
  String get cancelSendingBody =>
      'الملف هيتشال من المحادثة عندك وعند الطرف التاني.';

  @override
  String get cancelReceivingBody => 'الملف هيتشال من عندك ومش هيكمّل.';

  @override
  String get cancelTransfer => 'إلغاء النقل';

  @override
  String get notificationsBack => 'الإشعارات رجعت للمحادثة دي';

  @override
  String get muteHour => 'ساعة';

  @override
  String get mute8Hours => '8 ساعات';

  @override
  String get muteWeek => 'أسبوع';

  @override
  String get muteAlways => 'دايماً';

  @override
  String get mutedGroupToast => 'اتكتم — المنشن بس هو اللي هيبعتلك إشعار';

  @override
  String get mutedToast => 'إشعارات المحادثة دي اتكتمت';

  @override
  String get closeSearch => 'قفل البحث';

  @override
  String get searchInChat => 'دوّر في المحادثة';

  @override
  String get none => 'مفيش';

  @override
  String get older => 'الأقدم';

  @override
  String get newer => 'الأحدث';

  @override
  String get startGroupTalk => 'ابدأ الكلام في الجروب';

  @override
  String get sayHello => 'قول أهلاً 👋';

  @override
  String get emptyGroupEnc =>
      'رسايل الجروب مشفّرة بمفتاحه ومبتعدّيش على أي سيرفر.';

  @override
  String get emptyDirectEnc =>
      'الرسايل مشفّرة من طرف لطرف تلقائياً — من غير كلمة سر ومن غير إنترنت.';

  @override
  String get emptySaved => 'المحادثة دي بتتحفظ على موبايلك.';

  @override
  String get emptyNotSaved => 'المحادثة دي مش بتتحفظ: هتتمسح لما تقفل التطبيق.';

  @override
  String get notFinished => 'مكملش';

  @override
  String get chatEncryptedSystem => 'المحادثة مشفرة من طرف لطرف 🔒';

  @override
  String get safetyVerifiedSystem => 'تم التحقق من رمز الأمان ✓';

  @override
  String get previewPhoto => '📷 صورة';

  @override
  String get previewVideo => '🎥 فيديو';

  @override
  String get previewVoice => '🎤 رسالة صوتية';

  @override
  String previewFile(Object name) {
    return '📄 $name';
  }

  @override
  String sizeGb(Object n) {
    return '$n جيجا';
  }

  @override
  String sizeMb(Object n) {
    return '$n ميجا';
  }

  @override
  String get readFileFromPhoneFailed => 'معرفناش نقرا الملف من الموبايل';

  @override
  String get peerGotCorrupt => 'وصل بايظ عند التاني — ابعته تاني';

  @override
  String get peerCanceledReceive => 'التاني لغى الاستلام';

  @override
  String get personNearby => 'شخص قريب';

  @override
  String get groupCreatedOpen => 'الجروب اتعمل — أي حد قريب يقدر يدخل';

  @override
  String get groupCreatedPassword => 'الجروب اتعمل — الدخول بكلمة السر';

  @override
  String get groupCreatedAsk => 'الجروب اتعمل — الدخول بموافقتك';

  @override
  String get networkNotRunning => 'الشبكة مش شغالة';

  @override
  String get wrongPassword => 'كلمة السر غلط';

  @override
  String get groupNeedsApproval => 'الجروب ده محتاج موافقة صاحبه';

  @override
  String get ownerOffline => 'صاحب الجروب مش متصل دلوقتي — جرّب لما يكون قريب';

  @override
  String get sendRequestFailed => 'معرفناش نبعت الطلب';

  @override
  String get notAllowed => 'مش من صلاحياتك';

  @override
  String get noConnectionNow => 'مفيش اتصال دلوقتي';

  @override
  String youKicked(Object name) {
    return 'شلت $name من الجروب';
  }

  @override
  String get ownerOnly => 'صاحب الجروب بس اللي يقدر يعمل كده';

  @override
  String get maxAdmins => 'وصلت لأقصى عدد مديرين';

  @override
  String youMadeAdmin(Object name) {
    return 'خليت $name مدير';
  }

  @override
  String youRemovedAdmin(Object name) {
    return 'شلت $name من الإدارة';
  }

  @override
  String get adminsOnlyRename => 'المديرين بس اللي يقدروا يغيّروا الاسم';

  @override
  String youRenamed(Object name) {
    return 'غيّرت اسم الجروب لـ \"$name\"';
  }

  @override
  String removedFromGroupNotice(Object name) {
    return 'اتشلت من جروب \"$name\"';
  }

  @override
  String byKicked(Object by, Object who) {
    return '$by شال $who من الجروب';
  }

  @override
  String get youBecameAdmin => 'بقيت مدير في الجروب';

  @override
  String becameAdmin(Object name) {
    return '$name بقى مدير';
  }

  @override
  String get youNoLongerAdmin => 'مبقتش مدير في الجروب';

  @override
  String noLongerAdmin(Object name) {
    return '$name مبقاش مدير';
  }

  @override
  String byRenamed(Object by, Object name) {
    return '$by غيّر اسم الجروب لـ \"$name\"';
  }

  @override
  String mentionedYou(Object text) {
    return 'منشن ليك: $text';
  }

  @override
  String reactedOn(Object emoji, Object text) {
    return 'تفاعل بـ $emoji على: \"$text\"';
  }

  @override
  String get aroundYouNow => 'حواليك دلوقتي';

  @override
  String get helpMark => '؟';

  @override
  String get howToPlay => 'إزاي بتتلعب؟';

  @override
  String get games => 'الألعاب';

  @override
  String playWith(String name) {
    return 'العب مع $name';
  }

  @override
  String get playWithGroup => 'العب مع الجروب';

  @override
  String get gamesTabDirect => 'اتنين';

  @override
  String get gamesTabGroup => 'جروب';

  @override
  String playersRange(String range) {
    return '$range لاعبين';
  }

  @override
  String gameInviteFrom(String name, String game) {
    return '$name عازمك على $game';
  }

  @override
  String gameInviteMine(String game) {
    return 'إنت فتحت $game';
  }

  @override
  String get gamePlay => 'العب';

  @override
  String get gameJoin => 'انضم';

  @override
  String get gameJoined => 'إنت جوه';

  @override
  String get gameNotNow => 'مش دلوقتي';

  @override
  String get gameStart => 'ابدأ';

  @override
  String get gameOpen => 'افتح اللعبة';

  @override
  String get gameWatch => 'اتفرج';

  @override
  String gameWaitingHost(String name) {
    return 'مستنيين $name يبدأ';
  }

  @override
  String gameWaitingPeer(String name) {
    return 'مستنيين $name يوافق';
  }

  @override
  String gameSeats(String n, String max) {
    return '$n من $max';
  }

  @override
  String gameNeedMore(String n) {
    return 'محتاجين $n كمان عشان تبدأ';
  }

  @override
  String get gameDoneCard => 'اللعبة خلصت';

  @override
  String get gameClosedCard => 'اللعبة اتقفلت';

  @override
  String get gameEnded => 'اللعبة خلصت';

  @override
  String get gameHostLeft => 'صاحب الغرفة خرج، فاللعبة اتقفلت';

  @override
  String get gameCanceled => 'اللعبة اتلغت';

  @override
  String gameRunningBanner(String game) {
    return 'في لعبة شغالة: $game';
  }

  @override
  String get gameBackToGame => 'ارجع لها';

  @override
  String get gameBackToChat => 'ارجع للشات';

  @override
  String get gameRematch => 'ماتش تاني';

  @override
  String gameRematchAsked(String name) {
    return '$name عايز ماتش تاني';
  }

  @override
  String get gameRematchWaiting => 'مستني التاني يوافق…';

  @override
  String get gameYouWon => 'إنت كسبت!';

  @override
  String get gameYouLost => 'المرة دي لأ… ماتش تاني؟';

  @override
  String gameWinner(String name) {
    return '$name كسب!';
  }

  @override
  String get gameDraw => 'تعادل';

  @override
  String get gameYourTurn => 'دورك';

  @override
  String gameTheirTurn(String name) {
    return 'دور $name';
  }

  @override
  String get gameQuitQ => 'تخرج من اللعبة؟';

  @override
  String get gameQuitBody => 'اللعبة هتكمل للباقيين من غيرك.';

  @override
  String get gameQuitBody2 => 'لو خرجت التاني هيكسب.';

  @override
  String get gameEndQ => 'تقفل اللعبة للكل؟';

  @override
  String get gameEndBody =>
      'إنت صاحب الغرفة: لو خرجت اللعبة هتتقفل عند كل اللاعبين.';

  @override
  String get gameLeave => 'اخرج';

  @override
  String get gameNobody => 'مفيش حد متصل دلوقتي تلعب معاه';

  @override
  String get gameNeedConnection => 'استنى الاتصال يجهز الأول';

  @override
  String gameOldVersion(String name) {
    return 'مفيش رد… يمكن $name عنده نسخة قديمة من وصل';
  }

  @override
  String get gameSpectating => 'إنت بتتفرج';

  @override
  String get gameScore => 'النتيجة';

  @override
  String get gamePlayers => 'اللاعبين';

  @override
  String gameRound(String n) {
    return 'الماتش $n';
  }

  @override
  String get gameChatHint => 'اكتب للاعبين…';

  @override
  String get gameChatMuted => 'مينفعش تتكلم دلوقتي';

  @override
  String gameCheated(String name) {
    return '$name غش! (غيّر اختياره أو كدب في رد)';
  }

  @override
  String get gameHost => 'صاحب الغرفة';

  @override
  String get gameSkip => 'عدّي';

  @override
  String gameTimeLeft(String s) {
    return 'فاضل $s ث';
  }

  @override
  String get gameWins => 'مرات الكسب';

  @override
  String gameVsRecord(String a, String b) {
    return 'بينكم: $a – $b';
  }

  @override
  String get gameMore => 'ألعاب';

  @override
  String get gameXo => 'إكس أو';

  @override
  String get gameConnect4 => 'أربعة في صف';

  @override
  String get gameBattleship => 'حرب السفن';

  @override
  String get gameRps => 'حجر ورقة مقص';

  @override
  String get gameDots => 'مربعات ونقط';

  @override
  String get gameMemory => 'الذاكرة';

  @override
  String get gameSpy => 'مين الجاسوس؟';

  @override
  String get gameQuiz => 'المسابقة';

  @override
  String get gameMafia => 'المافيا';

  @override
  String get tagXo => '3 في صف تكسب';

  @override
  String get tagConnect4 => 'القطعة بتنزل، و4 في صف تكسب';

  @override
  String get tagBattleship => 'خبّي سفنك واضرب سفنه';

  @override
  String get tagRps => 'مين هيغلب مين؟';

  @override
  String get tagDots => 'اقفل المربع وخده';

  @override
  String get tagMemory => 'افتكر مكان الصور';

  @override
  String get tagSpy => 'الكل عارف الكلمة… إلا واحد';

  @override
  String get tagQuiz => 'مين أسرع وأشطر؟';

  @override
  String get tagMafia => 'اكشفوا القتلة قبل ما يخلّصوا عليكم';

  @override
  String get helpGoal => 'الهدف';

  @override
  String get helpHow => 'إزاي بتتلعب';

  @override
  String get helpRoles => 'الأدوار';

  @override
  String get helpTips => 'نصايح';

  @override
  String get helpFaq => 'أسئلة';

  @override
  String get helpWhereDirect => 'في الخاص';

  @override
  String get helpWhereGroup => 'في الجروبات';

  @override
  String helpMinutes(String range) {
    return '$range دقيقة';
  }

  @override
  String get helpFaqLeaveQ => 'لو حد فصل أو خرج؟';

  @override
  String get helpFaqLeaveA =>
      'لو لاعب خرج، اللعبة بتكمل للباقيين ودوره بيتنط. لو صاحب الغرفة (اللي فتح اللعبة) خرج أو بعد أكتر من 25 ثانية، اللعبة بتتقفل عند الكل.';

  @override
  String get helpFaqHostQ => 'مين \"صاحب الغرفة\"؟';

  @override
  String get helpFaqHostA =>
      'اللي فتح اللعبة. موبايله هو الحكم: بيشغّل القواعد، وبيوزّع الأدوار السرية، وبيعدّ الأصوات. بيلعب عادي زي أي حد، والتطبيق مبيوريهوش أسرار حد.';

  @override
  String get helpFaqCheatQ => 'حد يقدر يغش؟';

  @override
  String get helpFaqCheatA =>
      'في حرب السفن وحجر ورقة مقص اختيارك بيتقفل ببصمة قبل ما التاني يشوفه، والتطبيق بيكشف أي حد غيّر اختياره أو كدب. في باقي الألعاب موبايل صاحب الغرفة هو الحكم.';

  @override
  String get helpXoGoal =>
      'أول واحد يعمل 3 علامات في صف (أفقي أو رأسي أو مايل) يكسب.';

  @override
  String get helpXoHow =>
      'اللي بيبدأ بياخد ✕ والتاني ○.\nكل واحد بدوره يدوس على خانة فاضية.\nلو اللوح اتملى ومحدش عمل 3 في صف يبقى تعادل.\nفي الماتش اللي بعده اللي بيبدأ بيتبدّل.';

  @override
  String get helpXoTips =>
      'النص أقوى خانة في الأول.\nلو التاني عنده 2 في صف، اقفل عليه فوراً.';

  @override
  String get helpConnect4Goal => 'أول واحد يعمل 4 قطع من لونه في صف يكسب.';

  @override
  String get helpConnect4How =>
      'اللوح 7 أعمدة و6 صفوف.\nدوس على أي عمود، والقطعة بتنزل لأوطى خانة فاضية فيه.\nالـ 4 ممكن يكونوا أفقي أو رأسي أو مايلين.\nلو اللوح اتملى من غير 4 في صف يبقى تعادل.';

  @override
  String get helpConnect4Tips =>
      'العمود اللي في النص بيفتح لك فرص أكتر.\nبص على الخطوط المايلة؛ ناس كتير بتنساها.';

  @override
  String get helpBattleshipGoal => 'غرّق كل سفن التاني قبل ما يغرّق سفنك.';

  @override
  String get helpBattleshipHow =>
      'كل واحد عنده بحر 8×8 فيه 4 سفن: طولها 4 و3 و3 و2.\nدوس \"رصّة تانية\" لحد ما الرصّة تعجبك، وبعدين \"جاهز\".\nبالدور دوس على خانة في بحر التاني عشان تضرب.\nالرد: مياه ○ أو إصابة ✕ أو غرّقت سفينة.\nلو أصبت بتضرب تاني، ولو جت مياه الدور بيروح.';

  @override
  String get helpBattleshipTips =>
      'لما تصيب، جرّب الخانات اللي جنبها.\nالسفن مبتلمسش بعض، فحوالين السفينة الغرقانة كله مياه.\nسفنك مبتخرجش من موبايلك؛ في الآخر التطبيق بيتأكد إن محدش كدب.';

  @override
  String get helpRpsGoal => 'أول واحد يكسب رميتين يكسب الماتش.';

  @override
  String get helpRpsHow =>
      'اختار حجر ✊ أو ورقة ✋ أو مقص ✌️.\nالحجر بيكسّر المقص، والمقص بيقص الورقة، والورقة بتلف الحجر.\nالاختيارين بيظهروا مع بعض بعد ما الاتنين يختاروا.\nلو اخترتوا نفس الحاجة الرمية بتتعاد.';

  @override
  String get helpRpsTips =>
      'محدش يقدر يشوف اختيارك قبل ما يختار؛ التطبيق بيقفله ببصمة.';

  @override
  String get helpDotsGoal => 'خد أكتر عدد مربعات.';

  @override
  String get helpDotsHow =>
      'بالدور، كل واحد يرسم خط بين نقطتين جنب بعض.\nاللي يرسم الضلع الرابع لمربع ياخده (بيتلوّن بلونه).\nلو قفلت مربع بتلعب تاني على طول.\nلما كل المربعات تتقفل، اللي معاه أكتر واحد يكسب.';

  @override
  String get helpDotsTips =>
      'متدّيش للتاني ضلع تالت في مربع؛ هياخده.\nفي الآخر حاول تسيب للتاني سلسلة قصيرة وتاخد إنت الطويلة.';

  @override
  String get helpMemoryGoal => 'لِم أكتر عدد من الكروت المتشابهة.';

  @override
  String get helpMemoryHow =>
      'الكروت مقلوبة، وكل صورة ليها كارتين.\nفي دورك اقلب كارتين.\nلو شبه بعض بتاخدهم وتلعب تاني.\nلو مش شبه بعض بيتقلبوا تاني بعد لحظة والدور بيروح للي بعدك.\nلما الكروت تخلص، اللي معاه أكتر يكسب.';

  @override
  String get helpMemoryTips =>
      'ركّز في الكروت اللي غيرك بيقلبها؛ دي معلومة ببلاش.';

  @override
  String get helpSpyGoal =>
      'لو إنت مش الجاسوس: اكتشفوه. لو إنت الجاسوس: متتكشفش، أو اعرف الكلمة.';

  @override
  String get helpSpyHow =>
      'التطبيق بيختار فئة (أكلات، أماكن…) وكلمة.\nكل واحد بيشوف الكلمة على موبايله، إلا واحد بيشوف \"إنت الجاسوس\" والفئة بس.\nبالدور كل واحد يقول تلميح صغير عن الكلمة (بصوته أو يكتبه) ويدوس \"خلصت\".\nبعد التلميحات الكل يصوّت على مين الجاسوس.\nلو الجاسوس اتمسك، ياخد فرصة أخيرة يخمّن الكلمة من 8 اختيارات.';

  @override
  String get helpSpyRoles =>
      '🕵️ الجاسوس: مش عارف الكلمة، بيحاول يتصرف كأنه عارف.\n👤 الباقيين: عارفين الكلمة، بيحاولوا يكشفوه من غير ما يفضحوا الكلمة.';

  @override
  String get helpSpyTips =>
      'التلميح لو واضح أوي الجاسوس هيعرف الكلمة، ولو غامض أوي هيشكّوا فيك.\nالجاسوس: اسمع تلميحات اللي قبلك كويس.';

  @override
  String get helpQuizGoal => 'جاوب صح وبسرعة واجمع أكتر نقط.';

  @override
  String get helpQuizHow =>
      'صاحب الغرفة بيختار الفئة وعدد الأسئلة.\nكل سؤال ليه 4 اختيارات و15 ثانية.\nالإجابة الصح بتاخد 500 نقطة، وكمان لحد 500 على السرعة.\nبعد كل سؤال الإجابة الصح والترتيب بيظهروا.';

  @override
  String get helpQuizTips =>
      'الوقت بيتحسب على موبايلك من لحظة ما السؤال يظهر عندك، فبطء الشبكة مش هيظلمك.';

  @override
  String get helpMafiaGoal =>
      'المواطنين: اكشفوا المافيا وطلّعوهم. المافيا: خلّصوا على الباقيين من غير ما تتكشفوا.';

  @override
  String get helpMafiaHow =>
      'التطبيق بيوزّع الأدوار سرّي؛ كل واحد بيشوف دوره بس.\nالليل 🌙: المافيا يختاروا ضحية، والدكتور يحمي حد، والمحقق يسأل عن حد.\nالصبح ☀️: التطبيق يعلن مين اتقتل (أو إن الدكتور أنقذه).\nالنقاش: 3 دقايق تتكلموا وتتهموا بعض (صاحب الغرفة يقدر يختصر الوقت).\nالتصويت: اللي ياخد أكتر أصوات يخرج ودوره يتكشف. لو الأصوات اتعادلت محدش بيخرج.\nوبعدين ليل تاني… لحد ما فريق يكسب.';

  @override
  String get helpMafiaRoles =>
      '🔪 مافيا: واحد لكل 4 لاعبين تقريباً. عارفين بعض، وليهم شات سري بالليل.\n💉 دكتور: كل ليلة يحمي حد (ممكن نفسه)، بس مش نفس الشخص ليلتين ورا بعض.\n🔍 محقق: كل ليلة يعرف عن حد هو مافيا ولا لأ.\n👤 مواطن: ملوش قدرة؛ سلاحه عقله وصوته.';

  @override
  String get helpMafiaTips =>
      'المواطنين بيكسبوا لو كل المافيا خرجوا. المافيا بيكسبوا لو بقى عددهم قد الباقيين.\nاللي مات بيتفرج ومبيتكلمش.\nلو قاعدين مع بعض اتكلموا بصوتكم؛ التطبيق بيمسك الوقت والتصويت بس.';

  @override
  String get rpsRock => 'حجر';

  @override
  String get rpsPaper => 'ورقة';

  @override
  String get rpsScissors => 'مقص';

  @override
  String get rpsPick => 'اختار';

  @override
  String rpsPicked(String name) {
    return 'اخترت ✓ مستني $name';
  }

  @override
  String rpsTheyPicked(String name) {
    return '$name اختار';
  }

  @override
  String rpsFirstTo(String n) {
    return 'أول واحد يوصل $n';
  }

  @override
  String get rpsTie => 'نفس الاختيار، تاني!';

  @override
  String get bsPlace => 'رصّ سفنك';

  @override
  String get bsShuffle => 'رصّة تانية';

  @override
  String get bsReady => 'جاهز';

  @override
  String bsWaitingThem(String name) {
    return 'مستني $name يرصّ سفنه';
  }

  @override
  String get bsYourSea => 'بحرك';

  @override
  String bsTheirSea(String name) {
    return 'بحر $name';
  }

  @override
  String get bsTapToFire => 'دوس على خانة في بحره عشان تضرب';

  @override
  String get bsHit => 'إصابة! اضرب تاني';

  @override
  String get bsMiss => 'مياه';

  @override
  String get bsSunk => 'غرّقت سفينة!';

  @override
  String bsLeft(String n) {
    return 'فاضل $n';
  }

  @override
  String get dotsBoxes => 'مربعات';

  @override
  String get memPairs => 'أزواج';

  @override
  String get spyYouAreSpy => 'إنت الجاسوس';

  @override
  String spyCategory(String cat) {
    return 'الفئة: $cat';
  }

  @override
  String get spyWordIs => 'الكلمة';

  @override
  String get spyTapToShow => 'دوس عشان تشوف (خبّي الشاشة عن اللي جنبك)';

  @override
  String get spyHide => 'خبّي';

  @override
  String spyClueTurn(String name) {
    return 'دور $name يقول تلميح';
  }

  @override
  String get spyYourClue =>
      'دورك: قول تلميح صغير عن الكلمة (بصوتك أو اكتبه تحت)';

  @override
  String get spyDone => 'خلصت تلميحي';

  @override
  String get spyPass => 'عدّي دوره';

  @override
  String get spyToVote => 'يلا نصوّت';

  @override
  String spyClues(String n, String m) {
    return 'تلميح $n من $m';
  }

  @override
  String get spyVoteTitle => 'مين الجاسوس؟';

  @override
  String spyVoted(String n, String m) {
    return 'صوّت $n من $m';
  }

  @override
  String get spyYourVote => 'صوتك راح ✓';

  @override
  String spyGuessing(String name) {
    return '$name اتمسك… وبيخمّن الكلمة';
  }

  @override
  String get spyGuessNow => 'اتمسكت! عندك فرصة أخيرة: خمّن الكلمة';

  @override
  String spyWas(String name) {
    return 'الجاسوس كان $name';
  }

  @override
  String spyWordWas(String w) {
    return 'الكلمة كانت: $w';
  }

  @override
  String spyGuessed(String w) {
    return 'خمّن \"$w\"';
  }

  @override
  String get spyNotCaught => 'محدش مسك الجاسوس';

  @override
  String spyWrongCaught(String name) {
    return 'اتمسك $name… بس مكانش الجاسوس';
  }

  @override
  String get quizCategory => 'الفئة';

  @override
  String get quizMixed => 'منوّعة';

  @override
  String get quizCount => 'عدد الأسئلة';

  @override
  String quizQuestionOf(String i, String n) {
    return 'سؤال $i من $n';
  }

  @override
  String quizAnswered(String n, String m) {
    return 'جاوب $n من $m';
  }

  @override
  String quizRight(String n) {
    return 'صح! +$n';
  }

  @override
  String get quizWrong => 'غلط';

  @override
  String get quizTooLate => 'الوقت خلص';

  @override
  String get quizRanking => 'الترتيب';

  @override
  String quizPoints(String n) {
    return '$n نقطة';
  }

  @override
  String get mafiaRoleMafia => 'مافيا';

  @override
  String get mafiaRoleDoctor => 'دكتور';

  @override
  String get mafiaRoleDetective => 'محقق';

  @override
  String get mafiaRoleCitizen => 'مواطن';

  @override
  String get mafiaYourRole => 'شخصيتك السرية';

  @override
  String mafiaTeam(String names) {
    return 'فريقك: $names';
  }

  @override
  String mafiaNight(String n) {
    return 'الليل $n 🌙';
  }

  @override
  String get mafiaMorning => 'الصبح ☀️';

  @override
  String get mafiaTalk => 'النقاش';

  @override
  String get mafiaVote => 'التصويت';

  @override
  String get mafiaNightWait => 'الليل… غمّض واستنى الصبح';

  @override
  String get mafiaPickKill => 'اختار الضحية';

  @override
  String get mafiaPickSave => 'اختار حد تحميه الليلة';

  @override
  String get mafiaPickCheck => 'اختار حد تسأل عنه';

  @override
  String mafiaPicked(String name) {
    return 'اخترت $name ✓';
  }

  @override
  String mafiaKilled(String name) {
    return '$name اتقتل الليلة اللي فاتت';
  }

  @override
  String get mafiaRescued => 'المافيا حاولوا… بس الدكتور أنقذ الضحية!';

  @override
  String get mafiaQuietNight => 'ليلة هادية، محدش مات';

  @override
  String mafiaOut(String name, String role) {
    return '$name خرج… وكان $role';
  }

  @override
  String get mafiaNoOut => 'الأصوات اتعادلت، محدش خرج';

  @override
  String get mafiaVoteNone => 'محدش';

  @override
  String get mafiaTownWins => 'المواطنين كسبوا!';

  @override
  String get mafiaMafiaWins => 'المافيا كسبت!';

  @override
  String get mafiaYouDied => 'إنت مت… بتتفرج دلوقتي';

  @override
  String mafiaIsMafia(String name) {
    return '$name مافيا!';
  }

  @override
  String mafiaNotMafia(String name) {
    return '$name مش مافيا';
  }

  @override
  String get mafiaSecretChat => 'شات المافيا السري';

  @override
  String get mafiaSkip => 'اختصر الوقت';

  @override
  String mafiaAlive(String n) {
    return 'عايشين $n';
  }

  @override
  String mafiaVotedCount(String n, String m) {
    return 'صوّت $n من $m';
  }

  @override
  String get mafiaNoSameTwice => 'مينفعش تحمي نفس الشخص ليلتين ورا بعض';

  @override
  String get spyYourCard => 'كلمتك';

  @override
  String get guideTitle => 'دليل وصل';

  @override
  String get guideSub => 'الاتصال، الجروبات، الألعاب والأمان';

  @override
  String get guideHelp => 'شرح طرق الاتصال';

  @override
  String get guideJumpConnect => 'الاتصال';

  @override
  String get guideJumpGroups => 'الجروبات';

  @override
  String get guideJumpGames => 'الألعاب';

  @override
  String get guideJumpSafety => 'الأمان';

  @override
  String get guideConnectTitle => 'طرق الاتصال';

  @override
  String get guideConnectIntro =>
      'وصل مبيحتاجش إنترنت ولا شريحة ولا حساب. اختار الطريقة على حسب المكان اللي إنت فيه:';

  @override
  String get guideWhat => 'إيه هو';

  @override
  String get guideWhen => 'إمتى تستخدمه';

  @override
  String get guideFacts => 'تعرف إيه';

  @override
  String get guideHow => 'تبدأ إزاي';

  @override
  String get guideBtWhat =>
      'الموبايلات بتكلم بعض بالبلوتوث مباشرة، من غير أي شبكة خالص.';

  @override
  String get guideBtWhen =>
      'لما مفيش واي فاي ولا هوت سبوت: في الشارع، في رحلة، أو لما الشبكة واقعة.';

  @override
  String get guideBtFacts =>
      'المدى حوالي 10 لـ 30 متر بين كل موبايلين.\nكل موبايل بيتوصل بحوالي 5، والرسالة بتنط من موبايل للتاني لحد 6 مرات، فبتوصل لأبعد بكتير.\nرسايل وصور وملفات وفويس. الفيديو والمكالمات لأ (البلوتوث بطيء عليهم).';

  @override
  String get guideBtHow =>
      'دوس \"بلوتوث\" في أول صفحة.\nوافق على الأذونات (البلوتوث والأجهزة القريبة).\nاللي حواليك فاتحين وصل هيظهروا في \"القريبين\" لوحدهم.';

  @override
  String get guideWifiWhat =>
      'الموبايلات على نفس الواي فاي، أو واحد فاتح هوت سبوت والباقيين داخلين عليه. الشبكة دي مش لازم يكون فيها إنترنت.';

  @override
  String get guideWifiWhen =>
      'لما تكونوا في نفس البيت أو القاعة أو الكافيه، أو لما حد يقدر يفتح هوت سبوت.';

  @override
  String get guideWifiFacts =>
      'أسرع بكتير من البلوتوث، وفيه فيديو ومكالمات صوت وصورة.\nالهوت سبوت بيشيل عادةً من 5 لـ 10 موبايلات.\nبعض الراوترات العامة بتمنع الأجهزة تكلم بعض؛ ساعتها استخدم هوت سبوت.';

  @override
  String get guideWifiHow =>
      'اتوصل بالواي فاي، أو افتح هوت سبوت من إعدادات الموبايل وخلّي صحابك يدخلوا عليه.\nدوس \"واي فاي\" في وصل.\nاللي على نفس الشبكة هيظهروا لوحدهم.';

  @override
  String get guideBothWhat =>
      'البلوتوث والواي فاي مع بعض: موبايلك بيبقى كوبري بين اللي على الواي فاي واللي على البلوتوث.';

  @override
  String get guideBothWhen =>
      'لما الناس متفرقين: شوية على هوت سبوت، وشوية بعيد مفيش معاهم غير البلوتوث. أو عشان توصّل هوت سبوتين ببعض.';

  @override
  String get guideBothFacts =>
      'الشبكة بتكبر: كل موبايل على \"الاتنين\" بيربط الشبكتين ببعض.\nالمكالمات والفيديو بيفضلوا جوه نفس الواي فاي.\nبيصرف بطارية أكتر شوية.';

  @override
  String get guideBothHow =>
      'اتوصل بواي فاي أو هوت سبوت.\nدوس \"الاتنين مع بعض\".\nوصل هيوصّل الكل ببعض لوحده.';

  @override
  String get guideMeshHops =>
      'الرسالة بتعدّي على 6 موبايلات بالكتير، والموبايلات اللي في النص بتوصّل بس ومبتقدرش تقرا الشات الخاص.';

  @override
  String get guideGroupsTitle => 'الجروبات';

  @override
  String get guideGamesTitle => 'الألعاب';

  @override
  String get guideGamesBody =>
      'في أي شات دوس 🎮 واختار لعبة. في الخاص صاحبك بيوافق واللعبة تبدأ، وفي الجروب اللي عايز يلعب يدوس \"انضم\" واللي فتح اللعبة يدوس \"ابدأ\". دوس على أي لعبة تحت عشان تعرف بتتلعب إزاي.';

  @override
  String get guideSafetyTitle => 'الأمان والخصوصية';
}
