import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganbak/features/share/share_page.dart';
import 'package:ganbak/features/share/share_server.dart';

import 'support.dart';

/// "شارك وصل": السيرفر الصغير بيبعت الصفحة والملف بس، ومفيش أي حاجة تانية.
void main() {
  late Directory dir;
  late File apkFile;
  late ShareServer server;
  final client = HttpClient();

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('wasl_share');
    apkFile = File('${dir.path}/base.apk')..writeAsBytesSync(List.generate(300000, (i) => i % 251));
    await File('${dir.path}/secret.txt').writeAsString('secret');
    server = ShareServer(apk: ApkInfo(path: apkFile.path, size: 300000, sha256: 'ab' * 32));
    expect(await server.start(port: 0), isTrue);
  });

  tearDownAll(() async {
    await server.stop();
    client.close(force: true);
    await dir.delete(recursive: true);
  });

  Future<(int, List<int>, HttpHeaders)> get(String path, {String method = 'GET', String? lang}) async {
    final req = await client.openUrl(method, Uri.parse('http://127.0.0.1:${server.port}$path'));
    if (lang != null) req.headers.set('accept-language', lang);
    final res = await req.close();
    final body = await res.fold<List<int>>([], (a, b) => a..addAll(b));
    return (res.statusCode, body, res.headers);
  }

  test('الصفحة بلغة المتصفح وفيها زرار التحميل والبصمة', () async {
    final (code, body, headers) = await get('/', lang: 'ar-EG,ar;q=0.9,en;q=0.5');
    expect(code, 200);
    final html = utf8.decode(body);
    expect(html, contains('dir="rtl"'));
    expect(html, contains('حمّل التطبيق'));
    expect(html, contains('href="/wasl.apk"'));
    expect(html, contains('abab abab'));
    expect(headers.value('content-security-policy'), contains("default-src 'none'"));
    final (_, en, _) = await get('/?l=en', lang: 'ar');
    expect(utf8.decode(en), contains('Download the app'));
  });

  test('الملف بيتبعت كامل بنوعه', () async {
    final (code, body, headers) = await get('/wasl.apk');
    expect(code, 200);
    expect(body.length, 300000);
    expect(body, apkFile.readAsBytesSync());
    expect(headers.contentType?.mimeType, 'application/vnd.android.package-archive');
    expect(headers.value('content-disposition'), contains('.apk'));
    await waitFor(() => server.served.value >= 1, what: 'العداد');
  });

  test('أي مسار تاني أو طريقة تانية بترجع رفض', () async {
    for (final p in ['/secret.txt', '/../secret.txt', '/%2e%2e/secret.txt', '/wasl.apk/', '/index.html', '/favicon.ico']) {
      final (code, body, _) = await get(p);
      expect(code, 404, reason: p);
      expect(utf8.decode(body, allowMalformed: true), isNot(contains('secret')));
    }
    final (code, _, _) = await get('/', method: 'POST');
    expect(code, 405);
  });

  test('الصفحة لنسخة متثبتة على أجزاء مفيهاش زرار تحميل', () {
    final html = SharePage.html(
      lang: 'en',
      apk: const ApkInfo(path: '/x', size: 1, sha256: 'cd', split: true),
      version: '1.4',
    );
    expect(html, isNot(contains('href="/wasl.apk"')));
    expect(html, contains('installed from a store'));
  });

  test('اختيار العنوان: الهوت سبوت الأول، ومن غير بيانات الموبايل', () {
    final found = [('rmnet_data0', '10.12.0.7'), ('wlan0', '192.168.1.23'), ('ap0', '192.168.43.1')];
    expect(ShareServer.pickAddress(found, hosting: true), '192.168.43.1');
    expect(ShareServer.pickAddress(found, hosting: false), '192.168.1.23');
    expect(ShareServer.pickAddress([('rmnet0', '10.0.0.2'), ('tun0', '10.8.0.1')], hosting: false), isNull);
    expect(ShareServer.pickAddress([('wlan0', '8.8.8.8')], hosting: false), isNull);
    expect(ShareServer.pageLanguage(null, 'en-US,en'), 'en');
    expect(ShareServer.pageLanguage('ar', 'en-US'), 'ar');
    expect(ShareServer.pageLanguage('xx', 'ar'), 'ar');
  });
}
