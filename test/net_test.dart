import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/crypto/kdf.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/features/net/wasl_network.dart';
import 'package:wasl/mesh/mesh_router.dart';

import 'support.dart';

/// "شبكة وصل": عرض الشبكة بيوصل مع "أنا موجود"، واللي بيظهر للمستخدم هو اللي جنبه بس.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('العرض في الإعلان', () {
    test('بيتقري صح، والقيم الغلط بتترمي', () {
      expect(WifiOffer.fromWire({'s': 'DIRECT-ab-Wasl', 'p': 'abcd1234', 'x': 1})?.ssid, 'DIRECT-ab-Wasl');
      expect(WifiOffer.fromWire({'s': 'AndroidShare_1', 'p': 'abcd1234', 'x': 3})?.security, 3);
      expect(WifiOffer.fromWire({'s': 'open', 'p': '', 'x': 0})?.pass, '');
      expect(WifiOffer.fromWire({'s': '', 'p': 'abcd1234'}), isNull);
      expect(WifiOffer.fromWire({'s': 'x' * 33, 'p': 'abcd1234'}), isNull);
      expect(WifiOffer.fromWire({'s': 'net', 'p': 'short'}), isNull, reason: 'WPA محتاج 8 حروف على الأقل');
      expect(WifiOffer.fromWire({'s': 'net', 'p': 'p' * 64}), isNull);
      expect(WifiOffer.fromWire({'s': 'bad\u0000name', 'p': 'abcd1234'}), isNull);
      expect(WifiOffer.fromWire('nope'), isNull);
      expect(WifiOffer.fromWire({'s': 'net', 'p': 'abcd1234', 'x': 9})?.security, 1, reason: 'نوع غريب = WPA2');
    });

    test('الشبكة بتوصل للجيران مع "أنا موجود" وبتختفي لما تتقفل', () async {
      final net = MemoryNet();
      final routers = <MeshRouter>[];
      WifiOffer? offer;
      Future<(Profile, MeshRouter)> dev(String name, {bool host = false}) async {
        final p = await Profile.fromSeed(Kdf.randomBytes(32), name: name, color: 1);
        final r = MeshRouter(
          link: net.add(p.id),
          presenceEvery: const Duration(milliseconds: 100),
          nodeTtl: const Duration(seconds: 5),
          describe: () => {
            'n': p.name,
            'c': p.color,
            'k': base64.encode(p.publicKey),
            if (host) 'w': ?offer?.toWire(),
          },
        );
        routers.add(r);
        await r.start();
        return (p, r);
      }

      final (ha, ra) = await dev('أحمد', host: true);
      final (hb, rb) = await dev('بسمة');
      final (_, rc) = await dev('كريم');
      net.connect(ha.id, hb.id);
      net.connect(hb.id, rc.myId);
      await waitFor(() => rb.nodes.containsKey(ha.id) && rc.nodes.containsKey(ha.id));
      expect(rb.nodes[ha.id]!.wifi, isNull);

      offer = const WifiOffer(ssid: 'AndroidShare_4821', pass: 'k3v9x2m8q1');
      ra.announce();
      await waitFor(() => rb.nodes[ha.id]!.wifi != null && rc.nodes[ha.id]!.wifi != null);
      expect(rb.nodes[ha.id]!.wifi, offer);
      // بسمة جنبه (جار مباشر) فتشوف العرض، كريم بعيد (عن طريق بسمة) فلأ
      expect(WaslNetwork.offersAmong(rb.nodes.values, state: NetState.idle).map((n) => n.id), [ha.id]);
      expect(WaslNetwork.offersAmong(rc.nodes.values, state: NetState.idle), isEmpty);

      offer = null;
      ra.announce();
      await waitFor(() => rb.nodes[ha.id]!.wifi == null);
      for (final r in routers) {
        await r.stop();
        r.dispose();
      }
    });
  });

  group('مين يشوف العرض', () {
    MeshNode node(String id, {WifiOffer? wifi, int hops = 1}) => MeshNode(id, Uint8List(32))
      ..name = id
      ..wifi = wifi
      ..hops = hops;
    const a = WifiOffer(ssid: 'net-a', pass: 'abcd1234');
    const b = WifiOffer(ssid: 'net-b', pass: 'abcd1234');

    test('الجيران المباشرين بس، ومش الشبكة اللي أنا فيها ولا اللي قلت عليها مش دلوقتي', () {
      final nodes = [
        node('aaaaaaaaaaaaaaa1', wifi: a),
        node('aaaaaaaaaaaaaaa2', wifi: b),
        node('aaaaaaaaaaaaaaa3', wifi: a, hops: 2),
        node('aaaaaaaaaaaaaaa4'),
      ];
      expect(WaslNetwork.offersAmong(nodes, state: NetState.idle).length, 2);
      expect(WaslNetwork.offersAmong(nodes, state: NetState.joined, joined: a).single.wifi, b);
      expect(WaslNetwork.offersAmong(nodes, state: NetState.idle, dismissed: {'net-b'}).single.wifi, a);
      // وأنا فاتح شبكة أو بدخل واحدة: مفيش عروض
      expect(WaslNetwork.offersAmong(nodes, state: NetState.hosting), isEmpty);
      expect(WaslNetwork.offersAmong(nodes, state: NetState.joining), isEmpty);
    });
  });
}
