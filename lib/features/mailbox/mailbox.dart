import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/crypto/box.dart';
import '../../core/crypto/kdf.dart';
import '../../core/profile/profile.dart';
import '../../mesh/mesh_router.dart';

/// رسالة مقفولة لشخص مش موجود دلوقتي — بتستنى صاحبها ("الرسالة تستنى صاحبها").
///
/// التشفير (زي نمط Noise "X" في اتجاه واحد):
///   المرسل بيعمل مفتاح مؤقت e لكل رسالة.
///   المفتاح = HKDF( X25519(e, R) ‖ X25519(S, R) , "wasl/mailbox/v1", salt = e ‖ S ‖ R )
///   S = مفتاح هوية المرسل الثابت، R = مفتاح هوية المستلم الثابت.
///   الجزء التاني (S×R) بيثبت إن اللي قفلها هو صاحب S فعلاً — محدش يقدر يبعت باسم حد تاني.
///   الصندوق = AES-256-GCM، والـ aad = "wasl/mailbox/v1|من|لمين|رقم الرسالة".
/// اللي شايلين الرسالة في النص بيشوفوا من مين لمين بس (المعرّفات) — مش المحتوى.
class Envelope {
  Envelope({
    required this.id,
    required this.from,
    required this.to,
    required this.senderKey,
    required this.ephemeral,
    required this.box,
  });

  /// رقم الرسالة (عشوائي، 16 هيكس).
  final String id;
  final String from;
  final String to;

  /// مفتاح هوية المرسل الثابت (base64) — المستلم بيتأكد إنه بيتهاش لـ [from].
  final String senderKey;
  final String ephemeral;
  final String box;

  static const maxBox = 12 * 1024;

  Map<String, dynamic> toWire() => {'m': id, 'f': from, 'to': to, 'sk': senderKey, 'e': ephemeral, 'c': box};

  static Envelope? fromWire(Object? raw) {
    if (raw is! Map) return null;
    final m = raw['m'], f = raw['f'], to = raw['to'], sk = raw['sk'], e = raw['e'], c = raw['c'];
    if (m is! String || !RegExp(r'^[0-9a-f]{16}$').hasMatch(m)) return null;
    if (f is! String || to is! String || !MeshRouter.isId(f) || !MeshRouter.isId(to) || f == to) return null;
    if (sk is! String || sk.length > 64 || e is! String || e.length > 64) return null;
    if (c is! String || c.isEmpty || c.length > maxBox) return null;
    return Envelope(id: m, from: f, to: to, senderKey: sk, ephemeral: e, box: c);
  }

  int get size => box.length + 160;
}

/// محتوى الرسالة بعد ما تتفك.
class MailMessage {
  const MailMessage({required this.id, required this.text, required this.sentAt, required this.name});
  final String id;
  final String text;
  final DateTime sentAt;

  /// اسم المرسل وقت ما بعت (للعرض لو مش معروف).
  final String name;
}

class MailCrypto {
  MailCrypto._();

  static const _info = 'wasl/mailbox/v1';

  /// أقدم رسالة بنقبلها (نفس مدة تذكّر الرسايل اللي وصلت، عشان محدش يعيد رسالة قديمة).
  static const maxAge = Duration(days: 3);
  static const maxText = 4000;

  static List<int> _aad(String from, String to, String id) => utf8.encode('$_info|$from|$to|$id');

  static Future<Uint8List> _key(List<int> dh1, List<int> dh2, List<int> e, List<int> s, List<int> r) =>
      Kdf.hkdf([...dh1, ...dh2], _info, salt: [...e, ...s, ...r]);

  /// يقفل رسالة لـ [to] (مفتاحه [recipientKey]).
  static Future<Envelope> seal({
    required SimpleKeyPair me,
    required List<int> myKey,
    required String myId,
    required String myName,
    required String to,
    required List<int> recipientKey,
    required String text,
    DateTime? at,
    Random? rng,
  }) async {
    final r = rng ?? Random.secure();
    final id = List.generate(8, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final x = X25519();
    final eph = await x.newKeyPair();
    final ephPub = (await eph.extractPublicKey()).bytes;
    final remote = SimplePublicKey(recipientKey, type: KeyPairType.x25519);
    final dh1 = await (await x.sharedSecretKey(keyPair: eph, remotePublicKey: remote)).extractBytes();
    final dh2 = await (await x.sharedSecretKey(keyPair: me, remotePublicKey: remote)).extractBytes();
    final key = await _key(dh1, dh2, ephPub, myKey, recipientKey);
    final clipped = text.length > maxText ? text.substring(0, maxText) : text;
    final body = utf8.encode(jsonEncode({
      't': clipped,
      'ts': (at ?? DateTime.now()).millisecondsSinceEpoch,
      'n': myName,
    }));
    final box = await Box.seal(key, body, _aad(myId, to, id));
    return Envelope(
      id: id,
      from: myId,
      to: to,
      senderKey: base64.encode(myKey),
      ephemeral: base64.encode(ephPub),
      box: base64.encode(box),
    );
  }

  /// يفتح رسالة ليّا. null = مش ليّا، أو المرسل مش صاحب المفتاح، أو اتعدلت.
  static Future<MailMessage?> open({
    required SimpleKeyPair me,
    required List<int> myKey,
    required String myId,
    required Envelope env,
  }) async {
    if (env.to != myId) return null;
    try {
      final senderKey = base64.decode(env.senderKey);
      final ephPub = base64.decode(env.ephemeral);
      if (senderKey.length != 32 || ephPub.length != 32) return null;
      // المعرّف لازم يكون هاش المفتاح (محدش ينتحل معرّف غيره)
      if (await Profile.idOf(senderKey) != env.from) return null;
      final x = X25519();
      final dh1 = await (await x.sharedSecretKey(
        keyPair: me,
        remotePublicKey: SimplePublicKey(ephPub, type: KeyPairType.x25519),
      ))
          .extractBytes();
      final dh2 = await (await x.sharedSecretKey(
        keyPair: me,
        remotePublicKey: SimplePublicKey(senderKey, type: KeyPairType.x25519),
      ))
          .extractBytes();
      final key = await _key(dh1, dh2, ephPub, senderKey, myKey);
      final clear = await Box.open(key, base64.decode(env.box), _aad(env.from, env.to, env.id));
      if (clear == null) return null;
      final m = jsonDecode(utf8.decode(clear));
      if (m is! Map) return null;
      final t = m['t'], ts = m['ts'], n = m['n'];
      if (t is! String || t.trim().isEmpty || t.length > maxText) return null;
      // من غير وقت، أو أقدم من اللي بنفتكره (3 أيام): ممكن تكون رسالة قديمة بتتعاد — بنرميها
      if (ts is! num) return null;
      final sent = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
      if (DateTime.now().difference(sent) > maxAge) return null;
      final name = n is String ? Profile.cleanName(n) : '';
      return MailMessage(id: env.id, text: t, sentAt: sent.isAfter(DateTime.now()) ? DateTime.now() : sent, name: name);
    } catch (_) {
      return null;
    }
  }

  /// إيصال "وصلت" من المستلم للمرسل، مقفول بمفتاح مشترك بينهم (محدش غيرهم يقدر يزوّره).
  static Future<String> receipt(SimpleKeyPair me, String myId, List<int> peerKey, String peerId, String mid) async {
    final key = await Box.pairKey(me, peerKey, 'wasl/mailbox-receipt');
    final box = await Box.seal(key, utf8.encode(mid), utf8.encode('wasl/mailbox-receipt|$myId|$peerId|$mid'));
    return base64.encode(box);
  }

  /// المرسل بيتأكد من الإيصال. يرجّع رقم الرسالة أو null.
  static Future<String?> openReceipt(SimpleKeyPair me, String myId, List<int> peerKey, String peerId, String mid, String sealed) async {
    try {
      final key = await Box.pairKey(me, peerKey, 'wasl/mailbox-receipt');
      final clear = await Box.open(key, base64.decode(sealed), utf8.encode('wasl/mailbox-receipt|$peerId|$myId|$mid'));
      if (clear == null) return null;
      final got = utf8.decode(clear);
      return got == mid ? got : null;
    } catch (_) {
      return null;
    }
  }
}

/// رسالة شايلها لحد تاني (مقفولة — مبقدرش أقراها).
class Carried {
  Carried(this.env) : since = DateTime.now();
  final Envelope env;
  final DateTime since;
  int deliveries = 0;
  DateTime? lastTry;
}

/// اللي موبايلي شايله لغيره: حدود عشان محدش يملا الموبايل.
class CarryBox {
  static const maxTotal = 300;
  static const maxPerSender = 30;
  static const maxBytes = 2 * 1024 * 1024;
  static Duration lifetime = const Duration(hours: 48);
  static const maxDeliveries = 3;
  static Duration retryEvery = const Duration(minutes: 5);

  final Map<String, Carried> items = {};
  int _bytes = 0;

  int get bytes => _bytes;

  /// يشيل رسالة. false = مرفوضة (مكررة، أو الحدود اتملت).
  bool add(Envelope env) {
    prune();
    if (items.containsKey(env.id)) return false;
    if (items.length >= maxTotal || _bytes + env.size > maxBytes) return false;
    if (items.values.where((c) => c.env.from == env.from).length >= maxPerSender) return false;
    items[env.id] = Carried(env);
    _bytes += env.size;
    return true;
  }

  void remove(String id) {
    final c = items.remove(id);
    if (c != null) _bytes -= c.env.size;
  }

  void prune([DateTime? now]) {
    final t = now ?? DateTime.now();
    for (final c in items.values.toList()) {
      if (t.difference(c.since) > lifetime || c.deliveries >= maxDeliveries) remove(c.env.id);
    }
  }

  /// الرسايل اللي أقدر أسلّمها لـ [peer] دلوقتي.
  List<Carried> dueFor(String peer, [DateTime? now]) {
    final t = now ?? DateTime.now();
    return [
      for (final c in items.values)
        if (c.env.to == peer && (c.lastTry == null || t.difference(c.lastTry!) >= retryEvery)) c,
    ];
  }
}

/// خدمة "الرسالة تستنى صاحبها" على موبايل واحد: رسايلي المستنية، واللي شايله لغيري، والإيصالات.
///
/// رسايل تحكم (U) — النسخ القديمة بتتجاهلها:
///   {t: mb, m, f, to, sk, e, c}   رسالة مقفولة: لصاحبها، أو لجار مباشر يشيلها
///   {t: mbd, m, d?}               من المستلم: d = إيصال مقفول للمرسل • من غير d = "ارمي نسختك"
///   {t: mbd, m, ok: true}         من المرسل: الإيصال وصل (بطّل تبعته)
class MailService {
  MailService({
    required this.router,
    required this.me,
    required this.myKey,
    required this.myId,
    required this.myName,
    required this.keyOf,
    required this.onMail,
    required this.onDelivered,
    this.isBlocked,
  });

  final MeshRouter router;
  final SimpleKeyPair me;
  final List<int> myKey;
  final String myId;
  String myName;

  /// مفتاح هوية شخص (لو نعرفه) — عشان نتأكد من إيصالاته.
  final List<int>? Function(String id) keyOf;

  /// رسالة وصلتني واتفتحت: (المرسل، مفتاحه، الرسالة).
  final void Function(String from, Uint8List senderKey, MailMessage mail) onMail;

  /// رسالتي وصلت لصاحبها (رقمها).
  final void Function(String peer, String id) onDelivered;
  final bool Function(String id)? isBlocked;

  final CarryBox carry = CarryBox();

  /// رسايلي المستنية: المعرّف ← رسايله.
  final Map<String, List<Envelope>> outbox = {};
  final Map<String, Set<String>> _handedTo = {};
  final Map<String, (String, String)> _pendingReceipts = {};
  final Map<String, DateTime> _seen = {};
  final Map<String, DateTime> _tried = {};

  static const maxPerPeer = 50;
  static const maxSeen = 5000;
  static const maxPendingReceipts = 500;
  static Duration resendEvery = const Duration(seconds: 20);

  /// يقفل رسالة لـ [to] ويحطها في الانتظار. يرجّع رقمها.
  Future<String> send(String to, List<int> key, String text) async {
    final env = await MailCrypto.seal(
      me: me, myKey: myKey, myId: myId, myName: myName, to: to, recipientKey: key, text: text);
    final list = outbox.putIfAbsent(to, () => []);
    if (list.length >= maxPerPeer) list.removeAt(0);
    list.add(env);
    flush();
    return env.id;
  }

  bool _due(String key, Duration every) {
    final now = DateTime.now();
    final last = _tried[key];
    if (last != null && now.difference(last) < every) return false;
    _tried[key] = now;
    return true;
  }

  void _send(String to, Map<String, dynamic> m) => router.sendControl(to, m).catchError((Object _) {});

  /// يسلّم اللي يقدر يتسلّم دلوقتي، ويدّي نسخ لجيرانه المباشرين يشيلوها.
  void flush() {
    carry.prune();
    final neighbours = [for (final n in router.nodes.values) if (n.hops == 1) n.id];
    for (final e in outbox.entries) {
      final peer = e.key;
      for (final env in e.value) {
        if (router.reachable(peer)) {
          if (_due('to|${env.id}', resendEvery)) _send(peer, {'t': 'mb', ...env.toWire()});
          continue;
        }
        final handed = _handedTo.putIfAbsent(env.id, () => {});
        for (final nb in neighbours) {
          if (nb == peer || handed.contains(nb) || handed.length >= 8) continue;
          handed.add(nb);
          _send(nb, {'t': 'mb', ...env.toWire()});
        }
      }
    }
    for (final c in carry.items.values.toList()) {
      final to = c.env.to;
      if (!router.reachable(to)) continue;
      for (final d in carry.dueFor(to)) {
        d
          ..lastTry = DateTime.now()
          ..deliveries += 1;
        _send(to, {'t': 'mb', ...d.env.toWire()});
      }
    }
    for (final e in _pendingReceipts.entries.toList()) {
      final (sender, sealed) = e.value;
      if (router.reachable(sender) && _due('rc|${e.key}', resendEvery)) {
        _send(sender, {'t': 'mbd', 'm': e.key, 'd': sealed});
      }
    }
    final now = DateTime.now();
    _seen.removeWhere((_, t) => now.difference(t) > const Duration(days: 3));
  }

  /// رسالة تحكم من نوع mb / mbd.
  Future<void> receive(String src, Map<String, dynamic> m) async {
    switch (m['t']) {
      case 'mb':
        await _onEnvelope(src, m);
      case 'mbd':
        await _onReceipt(src, m);
    }
  }

  Future<void> _onEnvelope(String src, Map<String, dynamic> m) async {
    final env = Envelope.fromWire(m);
    if (env == null || (isBlocked?.call(env.from) ?? false)) return;
    if (env.to != myId) {
      // بنشيل بس من اللي جنبنا مباشرة (محدش يملا موبايلات بعيدة)، ولو مفتاح المرسل بيتهاش لمعرّفه
      if (router.nodes[src]?.hops != 1) return;
      try {
        if (await Profile.idOf(base64.decode(env.senderKey)) != env.from) return;
      } catch (_) {
        return;
      }
      if (carry.add(env)) flush();
      return;
    }
    if (_seen.containsKey(env.id)) {
      if (src != env.from) _send(src, {'t': 'mbd', 'm': env.id});
      return;
    }
    final mail = await MailCrypto.open(me: me, myKey: myKey, myId: myId, env: env);
    if (mail == null) return;
    _seen[env.id] = DateTime.now();
    if (_seen.length > maxSeen) _seen.remove(_seen.keys.first);
    final senderKey = Uint8List.fromList(base64.decode(env.senderKey));
    onMail(env.from, senderKey, mail);
    if (src != env.from) _send(src, {'t': 'mbd', 'm': env.id});
    final sealed = await MailCrypto.receipt(me, myId, senderKey, env.from, env.id);
    _pendingReceipts[env.id] = (env.from, sealed);
    if (_pendingReceipts.length > maxPendingReceipts) _pendingReceipts.remove(_pendingReceipts.keys.first);
    flush();
  }

  Future<void> _onReceipt(String src, Map<String, dynamic> m) async {
    final mid = m['m'];
    if (mid is! String || !RegExp(r'^[0-9a-f]{16}$').hasMatch(mid)) return;
    if (m['ok'] == true) {
      final p = _pendingReceipts[mid];
      if (p != null && p.$1 == src) _pendingReceipts.remove(mid);
      return;
    }
    final carried = carry.items[mid];
    if (carried != null && carried.env.to == src) carry.remove(mid);
    final d = m['d'];
    final list = outbox[src];
    final key = keyOf(src);
    if (d is! String || d.length > 256 || list == null || key == null) return;
    final ok = await MailCrypto.openReceipt(me, myId, key, src, mid, d);
    if (ok == null) return;
    final i = list.indexWhere((x) => x.id == mid);
    if (i < 0) return;
    list.removeAt(i);
    if (list.isEmpty) outbox.remove(src);
    _handedTo.remove(mid);
    onDelivered(src, mid);
    _send(src, {'t': 'mbd', 'm': mid, 'ok': true});
  }

  void clear() {
    carry.items.clear();
    outbox.clear();
    _handedTo.clear();
    _pendingReceipts.clear();
    _tried.clear();
  }
}
