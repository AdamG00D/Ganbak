import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/crypto/box.dart';
import '../../core/crypto/kdf.dart';
import '../../core/crypto/sign.dart';
import '../../core/profile/profile.dart';
import '../../mesh/mesh_router.dart';

/// رسالة مقفولة لشخص مش موجود دلوقتي ("الرسالة تستنى صاحبها") — الإصدار 2: الظرف مفيهوش لا مرسل ولا مستلم.
///
/// التشفير (زي نمط Noise "X"): المرسل S بيعمل مفتاح مؤقت e لكل رسالة، والمستلم R.
///   k1 = HKDF(X25519(e,R), "wasl/mailbox/v2/hdr", salt e‖R)        → h = AES-GCM(k1, {f, sk, ek})  (مين المرسل)
///   k2 = HKDF(X25519(e,R) ‖ X25519(S,R), "wasl/mailbox/v2", salt e‖S‖R) → c = AES-GCM(k2, {t, ts, n, to} + حشو)
/// المستلم بس يقدر يفتح h (محتاج مفتاح R الخاص)، والجزء S×R بيثبت إن المرسل صاحب S فعلاً. اللي شايل الظرف بيشوف
/// رقم عشوائي وحجم ثابت تقريباً — ميعرفش من مين ولا لمين.
class Envelope {
  Envelope({required this.id, required this.ephemeral, required this.header, required this.box, this.hops = 0});

  /// رقم الرسالة (عشوائي، 16 هيكس).
  final String id;
  final String ephemeral;
  final String header;
  final String box;

  /// عدد المرات اللي اتسلّمت فيها من شايل لشايل (بيحد انتشارها).
  int hops;

  static const maxBox = 12 * 1024;
  static const maxHops = 3;

  Map<String, dynamic> toWire() => {'v': 2, 'm': id, 'e': ephemeral, 'h': header, 'c': box, 'hp': hops};

  static Envelope? fromWire(Object? raw) {
    if (raw is! Map || raw['v'] != 2) return null;
    final m = raw['m'], e = raw['e'], h = raw['h'], c = raw['c'], hp = raw['hp'];
    if (m is! String || !RegExp(r'^[0-9a-f]{16}$').hasMatch(m)) return null;
    if (e is! String || e.length > 64 || h is! String || h.isEmpty || h.length > 400) return null;
    if (c is! String || c.isEmpty || c.length > maxBox) return null;
    final hops = hp is int ? hp : 0;
    if (hops < 0 || hops > maxHops) return null;
    return Envelope(id: m, ephemeral: e, header: h, box: c, hops: hops);
  }

  int get size => box.length + header.length + 120;
}

/// محتوى الرسالة بعد ما تتفك.
class MailMessage {
  const MailMessage({
    required this.id,
    required this.from,
    required this.senderKey,
    required this.signKey,
    required this.text,
    required this.sentAt,
    required this.name,
  });
  final String id;
  final String from;
  final Uint8List senderKey;
  final Uint8List signKey;
  final String text;
  final DateTime sentAt;

  /// اسم المرسل وقت ما بعت (للعرض لو مش معروف).
  final String name;
}

class MailCrypto {
  MailCrypto._();

  static const maxText = 4000;
  static const _info = 'wasl/mailbox/v2';

  /// أقدم رسالة بنقبلها (نفس مدة تذكّر الرسايل اللي وصلت، عشان محدش يعيد رسالة قديمة).
  static const maxAge = Duration(days: 3);

  static List<int> _hdrAad(String id) => utf8.encode('$_info/hdr|$id');
  static List<int> _aad(String from, String to, String id) => utf8.encode('$_info|$from|$to|$id');

  static Future<List<int>> _dh(SimpleKeyPair kp, List<int> pub) async =>
      (await X25519().sharedSecretKey(keyPair: kp, remotePublicKey: SimplePublicKey(pub, type: KeyPairType.x25519)))
          .extractBytes();

  /// يقفل رسالة لـ [to] (مفتاحه [recipientKey]).
  static Future<Envelope> seal({
    required SimpleKeyPair me,
    required List<int> myKey,
    required List<int> mySignKey,
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
    final eph = await X25519().newKeyPair();
    final ephPub = (await eph.extractPublicKey()).bytes;
    final dh1 = await _dh(eph, recipientKey);
    final dh2 = await _dh(me, recipientKey);
    final k1 = await Kdf.hkdf(dh1, '$_info/hdr', salt: [...ephPub, ...recipientKey]);
    final k2 = await Kdf.hkdf([...dh1, ...dh2], _info, salt: [...ephPub, ...myKey, ...recipientKey]);
    final header = await Box.seal(
      k1,
      utf8.encode(jsonEncode({'f': myId, 'sk': base64.encode(myKey), 'ek': base64.encode(mySignKey)})),
      _hdrAad(id),
    );
    final clipped = text.length > maxText ? text.substring(0, maxText) : text;
    final body = SizePad.pad({
      't': clipped,
      'ts': (at ?? DateTime.now()).millisecondsSinceEpoch,
      'n': myName,
      'to': to,
    });
    final box = await Box.seal(k2, utf8.encode(body), _aad(myId, to, id));
    return Envelope(id: id, ephemeral: base64.encode(ephPub), header: base64.encode(header), box: base64.encode(box));
  }

  /// يفتح رسالة لو ليّا. null = مش ليّا، أو المرسل مش صاحب مفاتيحه، أو اتعدلت، أو قديمة.
  static Future<MailMessage?> open({
    required SimpleKeyPair me,
    required List<int> myKey,
    required String myId,
    required Envelope env,
  }) async {
    try {
      final ephPub = base64.decode(env.ephemeral);
      if (ephPub.length != 32) return null;
      final dh1 = await _dh(me, ephPub);
      final k1 = await Kdf.hkdf(dh1, '$_info/hdr', salt: [...ephPub, ...myKey]);
      final hdr = await Box.open(k1, base64.decode(env.header), _hdrAad(env.id));
      if (hdr == null) return null; // مش ليّا
      final h = jsonDecode(utf8.decode(hdr));
      if (h is! Map) return null;
      final from = h['f'], sk = Sign.key(h['sk']), ek = Sign.key(h['ek']);
      if (from is! String || !MeshRouter.isId(from) || from == myId || sk == null || ek == null) return null;
      // المعرّف لازم يكون هاش المفتاحين (محدش ينتحل معرّف غيره)
      if (await Profile.idOf(sk, ek) != from) return null;
      final dh2 = await _dh(me, sk);
      final k2 = await Kdf.hkdf([...dh1, ...dh2], _info, salt: [...ephPub, ...sk, ...myKey]);
      final clear = await Box.open(k2, base64.decode(env.box), _aad(from, myId, env.id));
      if (clear == null) return null;
      final m = jsonDecode(utf8.decode(clear));
      if (m is! Map) return null;
      final t = m['t'], ts = m['ts'], n = m['n'];
      if (m['to'] != myId || t is! String || t.trim().isEmpty || t.length > maxText) return null;
      // من غير وقت، أو أقدم من اللي بنفتكره (3 أيام): ممكن تكون رسالة قديمة بتتعاد — بنرميها
      if (ts is! int) return null;
      final sent = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(sent) > maxAge) return null;
      return MailMessage(
        id: env.id,
        from: from,
        senderKey: Uint8List.fromList(sk),
        signKey: Uint8List.fromList(ek),
        text: t,
        sentAt: sent.isAfter(DateTime.now()) ? DateTime.now() : sent,
        name: n is String ? Profile.cleanName(n) : '',
      );
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

/// رسالة شايلها لحد تاني (مقفولة — مبقدرش أقراها ولا أعرف لمين).
class Carried {
  Carried(this.env, this.via) : since = DateTime.now();
  final Envelope env;

  /// الجار اللي اداهاني (مبنرجعهاش له).
  final String via;
  final DateTime since;

  /// الجيران اللي عرضتها عليهم.
  final Set<String> offeredTo = {};
}

/// اللي موبايلي شايله لغيره: حدود عشان محدش يملا الموبايل.
class CarryBox {
  static const maxTotal = 300;

  /// من نفس الجار (المرسل مش معروف للشايل، فالحد على اللي سلّمني).
  static const maxPerNeighbour = 30;
  static const maxBytes = 2 * 1024 * 1024;
  static Duration lifetime = const Duration(hours: 48);

  /// بعرض الرسالة الواحدة على كام جار بالكتير.
  static const maxOffers = 12;

  final Map<String, Carried> items = {};
  int _bytes = 0;

  int get bytes => _bytes;

  /// يشيل رسالة. false = مرفوضة (مكررة، أو الحدود اتملت).
  bool add(Envelope env, String via) {
    prune();
    if (items.containsKey(env.id)) return false;
    if (items.length >= maxTotal || _bytes + env.size > maxBytes) return false;
    if (items.values.where((c) => c.via == via).length >= maxPerNeighbour) return false;
    items[env.id] = Carried(env, via);
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
      if (t.difference(c.since) > lifetime || c.offeredTo.length >= maxOffers) remove(c.env.id);
    }
  }

  /// الرسايل اللي لسه معرضتهاش على [neighbour].
  List<Carried> offersFor(String neighbour) => [
        for (final c in items.values)
          if (c.via != neighbour && !c.offeredTo.contains(neighbour) && c.env.hops < Envelope.maxHops) c,
      ];
}

/// خدمة "الرسالة تستنى صاحبها" على موبايل واحد: رسايلي المستنية، واللي شايله لغيري، والإيصالات.
///
/// رسايل تحكم (U) — بتمشي بالأكواد السرية زي باقي الرسايل الخاصة:
///   {t: mb, v: 2, m, e, h, c, hp}  ظرف: لصاحبه لو موجود، أو لجار مباشر يشيله ويعرضه على اللي يقابله
///   {t: mbd, m, d}                 من المستلم للمرسل: إيصال مقفول
///   {t: mbd, m, ok: true}          من المرسل: الإيصال وصل (بطّل تبعته)
class MailService {
  MailService({
    required this.router,
    required this.me,
    required this.myKey,
    required this.mySignKey,
    required this.myId,
    required this.myName,
    required this.keyOf,
    required this.onMail,
    required this.onDelivered,
    this.isBlocked,
    this.accept,
  });

  final MeshRouter router;
  final SimpleKeyPair me;
  final List<int> myKey;
  final List<int> mySignKey;
  final String myId;
  String myName;

  /// مفتاح هوية شخص (لو نعرفه) — عشان نتأكد من إيصالاته.
  final List<int>? Function(String id) keyOf;

  /// رسالة وصلتني واتفتحت.
  final void Function(MailMessage mail) onMail;

  /// رسالتي وصلت لصاحبها (رقمها).
  final void Function(String peer, String id) onDelivered;
  final bool Function(String id)? isBlocked;

  /// أقبل رسايل من الشخص ده؟ (الافتراضي في التطبيق: من الناس اللي أعرفهم بس)
  final bool Function(String id)? accept;

  final CarryBox carry = CarryBox();

  /// رسايلي المستنية: المعرّف ← رسايله.
  final Map<String, List<Envelope>> outbox = {};
  final Map<String, Set<String>> _handedTo = {};
  final Map<String, (String, String)> _pendingReceipts = {};
  final Map<String, DateTime> _seen = {};
  final Map<String, DateTime> _tried = {};

  /// أظرف جربت أفتحها ومطلعتش ليّا (منجربهاش تاني).
  final Set<String> _notMine = {};

  /// كام ظرف حاولت أفتحه من كل جار في الدقيقة دي (محدش يشغّل موبايلي على الفاضي).
  final Map<String, (int, int)> _opens = {};

  static const maxPerPeer = 50;
  static const maxSeen = 5000;
  static const maxPendingReceipts = 500;
  static const maxOpensPerMinute = 60;
  static Duration resendEvery = const Duration(seconds: 20);

  /// يقفل رسالة لـ [to] ويحطها في الانتظار. يرجّع رقمها.
  Future<String> send(String to, List<int> key, String text) async {
    final env = await MailCrypto.seal(
      me: me,
      myKey: myKey,
      mySignKey: mySignKey,
      myId: myId,
      myName: myName,
      to: to,
      recipientKey: key,
      text: text,
    );
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

  /// يسلّم اللي يقدر يتسلّم، ويدّي نسخ للجيران المباشرين، ويعرض اللي شايله على اللي قابلهم.
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
          if (handed.contains(nb) || handed.length >= 8) continue;
          handed.add(nb);
          _send(nb, {'t': 'mb', ...env.toWire()});
        }
      }
    }
    // اللي شايله لغيري: بعرضه على كل جار جديد (مبعرفش هو لمين — صاحبه بس اللي هيعرف)
    for (final nb in neighbours) {
      for (final c in carry.offersFor(nb)) {
        c.offeredTo.add(nb);
        _send(nb, {'t': 'mb', ...c.env.toWire(), 'hp': c.env.hops + 1});
      }
    }
    for (final e in _pendingReceipts.entries.toList()) {
      final (sender, sealed) = e.value;
      if (router.reachable(sender) && _due('rc|${e.key}', resendEvery)) {
        _send(sender, {'t': 'mbd', 'm': e.key, 'd': sealed});
      }
    }
    final now = DateTime.now();
    _seen.removeWhere((_, t) => now.difference(t) > MailCrypto.maxAge);
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

  bool _canOpen(String src) {
    final minute = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final (at, n) = _opens[src] ?? (minute, 0);
    final count = at == minute ? n + 1 : 1;
    _opens[src] = (minute, count);
    if (_opens.length > 500) _opens.remove(_opens.keys.first);
    return count <= maxOpensPerMinute;
  }

  Future<void> _onEnvelope(String src, Map<String, dynamic> m) async {
    final env = Envelope.fromWire(m);
    if (env == null || _seen.containsKey(env.id) || carry.items.containsKey(env.id)) return;
    if (!_notMine.contains(env.id) && _canOpen(src)) {
      final mail = await MailCrypto.open(me: me, myKey: myKey, myId: myId, env: env);
      if (mail != null) {
        _seen[env.id] = DateTime.now();
        if (_seen.length > maxSeen) _seen.remove(_seen.keys.first);
        if ((isBlocked?.call(mail.from) ?? false) || !(accept?.call(mail.from) ?? true)) return;
        onMail(mail);
        final sealed = await MailCrypto.receipt(me, myId, mail.senderKey, mail.from, env.id);
        _pendingReceipts[env.id] = (mail.from, sealed);
        if (_pendingReceipts.length > maxPendingReceipts) _pendingReceipts.remove(_pendingReceipts.keys.first);
        flush();
        return;
      }
      _notMine.add(env.id);
      if (_notMine.length > maxSeen) _notMine.remove(_notMine.first);
    }
    // مش ليّا: بشيله بس لو من جار مباشر ولسه مسافرش كتير
    if (router.nodes[src]?.hops != 1 || env.hops > Envelope.maxHops) return;
    if (carry.add(env, src)) flush();
  }

  Future<void> _onReceipt(String src, Map<String, dynamic> m) async {
    final mid = m['m'];
    if (mid is! String || !RegExp(r'^[0-9a-f]{16}$').hasMatch(mid)) return;
    if (m['ok'] == true) {
      final p = _pendingReceipts[mid];
      if (p != null && p.$1 == src) _pendingReceipts.remove(mid);
      return;
    }
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
    _notMine.clear();
    _opens.clear();
  }
}
