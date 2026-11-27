import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganbak/core/crypto/box.dart';
import 'package:ganbak/core/crypto/kdf.dart';
import 'package:ganbak/core/profile/profile.dart';
import 'package:ganbak/features/chat/core/chat_session.dart';
import 'package:ganbak/features/groups/group.dart';
import 'package:ganbak/features/groups/group_session.dart';
import 'package:ganbak/mesh/mesh_router.dart';

import 'support.dart';

/// الهوية الجديدة: الاسم والصورة موقّعين، ومحدش في الجروب يقدر يبعت باسم حد تاني.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Profile a, b, c;
  late Directory tmp;

  setUpAll(() async {
    a = await Profile.fromSeed(Kdf.randomBytes(32), name: 'أحمد', color: 1);
    b = await Profile.fromSeed(Kdf.randomBytes(32), name: 'بسمة', color: 2);
    c = await Profile.fromSeed(Kdf.randomBytes(32), name: 'كريم', color: 3);
    tmp = await Directory.systemTemp.createTemp('wasl_identity');
  });

  tearDownAll(() => tmp.delete(recursive: true));

  test('المعرّف = هاش المفتاحين، ومفتاح التوقيع ثابت من البذرة', () async {
    expect(a.id, await Profile.idOf(a.publicKey, a.signKey));
    expect(a.id, isNot(await Profile.idOf(a.publicKey, b.signKey)));
  });

  test('إعلان بتوقيع مفتاح تاني بيترفض (حتى لو المعرّف صح)', () async {
    final net = MemoryNet();
    MeshRouter router(Profile p, Future<String> Function(List<int>) sign) => MeshRouter(
          link: net.links[p.id] ?? net.add(p.id),
          presenceEvery: const Duration(milliseconds: 100),
          describe: () => {'n': p.name, 'c': p.color, 'k': base64.encode(p.publicKey), 's': base64.encode(p.signKey)},
          sign: sign,
        );
    final ra = router(a, a.sign);
    final rb = router(b, c.sign); // بسمة بتوقّع بمفتاح كريم
    await ra.start();
    await rb.start();
    net.connect(a.id, b.id);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(ra.nodes.containsKey(b.id), isFalse);
    expect(rb.nodes.containsKey(a.id), isTrue);
    await ra.stop();
    await rb.stop();
  });

  group('الجروب', () {
    late GroupInfo info;
    final sent = <String, List<String>>{};
    final sessions = <String, GroupSession>{};

    GroupSession session(Profile p) => sessions[p.id] = GroupSession(
          groupId: info.id,
          groupKey: info.key,
          myId: p.id,
          myName: p.name,
          transmit: (body) async => sent.putIfAbsent(p.id, () => []).add(body),
          online: () => true,
          chunkSize: 4096,
          pacing: Duration.zero,
          allowVideo: false,
          maxFileBytes: 1024 * 1024,
          mediaRoot: tmp,
          sign: p.sign,
          myBoxKey: base64.encode(p.publicKey),
          mySignKey: base64.encode(p.signKey),
        );

    setUpAll(() async {
      info = await GroupInfo.create(name: 'الشلة', mode: GroupMode.open, owner: a.id);
      session(a);
      session(b);
      session(c);
    });

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 200));

    /// كريم (عضو) بيعمل حزمة بإيده.
    Future<String> forge(Map<String, dynamic> packet, {required Profile signer}) async {
      final inner = jsonEncode(packet);
      final sg = await signer.sign(utf8.encode('wasl/group/v2|${info.id}|$inner'));
      final box = await Box.seal(info.key, utf8.encode(jsonEncode({'p': inner, 'sg': sg})), utf8.encode('wasl/group/v1|${info.id}'));
      return base64.encode(box);
    }

    test('الرسالة الحقيقية بتوصل باسم صاحبها', () async {
      await sessions[a.id]!.send('أهلاً يا جماعة');
      sessions[b.id]!.receive(a.id, sent[a.id]!.last);
      await settle();
      final got = sessions[b.id]!.messages.where((m) => m.kind == MessageKind.theirs).toList();
      expect(got.single.text, 'أهلاً يا جماعة');
      expect(got.single.senderId, a.id);
    });

    test('عضو بيبعت باسم أحمد بمفاتيح أحمد وتوقيعه هو: بتترمي', () async {
      final body = await forge({
        'k': 'msg', 'id': 'x1', 'text': 'ابعتولي فلوس', 'ts': 1, 's': a.id, 'n': 'أحمد',
        'xk': base64.encode(a.publicKey), 'ek': base64.encode(a.signKey),
      }, signer: c);
      sessions[b.id]!.receive(a.id, body);
      await settle();
      expect(sessions[b.id]!.messages.any((m) => m.text == 'ابعتولي فلوس'), isFalse);
    });

    test('عضو بيبعت باسم أحمد بمفاتيحه هو: بتترمي', () async {
      final body = await forge({
        'k': 'msg', 'id': 'x2', 'text': 'رسالة مزيفة', 'ts': 1, 's': a.id, 'n': 'أحمد',
        'xk': base64.encode(c.publicKey), 'ek': base64.encode(c.signKey),
      }, signer: c);
      sessions[b.id]!.receive(a.id, body);
      await settle();
      expect(sessions[b.id]!.messages.any((m) => m.text == 'رسالة مزيفة'), isFalse);
    });

    test('تعديل قديم بيتعاد مبيرجّعش النص القديم', () async {
      final sa = sessions[a.id]!, sb = sessions[b.id]!;
      await sa.send('النسخة الأولى');
      sb.receive(a.id, sent[a.id]!.last);
      await settle();
      final mine = sa.messages.lastWhere((m) => m.kind == MessageKind.mine);
      await sa.edit(mine, 'تعديل 1');
      final first = sent[a.id]!.last;
      await sa.edit(mine, 'تعديل 2');
      final second = sent[a.id]!.last;
      sb.receive(a.id, first);
      sb.receive(a.id, second);
      await settle();
      sb.receive(a.id, first); // كريم بيعيد التعديل القديم
      await settle();
      final theirs = sb.messages.lastWhere((m) => m.kind == MessageKind.theirs && m.senderId == a.id);
      expect(theirs.text, 'تعديل 2');
    });

    test('حزمة من غير توقيع (غير أجزاء الملفات وبيكتب) بتترمي', () async {
      final inner = jsonEncode({
        'k': 'msg', 'id': 'x3', 'text': 'من غير توقيع', 'ts': 1, 's': a.id, 'n': 'أحمد',
        'xk': base64.encode(a.publicKey), 'ek': base64.encode(a.signKey),
      });
      final box = await Box.seal(info.key, utf8.encode(jsonEncode({'p': inner})), utf8.encode('wasl/group/v1|${info.id}'));
      sessions[b.id]!.receive(a.id, base64.encode(box));
      await settle();
      expect(sessions[b.id]!.messages.any((m) => m.text == 'من غير توقيع'), isFalse);
    });
  });
}
