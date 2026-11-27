import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/crypto/kdf.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/features/mailbox/mailbox.dart';
import 'package:wasl/mesh/mesh_router.dart';

import 'support.dart';

/// "الرسالة تستنى صاحبها" على شبكة وهمية: أحمد يكتب لبسمة وهي مش موجودة، كريم يشيلها،
/// يقابل بسمة فتوصلها، وإيصالها يرجع لأحمد.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('رسالة بتتشال وتتسلّم وإيصالها بيرجع', () async {
    MailService.resendEvery = const Duration(milliseconds: 200);
    final net = MemoryNet();
    final routers = <MeshRouter>[];
    final keys = <String, List<int>>{};
    final got = <String, List<(String, MailMessage)>>{};
    final delivered = <String>[];
    final ticks = <Timer>[];

    Future<(Profile, MeshRouter, MailService)> dev(String name) async {
      final p = await Profile.fromSeed(Kdf.randomBytes(32), name: name, color: 1);
      keys[p.id] = p.publicKey;
      final r = MeshRouter(
        link: net.add(p.id),
        presenceEvery: const Duration(milliseconds: 100),
        nodeTtl: const Duration(seconds: 1),
        describe: () => {'n': p.name, 'c': p.color, 'k': base64.encode(p.publicKey), 's': base64.encode(p.signKey)},
        sign: p.sign,
      );
      final m = MailService(
        router: r,
        me: p.keyPair,
        myKey: p.publicKey,
        mySignKey: p.signKey,
        myId: p.id,
        myName: p.name,
        keyOf: (id) => keys[id],
        onMail: (mail) => got.putIfAbsent(p.id, () => []).add((mail.from, mail)),
        onDelivered: (_, id) => delivered.add(id),
      );
      r
        ..onControl = ((src, msg) => m.receive(src, msg))
        ..addListener(m.flush);
      routers.add(r);
      // زي الـ hub: محاولة كل شوية (هنا بسرعة)
      ticks.add(Timer.periodic(const Duration(milliseconds: 300), (_) => m.flush()));
      await r.start();
      return (p, r, m);
    }

    final (a, ra, ma) = await dev('أحمد');
    final (b, rb, _) = await dev('بسمة');
    final (c, rc, mc) = await dev('كريم');

    // أحمد وكريم مع بعض، وبسمة بعيدة
    net.connect(a.id, c.id);
    await waitFor(() => ra.nodes[c.id]?.hops == 1 && rc.nodes[a.id]?.hops == 1, what: 'أحمد وكريم');
    final id = await ma.send(b.id, b.publicKey, 'أنا جنب الباب الشمال');
    await waitFor(() => mc.carry.items.containsKey(id), what: 'كريم شايل الرسالة');
    expect(got[c.id], isNull, reason: 'كريم مبيقدرش يفتحها');

    // كريم يمشي من عند أحمد ويقابل بسمة
    net.disconnect(a.id, c.id);
    net.connect(c.id, b.id);
    await waitFor(() => (got[b.id] ?? []).isNotEmpty, what: 'بسمة استلمت');
    expect(got[b.id]!.single.$2.text, 'أنا جنب الباب الشمال');
    expect(got[b.id]!.single.$1, a.id);
    expect(delivered, isEmpty, reason: 'أحمد لسه معرفش');

    // أحمد يقرب تاني: الإيصال يوصله عن طريق كريم
    net.connect(a.id, c.id);
    await waitFor(() => delivered.contains(id), what: 'الإيصال رجع لأحمد');
    expect(ma.outbox[b.id], isNull);
    await waitFor(() => rb.nodes.containsKey(a.id));

    for (final t in ticks) {
      t.cancel();
    }
    for (final r in routers) {
      await r.stop();
    }
  });
}
