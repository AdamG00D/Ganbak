/// مقارنة الأسامي: "آمال" و"امال" و"Amal" بحرف روسي شبهه… كلهم نفس الاسم عند التحذير.
class NameMatch {
  NameMatch._();

  // حروف شبه بعض في الشكل (روسي/يوناني → إنجليزي)
  static const _lookalike = {
    'а': 'a', 'в': 'b', 'е': 'e', 'к': 'k', 'м': 'm', 'н': 'h', 'о': 'o', 'р': 'p', 'с': 'c', 'т': 't', 'у': 'y',
    'х': 'x', 'і': 'i', 'ј': 'j', 'ѕ': 's', 'ԁ': 'd', 'ɡ': 'g', 'α': 'a', 'ο': 'o', 'ρ': 'p', 'ν': 'v', 'τ': 't',
    'ι': 'i', 'κ': 'k', '0': 'o', '1': 'l',
  };

  /// شكل الاسم للمقارنة بس (مش للعرض).
  static String key(String name) {
    var s = name.toLowerCase();
    // تشكيل + تطويل + حروف مخفية واتجاه + مسافات وعلامات
    s = s.replaceAll(RegExp('[\u064B-\u065F\u0670\u0640\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'), '');
    s = s.replaceAll(RegExp(r'[\s\p{P}\p{S}_]', unicode: true), '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('گ', 'ك')
        .replaceAll('ک', 'ك')
        .replaceAll('ی', 'ي');
    final b = StringBuffer();
    for (final ch in s.split('')) {
      b.write(_lookalike[ch] ?? ch);
    }
    return b.toString();
  }

  static bool same(String a, String b) {
    final ka = key(a);
    return ka.isNotEmpty && ka == key(b);
  }
}
