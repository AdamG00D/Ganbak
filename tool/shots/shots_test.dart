import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganbak/core/profile/profile.dart';
import 'package:ganbak/core/settings/app_settings.dart';
import 'package:ganbak/core/storage/chat_store.dart';
import 'package:ganbak/core/storage/vault.dart';
import 'package:flutter/material.dart';
import 'package:ganbak/features/chat/chat_page.dart';
import 'package:ganbak/features/chat/person_sheet.dart';
import 'package:ganbak/features/chat/core/chat_session.dart';
import 'package:ganbak/l10n/l10n.dart';
import 'package:ganbak/features/home/home_screen.dart';
import 'package:ganbak/features/home/transport_screen.dart';
import 'package:ganbak/features/hub/chat_hub.dart';
import 'package:ganbak/features/games/core/game_kind.dart';
import 'package:ganbak/features/games/core/game_room.dart';
import 'package:ganbak/features/games/ui/game_help.dart';
import 'package:ganbak/features/games/ui/game_picker.dart';
import 'package:ganbak/features/games/ui/game_screen.dart';
import 'package:ganbak/features/groups/group_ui.dart';
import 'package:ganbak/features/guide/guide_screen.dart';
import 'package:ganbak/features/net/wasl_net_ui.dart';
import 'package:ganbak/features/share/share_screen.dart';
import 'package:ganbak/features/share/share_server.dart';
import 'package:ganbak/features/net/wasl_network.dart';
import 'package:ganbak/features/sos/sos_ui.dart';
import 'package:ganbak/mesh/mesh_router.dart';
import 'package:ganbak/features/settings/settings_screen.dart';

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
    await ProfileStore.instance.create(name: 'زياد', color: 1, cartoon: 3);
  });

  testWidgets('core transport', (tester) async {
    Shots.phone(tester);
    await Shots.shoot(tester, 'transport', () => const TransportScreen());
  });

  testWidgets('core guide', (tester) async {
    Shots.phone(tester);
    await Shots.shoot(tester, 'guide', () => const GuideScreen());
    await Shots.shoot(tester, 'guide-wifi', () => const GuideScreen(), then: (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await t.pump(const Duration(milliseconds: 300));
    });
    await Shots.shoot(tester, 'guide-games', () => const GuideScreen(section: GuideSection.games), settle: const Duration(milliseconds: 900));
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

    // الهوية: اتنين بنفس الاسم، وحد باسم كريم بس مش هو، وصفحة "عنه"
    testWidgets('identity', (tester) async {
      Shots.phone(tester);
      await world(tester);
      final r = hub.router!;
      const mona2 = 'b0b1b2b3b4b5b6b7', fakeKarim = 'c0c1c2c3c4c5c6c7';
      r.nodes[mona2] = MeshNode(mona2, Uint8List(32))
        ..name = 'مُنى'
        ..color = 3
        ..cartoon = 20
        ..hops = 1;
      r.nodes[fakeKarim] = MeshNode(fakeKarim, Uint8List(32))
        ..name = 'كريم'
        ..color = 6
        ..cartoon = 9
        ..hops = 2;
      await Shots.shoot(tester, 'identity-nearby', () => const HomeScreen(kind: TransportKind.wifi), then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(2));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.drag(find.byType(Scrollable).last, const Offset(0, -600));
        await t.pump(const Duration(milliseconds: 400));
      });
      final fake = hub.openDirect(fakeKarim)!;
      await Shots.shoot(tester, 'identity-warning', () => ChatPage(conversation: fake));
      await Shots.shoot(tester, 'identity-person', () => ChatPage(conversation: Sample.karimChat), then: (t) async {
        showPersonSheet(t.element(find.byType(ChatPage)), Sample.karimChat);
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      });
      r.nodes.remove(mona2);
      r.nodes.remove(fakeKarim);
    });

    // دعوة لجروب: الكارت في صفحة الجروبات، وزرار "ادعي حد" في بيانات الجروب
    testWidgets('invites', (tester) async {
      Shots.phone(tester);
      await world(tester);
      const ad = GroupAd(id: 'f0f1f2f3f4f5f6f7', name: 'رحلة سيوة', mode: GroupMode.password, owner: Sample.karim);
      final inv = GroupInvite(ad, Uint8List(32), Sample.karim, 'كريم');
      hub.invites.add(inv);
      await Shots.shoot(tester, 'invite-card', () => const HomeScreen(kind: TransportKind.wifi), then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(1));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
      });
      hub.invites.remove(inv);
      await Shots.shoot(tester, 'invite-button', () => GroupInfoScreen(group: Sample.shilla));
    });

    testWidgets('create group', (tester) async {
      Shots.phone(tester);
      await world(tester);
      Future<void> open(WidgetTester t) async {
        showCreateGroupSheet(t.element(find.byType(Scaffold).first));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      }
      await Shots.shoot(tester, 'group-create', () => const Scaffold(body: SizedBox.expand()), then: open);
      Shots.textScale = 1.3;
      await Shots.shoot(tester, 'group-create.big', () => const Scaffold(body: SizedBox.expand()),
          then: open, themes: const [Brightness.light]);
      Shots.textScale = 1;
    });

    // الرسالة تستنى صاحبها: كريم مش موجود، والكلام بس متاح
    testWidgets('chat away', (tester) async {
      Shots.phone(tester);
      await world(tester);
      final away = Sample.awayMessage();
      Sample.karimChat.session.messages.add(away);
      await Shots.shoot(tester, 'chat-away', () => ChatPage(conversation: Sample.karimChat));
      Sample.karimChat.session.messages.remove(away);
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
        game: {'g': '99887766aabb', 'k': 'xo', 'h': hub.myId, 'st': 'done', 'w': {hub.myId: 2, Sample.karim: 1}, 'nm': {hub.myId: 'زياد', Sample.karim: 'كريم'}},
      ));
      await Shots.shoot(tester, 'chat-game-cards', () => ChatPage(conversation: c));
    });
  });

  // خط كبير (1.3×) عربي وإنجليزي فاتح: أي كلام بيخرج برا مكانه بيوقّع الاختبار
  group('big', () {
    final hub = ChatHub.instance;
    setUp(() => Shots.textScale = 1.3);
    tearDown(() => Shots.textScale = 1);

    Future<void> world(WidgetTester tester) async {
      if (hub.running) return;
      await tester.runAsync(() async {
        await hub.start(TransportKind.wifi);
        await Sample.fill(hub);
      });
    }

    const light = [Brightness.light];
    testWidgets('big screens', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'transport', () => const TransportScreen(), themes: light);
      await Shots.shoot(tester, 'home-chats', () => const HomeScreen(kind: TransportKind.wifi), themes: light);
      await Shots.shoot(tester, 'guide', () => const GuideScreen(), themes: light);
      await Shots.shoot(tester, 'chat-group', () => ChatPage(conversation: Sample.shilla), themes: light);
      final away = Sample.awayMessage();
      Sample.karimChat.session.messages.add(away);
      await Shots.shoot(tester, 'chat-away', () => ChatPage(conversation: Sample.karimChat), themes: light);
      Sample.karimChat.session.messages.remove(away);
      for (final k in [GameKind.mafia, GameKind.battleship]) {
        await Shots.shoot(tester, 'game-help-${k.id}', () => GameHelpPage(kind: k), themes: light);
      }
      WaslNetwork.instance
        ..state = NetState.hosting
        ..hosted = const WifiOffer(ssid: 'AndroidShare_4821', pass: 'k3v9x2m8q1');
      await Shots.shoot(tester, 'net-hosting', () => const HomeScreen(kind: TransportKind.wifi), themes: light,
          then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(2));
        await t.pump();
        await t.pump(const Duration(milliseconds: 900));
      });
      await Shots.shoot(tester, 'net-qr', () => const HomeScreen(kind: TransportKind.wifi), themes: light,
          then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(2));
        await t.pump();
        await t.pump(const Duration(milliseconds: 900));
        await t.tap(find.byIcon(Icons.qr_code_2_rounded));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      });
      const apk = ApkInfo(path: '/x', size: 31457280, sha256: '3f9a1c0be47d2a8851f0c6e2d93b7a4405e1c8f2a6b9d03e7c51f4a8b2e9d6c1');
      await Shots.shoot(tester, 'share-ready', () => const ShareAppScreen(testApk: apk, testUrl: 'http://192.168.43.1:8080/'),
          themes: light);
      WaslNetwork.instance
        ..state = NetState.idle
        ..hosted = null;
      await Shots.shoot(tester, 'share-idle', () => const ShareAppScreen(testApk: apk), themes: light);
      await Shots.shoot(
        tester,
        'net-suggest',
        () => const Scaffold(body: SafeArea(child: Column(children: [WaslNetSuggestCard(count: 4)]))),
        themes: light,
      );
    });

    for (final (name, make) in <(String, Future<GameRoom> Function(String))>[
      ('game-xo', GameSamples.xo),
      ('game-dots', GameSamples.dots),
      ('game-rps', GameSamples.rps),
      ('game-bs', GameSamples.battleship),
      ('game-lobby', GameSamples.lobby),
      ('game-spy', GameSamples.spy),
      ('game-quiz-answer', (me) => GameSamples.quiz(me, answer: true)),
      ('game-mafia-day', (me) => GameSamples.mafia(me, day: true)),
    ]) {
      testWidgets('big $name', (tester) async {
        Shots.phone(tester);
        await world(tester);
        late GameRoom r;
        await tester.runAsync(() async {
          r = await make(hub.myId);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await Shots.shoot(tester, name, () => GameScreen(room: r), themes: light);
      });
    }

    testWidgets('big picker', (tester) async {
      Shots.phone(tester);
      await Shots.shoot(
        tester,
        'games-picker',
        () => Builder(builder: (context) => Scaffold(body: Center(child: Text(context.l10n.games)))),
        themes: light,
        then: (t) async {
          final ctx = t.element(find.byType(Scaffold));
          pickGame(ctx, group: false, title: ctx.l10n.playWith('كريم'));
          await t.pump();
          await t.pump(const Duration(milliseconds: 600));
        },
      );
    });
  });

  group('net', () {
    final hub = ChatHub.instance;
    final net = WaslNetwork.instance;
    const offer = WifiOffer(ssid: 'AndroidShare_4821', pass: 'k3v9x2m8q1');

    Future<void> world(WidgetTester tester) async {
      if (hub.running) return;
      await tester.runAsync(() async {
        await hub.start(TransportKind.wifi);
        await Sample.fill(hub);
      });
    }

    Future<void> nearby(WidgetTester t) async {
      await t.tap(find.byType(NavigationDestination).at(2));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 800));
    }

    tearDown(() {
      net
        ..state = NetState.idle
        ..hosted = null
        ..joined = null
        ..joinedFrom = null;
      hub.router?.nodes[Sample.karim]?.wifi = null;
    });

    testWidgets('net card idle', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'net-idle', () => const HomeScreen(kind: TransportKind.wifi), then: nearby);
    });

    testWidgets('net card hosting', (tester) async {
      Shots.phone(tester);
      await world(tester);
      net
        ..state = NetState.hosting
        ..hosted = offer;
      await Shots.shoot(tester, 'net-hosting', () => const HomeScreen(kind: TransportKind.wifi), then: nearby);
    });

    testWidgets('net qr', (tester) async {
      Shots.phone(tester);
      await world(tester);
      net
        ..state = NetState.hosting
        ..hosted = offer;
      await Shots.shoot(tester, 'net-qr', () => const HomeScreen(kind: TransportKind.wifi), then: (t) async {
        await nearby(t);
        await t.tap(find.byIcon(Icons.qr_code_2_rounded));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      });
    });

    testWidgets('net suggest', (tester) async {
      Shots.phone(tester);
      await Shots.shoot(
        tester,
        'net-suggest',
        () => const Scaffold(body: SafeArea(child: Column(children: [WaslNetSuggestCard(count: 4)]))),
      );
    });

    testWidgets('share app', (tester) async {
      Shots.phone(tester);
      await world(tester);
      const apk = ApkInfo(path: '/x', size: 31457280, sha256: '3f9a1c0be47d2a8851f0c6e2d93b7a4405e1c8f2a6b9d03e7c51f4a8b2e9d6c1');
      await Shots.shoot(tester, 'share-idle', () => const ShareAppScreen(testApk: apk));
      net
        ..state = NetState.hosting
        ..hosted = offer;
      await Shots.shoot(tester, 'share-ready', () => const ShareAppScreen(testApk: apk, testUrl: 'http://192.168.43.1:8080/'));
      await Shots.shoot(tester, 'share-ready-low', () => const ShareAppScreen(testApk: apk, testUrl: 'http://192.168.43.1:8080/'),
          then: (t) async {
        await t.drag(find.byType(ListView), const Offset(0, -900));
        await t.pump(const Duration(milliseconds: 300));
      });
    });

    testWidgets('net card joined', (tester) async {
      Shots.phone(tester);
      await world(tester);
      net
        ..state = NetState.joined
        ..joined = offer
        ..joinedFrom = 'كريم';
      await Shots.shoot(tester, 'net-joined', () => const HomeScreen(kind: TransportKind.wifi), then: nearby);
    });

    testWidgets('net offer', (tester) async {
      Shots.phone(tester);
      await world(tester);
      // الناس الوهميين بيختفوا بعد شوية لو الصور كلها اشتغلت ورا بعض: نرجّع كريم لو مش موجود
      hub.router!.nodes.putIfAbsent(
        Sample.karim,
        () => MeshNode(Sample.karim, Uint8List(32))
          ..name = 'كريم'
          ..cartoon = 7
          ..hops = 1,
      ).wifi = offer;
      await Shots.shoot(tester, 'net-offer', () => const Scaffold(body: SafeArea(child: Column(children: [WaslNetOfferBanner(kind: TransportKind.both)]))));
      await Shots.shoot(tester, 'net-offer-bt', () => const Scaffold(body: SafeArea(child: Column(children: [WaslNetOfferBanner(kind: TransportKind.bluetooth)]))));
    });

    testWidgets('net guide', (tester) async {
      Shots.phone(tester);
      await Shots.shoot(tester, 'guide-net', () => const GuideScreen(), then: (t) async {
        await t.scrollUntilVisible(find.text(t.element(find.byType(GuideScreen)).l10n.guideNetTitle).first, 400,
            scrollable: find.byType(Scrollable).first);
        await t.pump(const Duration(milliseconds: 300));
      });
    });
  });

  group('sos', () {
    final hub = ChatHub.instance;

    Future<void> world(WidgetTester tester) async {
      if (hub.running) return;
      await tester.runAsync(() async {
        await hub.start(TransportKind.wifi);
        await Sample.fill(hub);
      });
    }

    MeshNode karim() => hub.router!.nodes.putIfAbsent(
          Sample.karim,
          () => MeshNode(Sample.karim, Uint8List(32))
            ..name = 'كريم'
            ..cartoon = 7
            ..hops = 2,
        );

    testWidgets('sos alert', (tester) async {
      Shots.phone(tester);
      await world(tester);
      karim()
        ..sos = const SosSignal('عند البوابة الشمال، رجلي اتلوت ومش قادر أمشي')
        ..hops = 2;
      hub.sosDismissed.clear();
      await Shots.shoot(tester, 'sos-alert', () => const HomeScreen(kind: TransportKind.wifi));
      karim().sos = null;
    });

    testWidgets('sos mine and card', (tester) async {
      Shots.phone(tester);
      await world(tester);
      await Shots.shoot(tester, 'sos-card', () => const HomeScreen(kind: TransportKind.wifi), then: (t) async {
        await t.tap(find.byType(NavigationDestination).at(2));
        await t.pump();
        await t.pump(const Duration(milliseconds: 900));
      });
      await Shots.shoot(tester, 'sos-sheet', () => Builder(builder: (context) => Scaffold(body: Center(child: Text(context.l10n.sosAsk)))),
          then: (t) async {
        showSosSheet(t.element(find.byType(Scaffold)));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      });
      await tester.runAsync(() => hub.setSos('عند البوابة'));
      await Shots.shoot(tester, 'sos-mine', () => const HomeScreen(kind: TransportKind.wifi));
      await tester.runAsync(() async => hub.stopSos());
    });
  });
}
