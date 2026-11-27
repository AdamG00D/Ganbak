import 'dart:convert';

import 'share_server.dart';

/// صفحة التحميل اللي بتفتح على الموبايل اللي مفيهوش جنبك (من غير إنترنت: كل حاجة جوه الصفحة — مفيش خطوط
/// ولا صور من برا). بهوية التطبيق: حبر الليل والزعفران ونقشة الخيامية.
class SharePage {
  SharePage._();

  static const _t = {
    'ar': {
      'title': 'حمّل جنبك',
      'tag': 'شات مشفّر من غير إنترنت ولا سيرفر — بالبلوتوث والواي فاي.',
      'download': 'حمّل التطبيق',
      'meta': 'الإصدار {v} • {s} ميجا • أندرويد 7 أو أحدث',
      'how': 'تثبّته إزاي',
      's1': 'دوس «حمّل التطبيق» واستنى لحد ما التحميل يخلص.',
      's2': 'افتح الملف من الإشعار أو من «التنزيلات».',
      's3': 'لو الموبايل قال إن التثبيت من المصدر ده مش مسموح: دوس «الإعدادات» وفعّل «السماح من المصدر ده»، وارجع دوس «تثبيت».',
      's4': 'افتح جنبك واختار «الواي فاي» أو «الاتنين مع بعض» عشان تلاقي اللي بعتهولك.',
      'from': 'الملف جاي من موبايل صاحبك على طول، مش من الإنترنت. عاوز تتأكد إنه هو؟ قارن البصمة دي باللي ظاهرة على شاشته:',
      'compat': 'لو الموبايل قال إن التطبيق «مش متوافق»، الموبايل ده محتاج النسخة الشاملة (universal) من صفحة جنبك على GitHub لما يبقى فيه نت.',
      'split': 'النسخة اللي على موبايل صاحبك متثبتة من متجر على أجزاء ومينفعش تتبعت كده. حمّل جنبك من صفحته على GitHub لما يبقى فيه نت.',
      'other': 'English',
      'otherLang': 'en',
    },
    'en': {
      'title': 'Get Ganbak',
      'tag': 'Encrypted chat with no internet and no server — over Bluetooth and Wi-Fi.',
      'download': 'Download the app',
      'meta': 'Version {v} • {s} MB • Android 7 or newer',
      'how': 'How to install it',
      's1': 'Tap “Download the app” and wait until it finishes.',
      's2': 'Open the file from the notification or from “Downloads”.',
      's3': 'If the phone says installs from this source aren’t allowed: tap “Settings”, turn on “Allow from this source”, go back and tap “Install”.',
      's4': 'Open Ganbak and pick “Wi-Fi” or “Both” to find whoever shared it with you.',
      'from': 'The file comes straight from your friend’s phone, not from the internet. Want to be sure it’s the same? Compare this fingerprint with the one on their screen:',
      'compat': 'If the phone says the app is “not compatible”, it needs the universal build from Ganbak’s GitHub page once you have internet.',
      'split': 'Your friend’s copy was installed from a store in several parts and can’t be shared this way. Get Ganbak from its GitHub page once you have internet.',
      'other': 'العربية',
      'otherLang': 'ar',
    },
  };

  static String _e(String s) => const HtmlEscape().convert(s);

  /// البصمة على شكل مجموعات من 4 (أسهل في المقارنة).
  static String groups(String hex) {
    final b = StringBuffer();
    for (var i = 0; i < hex.length; i += 4) {
      if (i > 0) b.write(' ');
      b.write(hex.substring(i, i + 4 > hex.length ? hex.length : i + 4));
    }
    return b.toString();
  }

  // لوجو التطبيق: تلات نقط متوصلة على حبر الليل (زي الأيقونة)
  static const _logo = '<svg viewBox="0 0 1024 1024" width="84" height="84" aria-hidden="true">'
      '<rect x="8" y="8" width="1008" height="1008" rx="230" fill="#262B55" stroke="#F4B400" stroke-opacity=".5" stroke-width="16"/>'
      '<rect x="214" y="234" width="596" height="420" rx="140" fill="none" stroke="#F4B400" stroke-width="14" '
      'stroke-dasharray="44 30" opacity=".55"/>'
      '<path d="M352 508 L512 372 L672 508" fill="none" stroke="#F4B400" stroke-width="34" stroke-linecap="round"/>'
      '<circle cx="352" cy="508" r="54" fill="#F4B400"/><circle cx="512" cy="372" r="54" fill="#F4B400"/>'
      '<circle cx="672" cy="508" r="54" fill="#F4B400"/>'
      '<path d="M420 654 L380 760 L500 654" fill="#F4B400" opacity=".85"/></svg>';

  // نقشة الخيامية (نجمة تمانية) كخلفية للرأس
  static final _pattern = 'data:image/svg+xml;base64,${base64.encode(utf8.encode(
        '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
        '<g fill="none" stroke="#F4B400" stroke-opacity=".16" stroke-width="2">'
        '<rect x="17" y="17" width="30" height="30"/><rect x="17" y="17" width="30" height="30" transform="rotate(45 32 32)"/>'
        '</g><circle cx="32" cy="32" r="3" fill="#F4B400" fill-opacity=".16"/></svg>',
      ))}';

  static String html({required String lang, required ApkInfo apk, required String version}) {
    final t = _t[lang] ?? _t['en']!;
    final ar = lang == 'ar';
    final mb = (apk.size / (1024 * 1024)).toStringAsFixed(1);
    final meta = t['meta']!.replaceAll('{v}', version).replaceAll('{s}', mb);
    final main = apk.split
        ? '<p class="warn">${_e(t['split']!)}</p>'
        : '''
<a class="btn" href="/wasl.apk" download>
  <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" d="M12 3a1 1 0 0 1 1 1v9.6l3.3-3.3a1 1 0 1 1 1.4 1.4l-5 5a1 1 0 0 1-1.4 0l-5-5a1 1 0 1 1 1.4-1.4l3.3 3.3V4a1 1 0 0 1 1-1zM5 19h14a1 1 0 1 1 0 2H5a1 1 0 1 1 0-2z"/></svg>
  ${_e(t['download']!)}
</a>
<p class="meta">${_e(meta)}</p>''';
    final steps = [for (final k in ['s1', 's2', 's3', 's4']) '<li>${_e(t[k]!)}</li>'].join('\n');
    return '''<!doctype html>
<html lang="$lang" dir="${ar ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>${_e(t['title']!)}</title>
<style>
:root{--ink:#1B1F3B;--saffron:#F4B400;--saffron-ink:#8F5E00;--bg:#FBF6EC;--card:#FFFFFF;--text:#1B1F3B;--muted:#5B5F7A;--line:#EADFC8}
@media (prefers-color-scheme:dark){:root{--bg:#0F1226;--card:#1A1E3A;--text:#F3EEE2;--muted:#A9ACC4;--line:#2C3157;--saffron-ink:#F6BE2C}}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--text);
 font-family:${ar ? '"IBM Plex Sans Arabic","Noto Sans Arabic","Noto Naskh Arabic",' : ''}system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;line-height:1.65}
header{background:var(--ink) url("$_pattern");color:#fff;text-align:center;padding:36px 16px 64px;border-bottom:4px dashed rgba(244,180,0,.5)}
header h1{margin:14px 0 4px;font-size:30px;letter-spacing:.5px}
header p{margin:0 auto;max-width:440px;color:#D8D9E6;font-size:15px}
main{max-width:520px;margin:-40px auto 0;padding:0 16px 40px}
.card{background:var(--card);border:1px solid var(--line);border-radius:22px;padding:22px 18px;margin-bottom:16px;box-shadow:0 6px 24px rgba(27,31,59,.08)}
.btn{display:flex;align-items:center;justify-content:center;gap:10px;background:var(--saffron);color:var(--ink);
 text-decoration:none;font-weight:700;font-size:19px;padding:16px;border-radius:16px}
.btn:active{transform:scale(.98)}
.meta{text-align:center;color:var(--muted);font-size:13.5px;margin:10px 0 0}
h2{font-size:17px;margin:0 0 10px;color:var(--saffron-ink)}
ol{margin:0;padding-inline-start:0;list-style:none;counter-reset:s}
ol li{counter-increment:s;position:relative;padding-inline-start:40px;margin:0 0 12px;font-size:15px}
ol li::before{content:counter(s);position:absolute;inset-inline-start:0;top:0;width:28px;height:28px;border-radius:50%;
 background:var(--ink);color:var(--saffron);font-weight:700;display:flex;align-items:center;justify-content:center;font-size:14px}
.small{color:var(--muted);font-size:13.5px;margin:0 0 10px}
.fp{direction:ltr;text-align:center;font-family:ui-monospace,"Roboto Mono",monospace;font-size:13px;word-spacing:4px;
 background:var(--bg);border:1px dashed var(--line);border-radius:12px;padding:10px;color:var(--text)}
.warn{background:#FFF1D6;color:#6B4400;border-radius:14px;padding:14px;margin:0}
footer{text-align:center;font-size:14px}
footer a{color:var(--saffron-ink);font-weight:700}
</style>
</head>
<body>
<header>
$_logo
<h1>${_e(t['title']!)}</h1>
<p>${_e(t['tag']!)}</p>
</header>
<main>
<div class="card">
$main
</div>
<div class="card">
<h2>${_e(t['how']!)}</h2>
<ol>
$steps
</ol>
</div>
<div class="card">
<p class="small">${_e(t['from']!)}</p>
<div class="fp">${_e(groups(apk.sha256))}</div>
<p class="small" style="margin:12px 0 0">${_e(t['compat']!)}</p>
</div>
<footer><a href="/?l=${t['otherLang']}">${_e(t['other']!)}</a></footer>
</main>
</body>
</html>''';
  }
}
