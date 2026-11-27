import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/features/games/core/game_kind.dart';
import 'package:wasl/features/games/core/game_room.dart';
import 'package:wasl/features/games/engines/engines.dart';
import 'package:wasl/features/games/ui/game_help.dart';
import 'package:wasl/features/games/ui/game_screen.dart';
import 'package:wasl/l10n/l10n.dart';

class _Link implements RoomLink {
  @override
  String get myId => 'aaaaaaaaaaaaaaa1';
  @override
  String get myName => 'آدم';
  @override
  bool get trustedPublic => true;
  @override
  void sendAll(Map<String, dynamic> m) {}
  @override
  void sendTo(String id, Map<String, dynamic> m) {}
  @override
  void changed(GameRoom room) {}
}

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.build(AccentTheme.all.first, Brightness.light),
      locale: const Locale('ar'),
      supportedLocales: L10n.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

/// شاشات الألعاب: بتترسم بحالة حقيقية، ومبتقعش لو صاحب الغرفة بعت حاجات غريبة.
void main() {
  const me = 'aaaaaaaaaaaaaaa1';
  final others = ['aaaaaaaaaaaaaaa2', 'aaaaaaaaaaaaaaa3', 'aaaaaaaaaaaaaaa4', 'aaaaaaaaaaaaaaa5', 'aaaaaaaaaaaaaaa6'];

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final kind in GameKind.values) {
    testWidgets('${kind.id}: حالة حقيقية من القواعد', (tester) async {
      phone(tester);
      final players = [me, ...others.take(kind.minPlayers - 1)];
      final room = GameRoom(id: '00112233aabb', kind: kind, host: me, link: _Link(), engineFactory: createEngine)
        ..players = players;
      for (final p in players) {
        room.names[p] = p.substring(14);
      }
      room.start();
      await tester.pumpWidget(_app(GameScreen(room: room)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      room.close(RoomEnd.ended);
      await tester.pump();
    });

    testWidgets('${kind.id}: حالة غريبة مبتوقعش الشاشة', (tester) async {
      phone(tester);
      final room = GameRoom(id: '00112233aabb', kind: kind, host: 'aaaaaaaaaaaaaaa2', link: _Link())
        ..players = [me, 'aaaaaaaaaaaaaaa2']
        ..phase = RoomPhase.playing;
      for (final junk in <Map<String, dynamic>>[
        {'o': 5, 'turn': 7, 'phase': 3, 's': [1], 'roles': 'x', 'ready': 'y', 'hist': [1, 'a'], 'opts': {'a': 1}},
        {'phase': 'vote', 'voted': [1, 2], 'alive': 'all', 'left': 'soon', 'votes': [], 'picks': 'x', 'right': 'r'},
        {'phase': 'done', 'spy': 3, 'word': 9, 'options': [1], 'caught': [], 'side': 1, 'out': 5, 'died': {}},
        {'phase': 'fire', 'shots': {'x': 'y'}, 'revealed': {'a': 1}, 'pending': 'p', 'cheat': 4},
      ]) {
        room.view = junk;
        room.secret = {'role': 5, 'team': 'x', 'kills': [1], 'checks': [[1], 'x'], 'word': 3, 'spy': 'yes'};
        await tester.pumpWidget(_app(GameScreen(room: room)));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: '$junk');
      }
    });

    testWidgets('${kind.id}: صفحة الشرح', (tester) async {
      phone(tester);
      await tester.pumpWidget(_app(GameHelpPage(kind: kind)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }

  test('الأرقام العشوائية للقواعد بتيجي من Random.secure في التطبيق', () {
    // الغرفة من غير rng بتستخدم Random.secure (محدش يقدر يتوقع الأدوار أو الكروت)
    final room = GameRoom(id: '00112233aabb', kind: GameKind.mafia, host: me, link: _Link());
    expect(room.rng.runtimeType.toString(), Random.secure().runtimeType.toString());
  });
}
