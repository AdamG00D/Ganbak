import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../core/crypto/kdf.dart';

/// أكواد سرية بدل المعرّفات في الرسايل الخاصة (D) ورسايل التحكم (U): اللي في النص ميعرفش مين بيكلم مين.
///
/// لكل اتنين مفتاح مشترك (X25519 بين مفاتيحهم الثابتة). كود الشخص X في فترة e (كل 10 دقايق):
///   tag(X, e) = أول 8 بايت من HMAC-SHA256(مفتاح الاتنين، "wasl/route/v1|" + X + "|" + e)، هيكس
/// الإطار من A لـ B: المصدر = tag(A, e) والوجهة = tag(B, e). شكله زي المعرّف (16 هيكس)، فالنسخ القديمة بتوصّله عادي.
/// الأكواد بتتغير كل فترة، فمحدش يقدر يربط محادثة دلوقتي بمحادثة بعدها.
class RouteTags {
  RouteTags({required this.myId, required this.pairKey});

  final String myId;

  /// المفتاح المشترك مع [peer] (null = معرفناش مفتاحه).
  final Future<List<int>?> Function(String peer) pairKey;

  static const epochLength = Duration(minutes: 10);

  /// أكوادي (الوجهة) ← الشخص.
  final Map<String, String> _mine = {};

  /// أكوادهم (المصدر) ← الشخص.
  final Map<String, String> _theirs = {};

  /// الأكواد المحسوبة لكل شخص (عشان نمسحها لما يمشي).
  final Map<String, List<String>> _byPeer = {};
  int _epochDone = -1;
  final Set<String> _done = {};

  static int epochAt(DateTime t) => t.millisecondsSinceEpoch ~/ epochLength.inMilliseconds;

  static Future<String> tag(List<int> key, String who, int epoch) async {
    final mac = await Hmac.sha256().calculateMac(utf8.encode('wasl/route/v1|$who|$epoch'), secretKey: SecretKey(key));
    return Kdf.hex(mac.bytes.sublist(0, 8));
  }

  bool isMine(String dst) => _mine.containsKey(dst);

  /// الشخص اللي بعت بالكود ده (لو إحنا اللي مستنيينه).
  String? peerOf(String srcTag, String dstTag) {
    final peer = _theirs[srcTag];
    return peer != null && _mine[dstTag] == peer ? peer : null;
  }

  /// الكودين للإرسال لـ [peer] دلوقتي (المصدر، الوجهة) — null لو معرفناش مفتاحه.
  Future<(String, String)?> outgoing(String peer, [DateTime? now]) async {
    final key = await pairKey(peer);
    if (key == null) return null;
    final e = epochAt(now ?? DateTime.now());
    return (await tag(key, myId, e), await tag(key, peer, e));
  }

  /// يحسب أكواد الناس دول للفترة اللي فاتت والحالية واللي جاية (فرق الساعات بين الموبايلات).
  Future<void> refresh(Iterable<String> peers, [DateTime? now]) async {
    final e = epochAt(now ?? DateTime.now());
    if (e != _epochDone) {
      _mine.clear();
      _theirs.clear();
      _byPeer.clear();
      _done.clear();
      _epochDone = e;
    }
    final wanted = peers.toSet();
    for (final gone in _byPeer.keys.where((p) => !wanted.contains(p)).toList()) {
      for (final t in _byPeer.remove(gone)!) {
        _mine.remove(t);
        _theirs.remove(t);
      }
      _done.remove(gone);
    }
    for (final peer in wanted) {
      if (_done.contains(peer)) continue;
      final key = await pairKey(peer);
      if (key == null || _epochDone != e) continue;
      final tags = <String>[];
      for (final x in [e - 1, e, e + 1]) {
        final mine = await tag(key, myId, x), theirs = await tag(key, peer, x);
        _mine[mine] = peer;
        _theirs[theirs] = peer;
        tags.addAll([mine, theirs]);
      }
      _byPeer[peer] = tags;
      _done.add(peer);
    }
  }
}
