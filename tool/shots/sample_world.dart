// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/features/chat/core/chat_session.dart';
import 'package:wasl/features/groups/group.dart';
import 'package:wasl/features/groups/group_session.dart';
import 'package:wasl/features/hub/chat_hub.dart';
import 'package:wasl/mesh/mesh_router.dart';
import 'package:wasl/mesh/peer_link.dart';

import '../../test/support.dart';

/// موبايل وهمي حقيقي (مفتاح وموجّه وجلسات) على شبكة في الذاكرة — عشان صور الـ README تبان زي الحقيقة:
/// ناس متصلين فعلاً، شات مشفّر جاهز، جروبات أعضاؤها موجودين.
class WorldPeer {
  WorldPeer._(this.profile, this.link, this.root);

  final Profile profile;
  final MemoryLink link;
  final Directory root;
  late final MeshRouter router;
  final Map<String, GroupInfo> groups = {};
  final Map<String, GroupSession> groupSessions = {};
  final Map<String, ChatSession> sessions = {};
  final Map<String, PeerLink> _peers = {};

  String get id => profile.id;

  static Future<WorldPeer> create(MemoryNet net, Directory root, String name, int color, int? cartoon, int seed) async {
    final p = await Profile.fromSeed(Uint8List.fromList(List.generate(32, (i) => (seed * 31 + i * 7) & 0xff)),
        name: name, color: color, cartoon: cartoon);
    final w = WorldPeer._(p, net.add(p.id)..maxFrame = 200 * 1024, root);
    w.router = MeshRouter(
      link: w.link,
      presenceEvery: const Duration(milliseconds: 200),
      nodeTtl: const Duration(minutes: 10),
      describe: () => {
        'n': p.name,
        'c': p.color,
        'k': base64.encode(p.publicKey),
        'e': ?p.cartoon,
        'g': [for (final g in w.groups.values) g.ad.toWire()],
      },
    );
    w.router
      ..onData = w._onData
      ..onGroup = (g, src, body) => w.groupSessions[g]?.receive(src, body);
    await w.router.start();
    return w;
  }

  ChatSession _session(String peer) => sessions.putIfAbsent(
        peer,
        () => ChatSession(
          myName: profile.name,
          identity: profile.keyPair,
          myStaticKey: profile.publicKey,
          mediaRoot: root,
        ),
      );

  void _onData(String src, String body) {
    final link = _peers.putIfAbsent(
      src,
      () => PeerLink(
        myId: id,
        peerId: src,
        session: _session(src),
        send: (b) => router.sendData(src, b),
        maxFrame: () => router.maxFrame,
      ),
    );
    link.onFrame(body);
  }

  GroupSession join(GroupInfo info) {
    groups[info.id] = info;
    final s = GroupSession(
      groupId: info.id,
      groupKey: info.key,
      myId: id,
      myName: profile.name,
      transmit: (b) => router.sendGroup(info.id, b),
      online: () => router.neighborCount > 0,
      chunkSize: 32 * 1024,
      pacing: Duration.zero,
      allowVideo: true,
      maxFileBytes: 8 * 1024 * 1024,
      mediaRoot: root,
    );
    groupSessions[info.id] = s;
    router.announce();
    return s;
  }
}

/// العالم كله: أنا (الهب) + 7 أشخاص + جروبات + محادثات.
class World {
  World._();

  static late WorldPeer salma, mona, basma, hassan, karim, omar, youssef;
  static late GroupChat shilla;
  static late DirectChat monaChat;

  static Future<void> build(ChatHub hub) async {
    final net = MemoryNet();
    final root = await Directory.systemTemp.createTemp('wasl_world_');
    final meLink = net.add(hub.myId)..maxFrame = 200 * 1024;
    await hub.start(TransportKind.wifi, testLink: meLink);

    salma = await WorldPeer.create(net, root, 'سلمى', 7, 4, 1);
    mona = await WorldPeer.create(net, root, 'منى', 2, 6, 2);
    basma = await WorldPeer.create(net, root, 'بسمة', 5, 10, 3);
    hassan = await WorldPeer.create(net, root, 'حسن', 4, 18, 4);
    karim = await WorldPeer.create(net, root, 'كريم', 1, 9, 5);
    omar = await WorldPeer.create(net, root, 'عمر', 6, 16, 6);
    youssef = await WorldPeer.create(net, root, 'يوسف', 3, 13, 7);
    // أنا ← سلمى ومنى مباشرة • بسمة وحسن وكريم عن طريق جهاز • عمر ويوسف عن طريق جهازين
    for (final p in [salma, mona]) {
      net.connect(hub.myId, p.id);
    }
    net.connect(salma.id, basma.id);
    net.connect(mona.id, hassan.id);
    net.connect(mona.id, karim.id);
    net.connect(karim.id, omar.id);
    net.connect(hassan.id, youssef.id);
    await _wait(() => hub.people.length >= 7);

    // الشلة: جروب بكلمة سر، أنا صاحبه وبسمة مديرة
    shilla = await hub.createGroup(name: 'الشلة', mode: GroupMode.password, password: 'سر1234');
    for (final p in [karim, basma, mona, salma]) {
      p.join(await GroupInfo.fromAd(shilla.info.ad, shilla.info.key));
    }
    await _wait(() => shilla.members.length >= 4);
    await hub.setAdmin(shilla, basma.id, true);
    // رحلة الساحل: جروب عام فيه عمر
    final trip = await hub.createGroup(name: 'رحلة الساحل', mode: GroupMode.open);
    omar.join(await GroupInfo.fromAd(trip.info.ad, trip.info.key));
    // سكان العمارة: جروب حوالينا مدخلناهوش (بطلب انضمام)
    hassan.join(await GroupInfo.create(name: 'سكان العمارة', mode: GroupMode.ask, owner: hassan.id));
    await _wait(() => hub.nearbyGroups.isNotEmpty);

    // المحادثات
    final now = DateTime.now();
    DateTime ago(int min) => now.subtract(Duration(minutes: min));
    shilla.session.messages
      ..clear()
      ..addAll([
        ChatMessage(id: 's0', text: 'بسمة بقت مديرة في الجروب', kind: MessageKind.system, time: ago(60)),
        ChatMessage(id: 's1', text: 'يا جماعة هنتقابل الساعة 7 عند الكافيه؟', kind: MessageKind.theirs, sender: 'كريم', senderId: karim.id, time: ago(50))
          ..reactions.addAll({mona.id: '👍', salma.id: '👍', basma.id: '👍'}),
        ChatMessage(id: 's2', text: 'تمام أنا جاية', kind: MessageKind.theirs, sender: 'بسمة', senderId: basma.id, time: ago(48)),
        ChatMessage(id: 's3', text: 'أنا هوصل 7 ونص 🙏', kind: MessageKind.mine, status: MessageStatus.read, time: ago(45))
          ..reactions[karim.id] = '😂',
        ChatMessage(
          id: 's4',
          text: 'مفيش مشكلة، هنستناك',
          kind: MessageKind.theirs,
          sender: 'سلمى',
          senderId: salma.id,
          time: ago(30),
          reply: ReplyInfo(id: 's1', preview: 'يا جماعة هنتقابل الساعة 7 عند الكافيه؟', toMine: false, author: 'كريم', authorId: karim.id),
        ),
        ChatMessage(
          id: 's5',
          text: '@آدم هات معاك الشاحن بتاعي 😅',
          kind: MessageKind.theirs,
          sender: 'منى',
          senderId: mona.id,
          time: ago(2),
          mentions: {hub.myId: 'آدم'},
        )..mentionsMe = true,
      ]);
    shilla
      ..unread = 3
      ..lastActivity = ago(2);
    hub.setPinned(shilla, true);

    monaChat = hub.openDirect(mona.id)!;
    await _wait(() => monaChat.session.state.name == 'ready');
    monaChat.session.messages.addAll([
      ChatMessage(id: 'm1', text: 'إنت فين؟ النت مقطوع هنا خالص', kind: MessageKind.theirs, time: ago(40)),
      ChatMessage(id: 'm2', text: 'وأنا كمان، بس وصل شغال عادي على الواي فاي 😄', kind: MessageKind.mine, status: MessageStatus.read, time: ago(39)),
      ChatMessage(id: 'm3', text: 'حلو جداً. هنجيبي الساعة كام؟', kind: MessageKind.theirs, time: ago(30))..reactions[ChatSession.reactMe] = '❤️',
      ChatMessage(id: 'm4', text: 'كمان ربع ساعة', kind: MessageKind.mine, status: MessageStatus.read, time: ago(28)),
    ]);
    monaChat.lastActivity = ago(28);

    final karimChat = hub.openDirect(karim.id)!;
    karimChat.session.messages.add(ChatMessage(id: 'k1', text: 'تمام يا معلم 👍', kind: MessageKind.mine, status: MessageStatus.read, time: ago(90)));
    karimChat.lastActivity = ago(90);
    final salmaChat = hub.openDirect(salma.id)!;
    salmaChat.session.messages.add(ChatMessage(id: 'l1', text: 'بعتتلك الملف، شوفه لما تفضى', kind: MessageKind.theirs, time: ago(20)));
    salmaChat
      ..unread = 1
      ..lastActivity = ago(20);
    trip.session.messages.add(
      ChatMessage(id: 't1', text: 'الأتوبيس هيتحرك الساعة 6 الصبح', kind: MessageKind.theirs, sender: 'عمر', senderId: omar.id, time: ago(600)),
    );
    trip.lastActivity = ago(600);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> _wait(bool Function() test) async {
    for (var i = 0; i < 200 && !test(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
