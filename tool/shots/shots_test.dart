import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/core/settings/app_settings.dart';
import 'package:wasl/core/storage/chat_store.dart';
import 'package:wasl/core/storage/vault.dart';
import 'package:flutter/material.dart';
import 'package:wasl/features/chat/chat_page.dart';
import 'package:wasl/features/home/home_screen.dart';
import 'package:wasl/features/home/transport_screen.dart';
import 'package:wasl/features/hub/chat_hub.dart';
import 'package:wasl/features/settings/settings_screen.dart';

import 'harness.dart';
import 'sample.dart';

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
}
