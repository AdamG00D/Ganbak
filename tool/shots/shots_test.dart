import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/core/settings/app_settings.dart';
import 'package:wasl/core/storage/chat_store.dart';
import 'package:wasl/core/storage/vault.dart';
import 'package:flutter/material.dart';
import 'package:wasl/features/chat/chat_page.dart';
import 'package:wasl/features/chat/core/chat_session.dart';
import 'package:wasl/l10n/l10n.dart';
import 'package:wasl/features/home/home_screen.dart';
import 'package:wasl/features/home/transport_screen.dart';
import 'package:wasl/features/hub/chat_hub.dart';
import 'package:wasl/features/games/core/game_kind.dart';
import 'package:wasl/features/games/core/game_room.dart';
import 'package:wasl/features/games/ui/game_help.dart';
import 'package:wasl/features/games/ui/game_picker.dart';
import 'package:wasl/features/games/ui/game_screen.dart';
import 'package:wasl/features/settings/settings_screen.dart';

import 'harness.dart';
import 'sample.dart';
import 'sample_games.dart';

/// صور الشاشات للمراجعة (مش اختبار): build/shots/<اسم>.<لغة>.<فاتح|غامق>.png
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await Vault.instance.init(root: await Directory.systemTemp.createTemp('wasl_shots_'));
    ChatStore.instance.reset();
    await Shots.loadFonts();
    await ProfileStore.instance.create(name: 'آدم', color: 1, cartoon: 3);
  });

  testWidgets('core transport', (tester) async {
    Shots.phone(tester);
    await Shots.shoot(tester, 'transport', () => const TransportScreen());
  });

  testWidgets('core settings', (tester) async {
    Shots.phone(tester);
    await Shots.shoot(tester, 'settings', () => const SettingsScreen());
    await Shots.shoot(tester, 'settings-look', () => const SettingsScreen(), then: (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -520));
      await t.pump(const Duration(milliseconds: 300));
    });
  });

  group('home', () {
    final hub = ChatHub.instance;
    setUp(() async {});

    Future<void> world(WidgetTester tester) async {
      if (hub.running) return;
      await tester.runAsync(() async {
        await hub.start(TransportKind.wifi);
        await Sample.fill(hub);
      });
    }

    testWidgets('home chats', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'home-chats', () => const HomeScreen(kind: TransportKind.wifi));
    });

    testWidgets('home groups', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'home-groups', () => const HomeScreen(kind: TransportKind.wifi), then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(1));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
      });
    });

    testWidgets('home nearby', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'home-nearby', () => const HomeScreen(kind: TransportKind.wifi), then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(2));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
      });
    });

    testWidgets('chat direct', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'chat-direct', () => ChatPage(conversation: Sample.karimChat));
    });

    testWidgets('chat group', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'chat-group', () => ChatPage(conversation: Sample.shilla));
    });
  });

  group('games', () {
    final hub = ChatHub.instance;

    Future<void> world(WidgetTester tester) async {
      if (hub.running) return;
      await tester.runAsync(() async {
        await hub.start(TransportKind.wifi);
        await Sample.fill(hub);
      });
    }

    Future<void> room(WidgetTester tester, String name, Future<GameRoom> Function(String me) make) async {
      Shots.phone(tester);
      await world(tester);
      late GameRoom r;
      await tester.runAsync(() async {
        r = await make(hub.myId);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await Shots.shoot(tester, name, () => GameScreen(room: r, title: 'كريم'));
    }

    testWidgets('games picker', (tester) async {
      Shots.phone(tester);
      await world(tester);
      for (final group in [false, true]) {
        await Shots.shoot(
          tester,
          group ? 'games-picker-group' : 'games-picker',
          () => Builder(builder: (context) => Scaffold(body: Center(child: Text(context.l10n.games)))),
          then: (t) async {
            final ctx = t.element(find.byType(Scaffold));
            pickGame(ctx, group: group, title: group ? ctx.l10n.playWithGroup : ctx.l10n.playWith('كريم'));
            await t.pump();
            await t.pump(const Duration(milliseconds: 600));
          },
        );
      }
    });

    testWidgets('games help', (tester) async {
      Shots.phone(tester);
      for (final k in [GameKind.mafia, GameKind.battleship, GameKind.spy]) {
        await Shots.shoot(tester, 'game-help-${k.id}', () => GameHelpPage(kind: k));
      }
      await Shots.shoot(tester, 'game-help-mafia-long', () => const GameHelpPage(kind: GameKind.mafia), then: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await t.pump(const Duration(milliseconds: 300));
      });
    });

    testWidgets('games xo', (tester) async => room(tester, 'game-xo', GameSamples.xo));
    testWidgets('games xo won', (tester) async => room(tester, 'game-xo-won', GameSamples.xoWon));
    testWidgets('games c4', (tester) async => room(tester, 'game-c4', GameSamples.connect4));
    testWidgets('games dots', (tester) async => room(tester, 'game-dots', GameSamples.dots));
    testWidgets('games memory', (tester) async => room(tester, 'game-memory', GameSamples.memory));
    testWidgets('games rps', (tester) async => room(tester, 'game-rps', GameSamples.rps));
    testWidgets('games bs place', (tester) async => room(tester, 'game-bs-place', (me) => GameSamples.battleship(me, placing: true)));
    testWidgets('games bs', (tester) async => room(tester, 'game-bs', GameSamples.battleship));
    testWidgets('games lobby', (tester) async => room(tester, 'game-lobby', GameSamples.lobby));
    testWidgets('games spy', (tester) async => room(tester, 'game-spy', GameSamples.spy));
    testWidgets('games spy vote', (tester) async => room(tester, 'game-spy-vote', (me) => GameSamples.spy(me, vote: true)));
    testWidgets('games quiz', (tester) async => room(tester, 'game-quiz', GameSamples.quiz));
    testWidgets('games quiz answer', (tester) async => room(tester, 'game-quiz-answer', (me) => GameSamples.quiz(me, answer: true)));
    testWidgets('games mafia night', (tester) async => room(tester, 'game-mafia-night', GameSamples.mafia));
    testWidgets('games mafia day', (tester) async => room(tester, 'game-mafia-day', (me) => GameSamples.mafia(me, day: true)));

    testWidgets('games chat cards', (tester) async {
      Shots.phone(tester);
      await world(tester);
      final c = Sample.karimChat;
      await tester.runAsync(() async {
        c.games.receive(Sample.karim, {'g': '00112233aabb', 'y': 'inv', 'kind': 'c4', 'hn': 'كريم'}, private: false);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      c.session.messages.add(ChatMessage(
        id: 'game-old',
        text: 'old',
        kind: MessageKind.system,
        game: {'g': '99887766aabb', 'k': 'xo', 'h': hub.myId, 'st': 'done', 'w': {hub.myId: 2, Sample.karim: 1}, 'nm': {hub.myId: 'آدم', Sample.karim: 'كريم'}},
      ));
      await Shots.shoot(tester, 'chat-game-cards', () => ChatPage(conversation: c));
    });
  });
}
