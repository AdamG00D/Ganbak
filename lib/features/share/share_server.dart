import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/config.dart';
import 'share_page.dart';

/// نسخة التطبيق المتثبتة على الموبايل (اللي هنبعتها).
class ApkInfo {
  const ApkInfo({required this.path, required this.size, required this.sha256, this.split = false});

  final String path;
  final int size;

  /// بصمة الملف (hex) — اللي بيحمّل يقدر يقارنها باللي على شاشة المرسل.
  final String sha256;

  /// التطبيق متثبت كذا جزء (من متجر مثلاً): الملف الأساسي لوحده مش هيتثبت.
  final bool split;

  /// من القناة wasl/system (apkInfo).
  static Future<ApkInfo?> load() async {
    try {
      final r = await const MethodChannel('wasl/system').invokeMapMethod<String, dynamic>('apkInfo');
      final path = r?['path'], size = r?['size'], sha = r?['sha256'];
      if (path is! String || size is! int || sha is! String) return null;
      return ApkInfo(path: path, size: size, sha256: sha, split: r?['split'] == true);
    } catch (_) {
      return null;
    }
  }
}

/// سيرفر صغير جوه التطبيق لـ "شارك وصل": صفحة تحميل + ملف التطبيق، على الشبكة المحلية بس.
///
/// شغال بس طول ما شاشة المشاركة مفتوحة. بيرد على GET/HEAD لمسارين بس (`/` و`/wasl.apk`) — أي حاجة تانية 404،
/// فمفيش أي ملف تاني من الموبايل يطلع. عدد التحميلات في نفس الوقت محدود.
class ShareServer {
  ShareServer({required this.apk});

  final ApkInfo apk;
  HttpServer? _server;
  int _downloads = 0;

  static const preferredPort = 8080;
  static const maxDownloads = 4;

  /// عدد مرات التحميل اللي خلصت (للشاشة).
  final ValueNotifier<int> served = ValueNotifier(0);

  int get port => _server?.port ?? 0;
  bool get running => _server != null;

  Future<bool> start({int? port}) async {
    if (_server != null) return true;
    for (final p in [port ?? preferredPort, 0]) {
      try {
        final s = await HttpServer.bind(InternetAddress.anyIPv4, p, shared: false);
        s
          ..autoCompress = false
          ..idleTimeout = const Duration(seconds: 20)
          ..serverHeader = null;
        _server = s;
        s.listen(_handle, onError: (Object _) {});
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    res.headers
      ..set('Cache-Control', 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer');
    try {
      if (req.method != 'GET' && req.method != 'HEAD') {
        res.statusCode = HttpStatus.methodNotAllowed;
        return;
      }
      switch (req.uri.path) {
        case '/':
          final lang = pageLanguage(req.uri.queryParameters['l'], req.headers.value('accept-language'));
          final html = utf8.encode(SharePage.html(lang: lang, apk: apk, version: AppConfig.appVersion));
          res.headers
            ..contentType = ContentType.html
            ..set('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'; img-src data:")
            ..contentLength = html.length;
          if (req.method == 'GET') res.add(html);
        case '/wasl.apk':
          if (_downloads >= maxDownloads) {
            res.statusCode = HttpStatus.serviceUnavailable;
            res.headers.set('Retry-After', '10');
            return;
          }
          final file = File(apk.path);
          res.headers
            ..contentType = ContentType('application', 'vnd.android.package-archive')
            ..set('Content-Disposition', 'attachment; filename="Wasl-${AppConfig.appVersion}.apk"')
            ..contentLength = await file.length();
          if (req.method == 'HEAD') return;
          _downloads++;
          try {
            await res.addStream(file.openRead());
            served.value++;
          } finally {
            _downloads--;
          }
        default:
          res.statusCode = HttpStatus.notFound;
      }
    } catch (_) {
      // اللي بيحمّل قفل في النص — عادي
    } finally {
      try {
        await res.close();
      } catch (_) {}
    }
  }

  /// لغة الصفحة: `?l=` لو موجود، وإلا لغة متصفح اللي فاتحها.
  @visibleForTesting
  static String pageLanguage(String? query, String? acceptLanguage) {
    if (query == 'ar' || query == 'en') return query!;
    final first = (acceptLanguage ?? '').split(',').first.trim().toLowerCase();
    return first.startsWith('ar') ? 'ar' : 'en';
  }

  /// عنوان الموبايل على الشبكة المحلية (للينك اللي في الكود). [hosting] = شبكة وصل مفتوحة من الموبايل ده:
  /// بنفضّل عنوان الهوت سبوت (غالباً بيخلص بـ .1). بنتجاهل بيانات الموبايل وأي VPN.
  static Future<String?> localAddress({required bool hosting}) async {
    try {
      final list = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      return pickAddress([
        for (final i in list)
          for (final a in i.addresses) (i.name, a.address),
      ], hosting: hosting);
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static String? pickAddress(List<(String, String)> found, {required bool hosting}) {
    bool private(String ip) {
      final p = ip.split('.').map(int.tryParse).toList();
      if (p.length != 4 || p.contains(null)) return false;
      return p[0] == 192 && p[1] == 168 || p[0] == 10 || p[0] == 172 && p[1]! >= 16 && p[1]! <= 31;
    }

    const skip = ['rmnet', 'ccmni', 'pdp', 'dummy', 'tun', 'ppp', 'v4-', 'clat', 'ipsec'];
    final ok = [
      for (final (name, ip) in found)
        if (private(ip) && !skip.any(name.startsWith)) (name, ip),
    ];
    if (ok.isEmpty) return null;
    int score((String, String) e) {
      final (name, ip) = e;
      final ap = name.startsWith('ap') || name.startsWith('swlan') || name.startsWith('softap') || ip.endsWith('.1');
      if (hosting) return ap ? 0 : 1;
      return name.startsWith('wlan') ? 0 : 1;
    }

    ok.sort((a, b) => score(a).compareTo(score(b)));
    return ok.first.$2;
  }
}
