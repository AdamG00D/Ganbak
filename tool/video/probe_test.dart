import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/core/settings/app_settings.dart';
import 'package:wasl/core/storage/chat_store.dart';
import 'package:wasl/core/storage/vault.dart';
import 'package:wasl/features/chat/chat_page.dart';
import 'package:wasl/features/hub/chat_hub.dart';

import '../shots/harness.dart';
import '../shots/sample_world.dart';

/// تجربة: سرعة تسجيل إطارات من التطبيق الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final hub = ChatHub.instance;
  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await Vault.instance.init(root: await Directory.systemTemp.createTemp('wasl_video_'));
    ChatStore.instance.reset();
    await Shots.loadFonts();
    await ProfileStore.instance.create(name: 'آدم', color: 4, cartoon: 5);
  });

  testWidgets('probe', (tester) async {
    Shots.phone(tester);
    await tester.runAsync(() => World.build(hub));
    await tester.pumpWidget(Shots.app(ChatPage(conversation: World.monaChat)));
    await tester.pump(const Duration(milliseconds: 600));
    final out = Directory('build/video/probe')..createSync(recursive: true);
    final sw = Stopwatch()..start();
    for (var f = 0; f < 45; f++) {
      if (f == 10) {
        await tester.runAsync(() => World.mona.sessions[hub.myId]!.send('وصلت يا آدم؟ 👋'));
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 66));
      await tester.runAsync(() async {
        final b = tester.binding.renderViewElement!.findRenderObject();
        final boundary = find.byType(RepaintBoundary).evaluate().first.renderObject! as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        await File('${out.path}/f${f.toString().padLeft(4, '0')}.png').writeAsBytes(png!.buffer.asUint8List());
        b.hashCode;
      });
    }
    // ignore: avoid_print
    print('45 frames in ${sw.elapsedMilliseconds} ms');
  });
}
