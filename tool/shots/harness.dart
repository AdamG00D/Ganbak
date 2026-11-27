import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganbak/core/nav.dart';
import 'package:ganbak/core/settings/app_settings.dart';
import 'package:ganbak/core/theme/app_theme.dart';
import 'package:ganbak/l10n/l10n.dart';

/// أداة صور الشاشات: بترسم الشاشات الحقيقية بالخط الحقيقي وبتحفظها PNG في build/shots
/// عشان نراجع التصميم بالعين (عربي/إنجليزي، فاتح/غامق) من غير موبايل.
///
///   flutter test tool/shots/shots_test.dart            (كل الصور)
///   flutter test tool/shots/shots_test.dart --name games   (جزء منها)
class Shots {
  Shots._();

  static Directory out = Directory('build/shots');
  static bool _fonts = false;

  /// خط Plex + أيقونات Material + إيموجي (من النظام لو موجود).
  static Future<void> loadFonts() async {
    if (_fonts) return;
    _fonts = true;
    final plex = FontLoader('Plex');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      plex.addFont(_bytes('assets/fonts/IBMPlexSansArabic-$w.ttf'));
    }
    await plex.load();
    final root = Platform.environment['FLUTTER_ROOT'] ?? _flutterRoot();
    final icons = FontLoader('MaterialIcons')
      ..addFont(_bytes('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final path in const [
      '/usr/share/fonts/google-noto-color-emoji-fonts/Noto-COLRv1.ttf',
      '/usr/share/fonts/google-noto-emoji-fonts/NotoEmoji-Regular.ttf',
    ]) {
      if (File(path).existsSync()) {
        final emoji = FontLoader('ShotsEmoji')..addFont(_bytes(path));
        await emoji.load();
        break;
      }
    }
  }

  static String _flutterRoot() {
    final dart = File(Platform.resolvedExecutable).parent; // .../bin/cache/dart-sdk/bin
    return dart.parent.parent.parent.parent.path;
  }

  static Future<ByteData> _bytes(String path) async {
    final b = File(path).readAsBytesSync();
    return ByteData.view(b.buffer);
  }

  /// حجم الخط (زي إعداد "حجم الخط" في الموبايل) — 1.3 بيكشف الكلام اللي بيخرج برا مكانه.
  static double textScale = 1;

  static Widget app(Widget home, {Brightness brightness = Brightness.light, Locale locale = const Locale('ar')}) {
    L10n.use(locale);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: _withEmoji(AppTheme.build(AppSettings.instance.accent, brightness)),
      locale: locale,
      supportedLocales: L10n.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => RepaintBoundary(
        key: _boundary,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: home,
    );
  }

  static final _boundary = GlobalKey();

  /// الموبايل بيرسم الإيموجي بخط النظام لوحده؛ هنا لازم نقوله صراحة.
  static ThemeData _withEmoji(ThemeData t) => t.copyWith(
        textTheme: t.textTheme.apply(fontFamilyFallback: const ['ShotsEmoji']),
      );

  /// مقاس موبايل عادي (360×760 dp) بكثافة 1.5.
  static void phone(WidgetTester tester, {Size size = const Size(360, 760)}) {
    tester.view.physicalSize = size * 1.5;
    tester.view.devicePixelRatio = 1.5;
    tester.view.padding = const FakeViewPadding(top: 36, bottom: 24);
    addTearDown(tester.view.reset);
  }

  /// يحفظ اللي على الشاشة دلوقتي (الشاشة كلها، بالنوافذ والقوايم اللي فوقها).
  static Future<File> save(WidgetTester tester, String name) async {
    out.createSync(recursive: true);
    final file = File('${out.path}/$name.png');
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
    return file;
  }

  /// يرسم [screen] في كل التوليفات المطلوبة ويحفظ كل واحدة.
  static Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget Function() screen, {
    List<Brightness> themes = const [Brightness.light, Brightness.dark],
    List<Locale> locales = const [Locale('ar'), Locale('en')],
    Future<void> Function(WidgetTester tester)? then,
    Duration settle = const Duration(milliseconds: 600),
  }) async {
    for (final l in locales) {
      for (final b in themes) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app(screen(), brightness: b, locale: l));
        await tester.pump(settle);
        if (then != null) await then(tester);
        await tester.pump(const Duration(milliseconds: 50));
        await save(tester, '$name${textScale == 1 ? '' : '.big'}.${l.languageCode}.${b.name}');
      }
    }
    L10n.use(const Locale('ar'));
  }
}
