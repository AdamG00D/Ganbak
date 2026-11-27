// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/core/settings/app_settings.dart';
import 'package:wasl/core/storage/chat_store.dart';
import 'package:wasl/core/storage/vault.dart';
import 'package:wasl/features/chat/chat_page.dart';
import 'package:wasl/features/games/core/game_room.dart';
import 'package:wasl/features/games/ui/game_picker.dart';
import 'package:wasl/features/games/ui/game_screen.dart';
import 'package:wasl/features/groups/group_ui.dart';
import 'package:wasl/features/guide/guide_screen.dart';
import 'package:wasl/features/home/home_screen.dart';
import 'package:wasl/features/home/transport_screen.dart';
import 'package:wasl/features/hub/chat_hub.dart';
import 'package:wasl/features/onboarding/profile_editor.dart';
import 'package:wasl/l10n/l10n.dart';

import 'banner.dart';
import 'harness.dart';
import 'sample_games.dart';
import 'sample_world.dart';

/// صور الـ README والبانرات (في build/readme) — بعدها: python3 tool/shots/readme.py بينقلها لـ docs/images.
///
///   flutter test tool/shots/readme_test.dart && python3 tool/shots/readme.py
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final hub = ChatHub.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await Vault.instance.init(root: await Directory.systemTemp.createTemp('wasl_readme_'));
    ChatStore.instance.reset();
    await Shots.loadFonts();
    await ProfileStore.instance.create(name: 'آدم', color: 4, cartoon: 5);
    Shots.out = Directory('build/readme');
  });

  Future<void> world(WidgetTester tester) async {
    if (hub.running) return;
    await tester.runAsync(() => World.build(hub));
    GameSamples.people = [World.karim.id, World.salma.id, World.mona.id, World.omar.id, World.youssef.id];
  }

  /// صورة بالعربي وصورة بالإنجليزي في الثيم المطلوب.
  Future<void> shot(WidgetTester tester, String name, Widget Function() screen,
      {Brightness theme = Brightness.light, Future<void> Function(WidgetTester t)? then}) async {
    await Shots.shoot(tester, name, screen, themes: [theme], then: then);
  }

  testWidgets('readme screens', (tester) async {
    Shots.phone(tester);
    await world(tester);
    Future<void> tab(WidgetTester t, int i) async {
      await t.tap(find.byType(NavigationDestination).at(i));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 800));
    }

    await shot(tester, 'chats', () => const HomeScreen(kind: TransportKind.wifi));
    await shot(tester, 'nearby', () => const HomeScreen(kind: TransportKind.wifi), then: (t) => tab(t, 2));
    await shot(tester, 'group-chat', () => ChatPage(conversation: World.shilla));
    await shot(tester, 'direct-chat-dark', () => ChatPage(conversation: World.monaChat), theme: Brightness.dark);
    await shot(tester, 'transport', () => const TransportScreen());
    await shot(tester, 'group-info', () => GroupInfoScreen(group: World.shilla));
    await shot(
      tester,
      'member-sheet-dark',
      () => GroupInfoScreen(group: World.shilla),
      theme: Brightness.dark,
      then: (t) async {
        final ctx = t.element(find.byType(GroupInfoScreen));
        showMemberSheet(ctx, World.shilla, World.karim.id);
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      },
    );
    await shot(tester, 'profile', () => const ProfileEditor());
    await shot(tester, 'guide', () => const GuideScreen());
    await shot(
      tester,
      'games',
      () => ChatPage(conversation: World.monaChat),
      then: (t) async {
        final ctx = t.element(find.byType(ChatPage));
        pickGame(ctx, group: false, title: ctx.l10n.playWith(World.monaChat.title));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      },
    );
  });

  for (final (name, make) in <(String, Future<GameRoom> Function(String))>[
    ('game-connect4', GameSamples.connect4),
    ('game-mafia', (me) => GameSamples.mafia(me, day: true)),
  ]) {
    testWidgets('readme $name', (tester) async {
      Shots.phone(tester);
      await world(tester);
      late GameRoom r;
      await tester.runAsync(() async {
        r = await make(hub.myId);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await shot(tester, name, () => GameScreen(room: r));
    });
  }

  testWidgets('readme banners', (tester) async {
    tester.view.physicalSize = const Size(1280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final ar in [true, false]) {
      await tester.pumpWidget(Shots.app(ReadmeBanner(arabic: ar), locale: Locale(ar ? 'ar' : 'en')));
      await tester.pump(const Duration(milliseconds: 200));
      await Shots.save(tester, 'banner.${ar ? 'ar' : 'en'}');
    }
  });
}
