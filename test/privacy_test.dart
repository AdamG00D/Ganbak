import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/crypto/box.dart';
import 'package:wasl/core/crypto/kdf.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/mesh/mesh_router.dart';
import 'package:wasl/mesh/route_tags.dart';

import 'support.dart';

/// الخصوصية: اللي في النص ميعرفش مين بيكلم مين، وحجم الرسايل ثابت.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('الحشو: الأحجام بتبقى ثابتة', () {
    for (final n in [1, 50, 200, 1000, 3000, 9000]) {
      final m = {'k': 'msg', 'text': 'x' * n};
      final len = utf8.encode(SizePad.pad(m)).length;
      expect([256, 1024, 4096, 12288].contains(len), isTrue, reason: '$n → $len');
      expect(jsonDecode(SizePad.pad(m))['text'], 'x' * n);
    }
  });

  test('الرسايل الخاصة بتعدّي بأكواد سرية، والوسيط مبيشوفش المعرّفات', () async {
    final net = MemoryNet();
    final profiles = <String, Profile>{};
    final routers = <String, MeshRouter>{};
    final got = <String, List<String>>{};

    Future<Profile> dev(String name) async {
      final p = await Profile.fromSeed(Kdf.randomBytes(32), name: name, color: 1);
      profiles[p.id] = p;
      final r = MeshRouter(
        link: net.add(p.id),
        presenceEvery: const Duration(milliseconds: 100),
        nodeTtl: const Duration(seconds: 5),
        describe: () => {'n': p.name, 'c': 1, 'k': base64.encode(p.publicKey), 's': base64.encode(p.signKey), 'pr': 1},
        sign: p.sign,
      );
      r.tags = RouteTags(
        myId: p.id,
        pairKey: (peer) async {
          final key = r.nodes[peer]?.publicKey;
          return key == null ? null : Box.pairKey(p.keyPair, key, 'wasl/route/v1');
        },
      );
      r
        ..onRoutesChanged = (() => r.tags!.refresh([for (final n in r.nodes.values) if (n.privateRoutes) n.id]))
        ..onData = ((src, body) => got.putIfAbsent(p.id, () => []).add('$src:$body'));
      routers[p.id] = r;
      await r.start();
      return p;
    }

    final a = await dev('أحمد'), b = await dev('بسمة'), c = await dev('كريم');
    // أحمد — بسمة — كريم (بسمة في النص)
    final seen = <String>[];
    final lb = net.links[b.id]!;
    final orig = lb.onFrame!;
    lb.onFrame = (l, f) {
      seen.add(f);
      orig(l, f);
    };
    net.connect(a.id, b.id);
    net.connect(b.id, c.id);
    await waitFor(() => routers[a.id]!.nodes[c.id]?.privateRoutes == true && routers[c.id]!.nodes[a.id]?.privateRoutes == true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await routers[a.id]!.sendData(c.id, 'سر');
    await waitFor(() => (got[c.id] ?? []).isNotEmpty, what: 'كريم استلم');
    expect(got[c.id]!.single, '${a.id}:سر', reason: 'كريم بيعرف إنها من أحمد');
    final data = seen.where((f) => f.startsWith('D|')).toList();
    expect(data, isNotEmpty);
    for (final f in data) {
      expect(f.contains(a.id), isFalse, reason: 'معرّف أحمد ظاهر للوسيط');
      expect(f.contains(c.id), isFalse, reason: 'معرّف كريم ظاهر للوسيط');
    }
    expect(got[b.id], isNull, reason: 'الوسيط مستلمش حاجة');
    for (final r in routers.values) {
      await r.stop();
    }
  });
}
