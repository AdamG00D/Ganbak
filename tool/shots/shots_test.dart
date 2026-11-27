import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/core/settings/app_settings.dart';
import 'package:wasl/core/storage/chat_store.dart';
import 'package:wasl/core/storage/vault.dart';
import 'package:wasl/features/home/transport_screen.dart';
import 'package:wasl/features/settings/settings_screen.dart';

import 'harness.dart';

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
  });
}
