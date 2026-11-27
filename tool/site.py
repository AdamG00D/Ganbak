#!/usr/bin/env python3
"""يبني موقع وصل (GitHub Pages) في site/ — عربي (الأساسي) وإنجليزي، بهوية الخيامية.

python3 tool/site.py   ← بعد أي تغيير في الكلام أو الصور. الموقع بيتنشر لوحده من .github/workflows/pages.yml.
"""
import html
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / 'site'
BASE = 'https://adamg00d.github.io/Wasl/'
REPO = 'https://github.com/AdamG00D/Wasl'
DOWNLOAD = REPO + '/releases/latest'
SHOTS = ['chats', 'group-chat', 'nearby', 'games', 'game-mafia', 'guide']

T = {
    'ar': {
        'dir': 'rtl', 'path': '', 'other': 'en/', 'otherName': 'English',
        'title': 'وَصْل (Wasl) — شات مشفّر من غير إنترنت ولا سيرفر لأندرويد',
        'desc': 'وصل تطبيق شات لأندرويد بيشتغل من غير إنترنت ولا سيرفر: الموبايلات القريبة بتكلم بعض بالبلوتوث والواي فاي وبتوصّل الرسايل لبعض كشبكة Mesh. شات خاص مشفّر، جروبات، ألعاب، وشبكة واي فاي من موبايلك. مجاني ومفتوح المصدر.',
        'hero': 'اتكلم مع اللي حواليك<br>من غير إنترنت',
        'heroSub': 'وصل بيخلّي الموبايلات القريبة تكلم بعض بالبلوتوث والواي فاي، وتوصّل الرسايل لبعض كشبكة — من غير نت، ولا سيرفر، ولا حساب.',
        'download': 'حمّل وصل لأندرويد', 'source': 'الكود على GitHub',
        'meta': 'مجاني • مفتوح المصدر (GPL-3.0) • أندرويد 7 أو أحدث',
        'featTitle': 'ليه وصل؟',
        'feats': [
            ('📡', 'من غير إنترنت', 'بلوتوث، أو واي فاي / هوت سبوت، أو الاتنين مع بعض — وموبايلك يبقى كوبري بينهم.'),
            ('🕸️', 'الرسايل بتعدّي', 'كل موبايل بيوصّل للي بعده (لحد 6 موبايلات)، فالرسالة توصل أبعد بكتير من مدى موبايلك.'),
            ('🔒', 'شات خاص متشفّر', 'تشفير من طرف لطرف لوحده، واللي في النص مبيقدروش يقروا حاجة. ورمز أمان تتأكدوا بيه من بعض.'),
            ('✍️', 'محدش يتكلم باسمك', 'اسمك ورسايلك متوقّعة بمفتاحك، ووصل بيحذّرك لو حد ظهر باسم واحد تعرفه بس مش هو.'),
            ('📶', 'شبكة وصل', 'مفيش راوتر؟ موبايلك يعمل واي فاي لوحده واللي جنبك يدخلوه بضغطة أو بكود QR.'),
            ('⏳', 'الرسالة تستنى صاحبها', 'لو اللي بتكلمه مش موجود، الموبايلات اللي حواليك بتشيل رسالتك مقفولة لحد ما يظهر.'),
            ('🆘', 'استغاثة', 'اطلب مساعدة من كل اللي فاتحين وصل حواليك بضغطة واحدة.'),
            ('🎮', 'ألعاب جوه الشات', 'إكس أو، حرب السفن، الذاكرة، مين الجاسوس؟، المسابقة، المافيا وغيرهم.'),
            ('👥', 'جروبات', 'عامة، أو بكلمة سر، أو بطلب انضمام — بصاحب ومشرفين.'),
        ],
        'whenTitle': 'إمتى تحتاجه؟',
        'when': 'لما الشبكة تقع أو تبقى زحمة: الحفلات والمظاهرات والملاعب، الرحلات والصحرا، الجامعات، وانقطاع الكهربا والطوارئ.',
        'shotsTitle': 'شكله',
        'shareTitle': 'صاحبك مفيهوش وصل؟',
        'share': 'من الإعدادات ← "شارك وصل": موبايلك يفتح شبكة، وصاحبك يصوّر كودين ويحمّل التطبيق من موبايلك على طول — من غير نت.',
        'faqTitle': 'أسئلة شائعة',
        'faq': [
            ('وصل محتاج إنترنت؟', 'لأ. وصل بيشتغل بالبلوتوث والواي فاي بين الموبايلات القريبة، من غير إنترنت ولا باقة ولا سيرفر.'),
            ('إزاي أكلم حد بعيد عني؟', 'الرسايل بتعدّي على موبايلات تانية فاتحة وصل (لحد 6). وكمان لو هو مش موجود دلوقتي، رسالتك بتستنى وتوصله أول ما يظهر.'),
            ('الشات متشفّر؟', 'الشات الخاص متشفّر من طرف لطرف تلقائياً. التفاصيل والحدود المعروفة مكتوبة بصراحة في صفحة الأمان على GitHub.'),
            ('وصل مجاني؟', 'أيوه، مجاني ومفتوح المصدر (GPL-3.0)، مفيهوش إعلانات ولا تحليلات.'),
            ('بيشتغل على أنهي موبايلات؟', 'أندرويد 7 أو أحدث. شبكة وصل محتاجة أندرويد 8+، والدخول منها من جوه التطبيق أندرويد 10+.'),
        ],
        'foot': 'وَصْل — مفتوح المصدر تحت رخصة GPL-3.0',
        'shotAlt': {'chats': 'المحادثات', 'group-chat': 'شات جروب', 'nearby': 'القريبين', 'games': 'الألعاب', 'game-mafia': 'المافيا', 'guide': 'دليل وصل'},
    },
    'en': {
        'dir': 'ltr', 'path': 'en/', 'other': '../', 'otherName': 'العربية',
        'title': 'Wasl (وَصْل) — offline encrypted chat for Android, no internet, no server',
        'desc': 'Wasl is an offline chat app for Android: phones nearby talk over Bluetooth and Wi-Fi and relay messages as a mesh, with no internet and no server. End-to-end encrypted private chats, groups, games and your own Wi-Fi network. Free and open source.',
        'hero': 'Talk to people around you<br>with no internet',
        'heroSub': 'Wasl lets nearby phones talk over Bluetooth and Wi-Fi and relay messages for each other as a mesh — no internet, no server, no account.',
        'download': 'Get Wasl for Android', 'source': 'Source on GitHub',
        'meta': 'Free • Open source (GPL-3.0) • Android 7+',
        'featTitle': 'Why Wasl?',
        'feats': [
            ('📡', 'No internet needed', 'Bluetooth, Wi-Fi / hotspot, or both at once — your phone becomes a bridge between them.'),
            ('🕸️', 'Messages hop', 'Every phone relays to the next (up to 6), so a message reaches far beyond your own range.'),
            ('🔒', 'Encrypted private chats', 'End-to-end encryption by default; relays can’t read anything. Safety codes to verify each other.'),
            ('✍️', 'Nobody speaks for you', 'Your name and messages are signed with your key, and Wasl warns you when someone shows up with a name you know but isn’t them.'),
            ('📶', 'Wasl network', 'No router? Your phone makes its own Wi-Fi and people nearby join with one tap or a QR code.'),
            ('⏳', 'Messages wait', 'If the person isn’t around, phones nearby carry your sealed message until they show up.'),
            ('🆘', 'SOS', 'Ask everyone running Wasl around you for help with one tap.'),
            ('🎮', 'Games in chats', 'Tic-tac-toe, battleships, memory, who’s the spy?, quiz, mafia and more.'),
            ('👥', 'Groups', 'Open, password or join-request groups with an owner and admins.'),
        ],
        'whenTitle': 'When do you need it?',
        'when': 'When the network is down or overloaded: festivals, protests, stadiums, trips and deserts, campuses, power cuts and emergencies.',
        'shotsTitle': 'What it looks like',
        'shareTitle': 'Your friend doesn’t have it?',
        'share': 'Settings → “Share Wasl”: your phone opens a network, your friend scans two codes and downloads the app straight from your phone — no internet.',
        'faqTitle': 'FAQ',
        'faq': [
            ('Does Wasl need the internet?', 'No. It works over Bluetooth and Wi-Fi between nearby phones, with no internet, no data plan and no server.'),
            ('How do I reach someone far away?', 'Messages hop through other phones running Wasl (up to 6). And if they’re not around right now, your message waits and reaches them when they show up.'),
            ('Is it encrypted?', 'Private chats are end-to-end encrypted automatically. Details and known limits are written plainly in the security page on GitHub.'),
            ('Is Wasl free?', 'Yes — free and open source (GPL-3.0), with no ads and no analytics.'),
            ('Which phones?', 'Android 7 or newer. Starting a Wasl network needs Android 8+, joining one from inside the app Android 10+.'),
        ],
        'foot': 'Wasl — open source under GPL-3.0',
        'shotAlt': {'chats': 'Chats', 'group-chat': 'Group chat', 'nearby': 'Nearby', 'games': 'Games', 'game-mafia': 'Mafia', 'guide': 'Wasl guide'},
    },
}

LOGO = ('<svg viewBox="0 0 1024 1024" width="{s}" height="{s}" aria-hidden="true">'
        '<rect x="8" y="8" width="1008" height="1008" rx="230" fill="#262B55" stroke="#F4B400" stroke-opacity=".5" stroke-width="16"/>'
        '<rect x="214" y="234" width="596" height="420" rx="140" fill="none" stroke="#F4B400" stroke-width="14" stroke-dasharray="44 30" opacity=".55"/>'
        '<path d="M352 508 L512 372 L672 508" fill="none" stroke="#F4B400" stroke-width="34" stroke-linecap="round"/>'
        '<circle cx="352" cy="508" r="54" fill="#F4B400"/><circle cx="512" cy="372" r="54" fill="#F4B400"/>'
        '<circle cx="672" cy="508" r="54" fill="#F4B400"/><path d="M420 654 L380 760 L500 654" fill="#F4B400" opacity=".85"/></svg>')


def page(lang: str) -> str:
    t = T[lang]
    e = html.escape
    up = '../' if t['path'] else ''
    url = BASE + t['path']
    ld = {
        '@context': 'https://schema.org', '@type': 'SoftwareApplication',
        'name': 'Wasl', 'alternateName': 'وَصْل', 'operatingSystem': 'Android 7.0+',
        'applicationCategory': 'CommunicationApplication', 'description': t['desc'],
        'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD'},
        'downloadUrl': DOWNLOAD, 'license': 'https://www.gnu.org/licenses/gpl-3.0.html',
        'url': url, 'image': BASE + 'img/banner.en.png', 'codeRepository': REPO, 'inLanguage': ['ar', 'en'],
    }
    faq_ld = {
        '@context': 'https://schema.org', '@type': 'FAQPage',
        'mainEntity': [{'@type': 'Question', 'name': q, 'acceptedAnswer': {'@type': 'Answer', 'text': a}} for q, a in t['faq']],
    }
    feats = '\n'.join(
        f'<div class="feat"><div class="ic">{i}</div><h3>{e(h)}</h3><p>{e(p)}</p></div>' for i, h, p in t['feats'])
    shots = '\n'.join(
        f'<img src="{up}img/{lang}/{s}.png" alt="{e(t["shotAlt"][s])}" width="270" height="570" loading="lazy">' for s in SHOTS)
    faq = '\n'.join(f'<details><summary>{e(q)}</summary><p>{e(a)}</p></details>' for q, a in t['faq'])
    dl_icon = ('<svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" d="M12 3a1 1 0 0 1 1 1v9.6'
               'l3.3-3.3a1 1 0 1 1 1.4 1.4l-5 5a1 1 0 0 1-1.4 0l-5-5a1 1 0 1 1 1.4-1.4l3.3 3.3V4a1 1 0 0 1 1-1zM5 19h14a1 1 0 1 1 0 2H5a1 1 0 1 1 0-2z"/></svg>')
    return f'''<!doctype html>
<html lang="{lang}" dir="{t['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(t['title'])}</title>
<meta name="description" content="{e(t['desc'])}">
<link rel="canonical" href="{url}">
<link rel="alternate" hreflang="ar" href="{BASE}">
<link rel="alternate" hreflang="en" href="{BASE}en/">
<link rel="alternate" hreflang="x-default" href="{BASE}">
<meta property="og:type" content="website">
<meta property="og:title" content="{e(t['title'])}">
<meta property="og:description" content="{e(t['desc'])}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{BASE}img/banner.{lang}.png">
<meta property="og:locale" content="{'ar_EG' if lang == 'ar' else 'en_US'}">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#1B1F3B">
<link rel="icon" href="{up}img/icon.png" type="image/png">
<link rel="apple-touch-icon" href="{up}img/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{up}style.css">
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>
<script type="application/ld+json">{json.dumps(faq_ld, ensure_ascii=False)}</script>
</head>
<body>
<header class="hero">
<nav><a class="brand" href="{up or './'}">{LOGO.format(s=36)}<span>{'وَصْل' if lang == 'ar' else 'Wasl'}</span></a>
<a class="lang" href="{t['other']}" hreflang="{'en' if lang == 'ar' else 'ar'}">{t['otherName']}</a></nav>
<div class="hero-in">
{LOGO.format(s=96)}
<h1>{t['hero']}</h1>
<p>{e(t['heroSub'])}</p>
<div class="cta"><a class="btn" href="{DOWNLOAD}">{dl_icon}{e(t['download'])}</a>
<a class="btn ghost" href="{REPO}">{e(t['source'])}</a></div>
<p class="meta">{e(t['meta'])}</p>
</div>
</header>
<main>
<section><h2>{e(t['featTitle'])}</h2><div class="grid">
{feats}
</div></section>
<section class="band"><h2>{e(t['whenTitle'])}</h2><p>{e(t['when'])}</p></section>
<section><h2>{e(t['shotsTitle'])}</h2><div class="shots">
{shots}
</div></section>
<section class="band"><h2>{e(t['shareTitle'])}</h2><p>{e(t['share'])}</p></section>
<section><h2>{e(t['faqTitle'])}</h2><div class="faq">
{faq}
</div></section>
</main>
<footer><p>{e(t['foot'])} • <a href="{REPO}">GitHub</a> • <a href="{REPO}/blob/main/SECURITY{'.ar' if lang == 'ar' else ''}.md">{'الأمان' if lang == 'ar' else 'Security'}</a></p></footer>
</body>
</html>
'''


CSS = '''
:root{--ink:#1B1F3B;--ink2:#262B55;--saffron:#F4B400;--saffron-ink:#8F5E00;--bg:#FBF6EC;--card:#fff;--text:#1B1F3B;--muted:#5B5F7A;--line:#EADFC8;--teal:#0F8B8D}
@media (prefers-color-scheme:dark){:root{--bg:#0F1226;--card:#1A1E3A;--text:#F3EEE2;--muted:#A9ACC4;--line:#2C3157;--saffron-ink:#F6BE2C}}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--text);font-family:"IBM Plex Sans Arabic",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;line-height:1.7}
a{color:inherit}
.hero{background:var(--ink) url("img/pattern.svg");color:#fff;padding:0 16px 56px;border-bottom:4px dashed rgba(244,180,0,.5)}
nav{max-width:1040px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;padding:14px 0}
.brand{display:flex;align-items:center;gap:10px;text-decoration:none;font-weight:700;font-size:20px}
.lang{color:var(--saffron);font-weight:700;text-decoration:none;border:1px solid rgba(244,180,0,.5);padding:4px 12px;border-radius:999px}
.hero-in{max-width:760px;margin:20px auto 0;text-align:center}
.hero h1{font-size:clamp(30px,6vw,48px);line-height:1.3;margin:16px 0 12px}
.hero p{color:#D8D9E6;font-size:18px;margin:0 auto;max-width:620px}
.cta{display:flex;flex-wrap:wrap;gap:12px;justify-content:center;margin-top:26px}
.btn{display:inline-flex;align-items:center;gap:10px;background:var(--saffron);color:var(--ink);font-weight:700;font-size:18px;padding:14px 22px;border-radius:16px;text-decoration:none}
.btn.ghost{background:transparent;color:#fff;border:1.5px solid rgba(255,255,255,.4)}
.hero .meta{font-size:14px;color:#B9BBD0;margin-top:14px}
main{max-width:1040px;margin:0 auto;padding:0 16px}
section{padding:48px 0 8px}
h2{font-size:28px;margin:0 0 18px;color:var(--saffron-ink);text-align:center}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px}
.feat{background:var(--card);border:1px solid var(--line);border-radius:20px;padding:18px}
.feat .ic{font-size:28px}
.feat h3{margin:6px 0 4px;font-size:18px}
.feat p{margin:0;color:var(--muted);font-size:15px}
.band{background:var(--card);border:1px dashed var(--line);border-radius:22px;padding:26px 20px;margin-top:40px;text-align:center}
.band p{max-width:680px;margin:0 auto;font-size:17px}
.shots{display:flex;gap:14px;overflow-x:auto;padding:4px 2px 14px;scroll-snap-type:x mandatory}
.shots img{flex:0 0 auto;width:210px;height:auto;border-radius:22px;border:1px solid var(--line);scroll-snap-align:center;background:var(--card)}
.faq{max-width:760px;margin:0 auto}
details{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:14px 18px;margin-bottom:10px}
summary{font-weight:700;cursor:pointer;font-size:17px}
details p{color:var(--muted);margin:10px 0 0}
footer{text-align:center;color:var(--muted);padding:40px 16px;font-size:14px}
footer a{color:var(--saffron-ink);font-weight:700}
'''

PATTERN = ('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
           '<g fill="none" stroke="#F4B400" stroke-opacity=".14" stroke-width="2"><rect x="17" y="17" width="30" height="30"/>'
           '<rect x="17" y="17" width="30" height="30" transform="rotate(45 32 32)"/></g>'
           '<circle cx="32" cy="32" r="3" fill="#F4B400" fill-opacity=".14"/></svg>')


def main() -> None:
    if SITE.exists():
        shutil.rmtree(SITE)
    (SITE / 'en').mkdir(parents=True)
    (SITE / 'img').mkdir()
    for lang, src in (('ar', ROOT / 'docs/images/screenshots'), ('en', ROOT / 'docs/images/screenshots/en')):
        (SITE / 'img' / lang).mkdir()
        for s in SHOTS:
            shutil.copy(src / f'{s}.png', SITE / 'img' / lang / f'{s}.png')
    for lang in ('ar', 'en'):
        shutil.copy(ROOT / f'docs/images/banner.{lang}.png', SITE / 'img' / f'banner.{lang}.png')
    shutil.copy(ROOT / 'tool/icon_preview.png', SITE / 'img/icon.png')
    (SITE / 'img/pattern.svg').write_text(PATTERN)
    (SITE / 'style.css').write_text(CSS.strip() + '\n')
    (SITE / 'index.html').write_text(page('ar'))
    (SITE / 'en/index.html').write_text(page('en'))
    (SITE / 'robots.txt').write_text(f'User-agent: *\nAllow: /\nSitemap: {BASE}sitemap.xml\n')
    (SITE / 'sitemap.xml').write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
        + ''.join(
            f'  <url><loc>{BASE}{p}</loc>'
            f'<xhtml:link rel="alternate" hreflang="ar" href="{BASE}"/>'
            f'<xhtml:link rel="alternate" hreflang="en" href="{BASE}en/"/></url>\n' for p in ('', 'en/'))
        + '</urlset>\n')
    (SITE / '.nojekyll').write_text('')
    print('site/ built')


if __name__ == '__main__':
    main()
