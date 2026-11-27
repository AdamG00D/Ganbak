import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as c;

/// توزيع عادل من غير حكم ("mental poker"): محدش — ولا حتى اللي فتح اللعبة — يعرف مين الجاسوس غير الجاسوس نفسه،
/// والكلمة محدش اختارها لوحده.
///
/// التشفير التبادلي: ضرب نقطة على منحنى Curve25519 في رقم سري (e·P). الترتيب مش فارق: e1·(e2·P) = e2·(e1·P)،
/// وبيتفك بالمعكوس (e⁻¹ mod L). بنشتغل بإحداثي u بس (Montgomery ladder) بأرقام كاملة (مش X25519 المقصوص).
///
/// المصفوفة n×n (صف لكل لاعب في الآخر، عمود لكل لاعب من الأول):
///  1. كل لاعب i بيبعت عموده [e·Bᵢ, e·Kᵢ₁, …] (الصف 0 = صف الجاسوس) + بصمة Bᵢ + صناديقه (شوف [DealSecrets]).
///  2. الخلط: لاعب ورا التاني بيحط طبقته على باقي الأعمدة وبيقلّب الصفوف عشوائياً.
///  3. الفك: لاعب ورا التاني بيشيل طبقته من كل الصفوف إلا صفه. الصف r بتاع players[r].
///  4. كل واحد بيفك صفه: كله فاضيات = إنت الجاسوس • غير كده بيفتح الصناديق ويعرف الكلمة.
///  5. في الآخر الكل بيكشف أسراره، وأي موبايل يقدر يتأكد إن فيه صف فاضي واحد بس وإن محدش غش.
class FairDeal {
  FairDeal._();

  static final BigInt p = (BigInt.one << 255) - BigInt.from(19);
  static final BigInt order = (BigInt.one << 252) + BigInt.parse('27742317777372353535851937790883648493');
  static final BigInt _a24 = BigInt.from(121665);
  static final BigInt base = BigInt.from(9);

  /// u(k·P) — Montgomery ladder (RFC 7748) برقم كامل من غير قص.
  static BigInt mul(BigInt k, BigInt u) {
    final x1 = u % p;
    var x2 = BigInt.one, z2 = BigInt.zero, x3 = x1, z3 = BigInt.one;
    var swap = 0;
    for (var t = 254; t >= 0; t--) {
      final kt = ((k >> t) & BigInt.one).toInt();
      swap ^= kt;
      if (swap == 1) {
        final tx = x2;
        x2 = x3;
        x3 = tx;
        final tz = z2;
        z2 = z3;
        z3 = tz;
      }
      swap = kt;
      final a = (x2 + z2) % p, aa = (a * a) % p;
      final b = (x2 - z2) % p, bb = (b * b) % p;
      final e = (aa - bb) % p;
      final cc = (x3 + z3) % p, d = (x3 - z3) % p;
      final da = (d * a) % p, cb = (cc * b) % p;
      final s1 = (da + cb) % p, s2 = (da - cb) % p;
      x3 = (s1 * s1) % p;
      z3 = (x1 * ((s2 * s2) % p)) % p;
      x2 = (aa * bb) % p;
      z2 = (e * ((aa + (_a24 * e) % p) % p)) % p;
    }
    if (swap == 1) {
      final tx = x2;
      x2 = x3;
      x3 = tx;
      final tz = z2;
      z2 = z3;
      z3 = tz;
    }
    if (z2 == BigInt.zero) return BigInt.zero;
    return (x2 * z2.modPow(p - BigInt.two, p)) % p;
  }

  static BigInt randomScalar([Random? rng]) {
    final r = rng ?? Random.secure();
    while (true) {
      var v = BigInt.zero;
      for (var i = 0; i < 32; i++) {
        v = (v << 8) | BigInt.from(r.nextInt(256));
      }
      v %= order;
      if (v > BigInt.one) return v;
    }
  }

  static BigInt inverse(BigInt k) => k.modInverse(order);

  /// نقطة عشوائية في المجموعة (k·G).
  static BigInt randomPoint([Random? rng]) => mul(randomScalar(rng), base);

  static String enc(BigInt u) {
    final b = Uint8List(32);
    var v = u;
    for (var i = 0; i < 32; i++) {
      b[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return base64.encode(b);
  }

  /// من base64 (null لو بايظة أو برا الحدود).
  static BigInt? dec(Object? s) {
    if (s is! String || s.length > 48) return null;
    try {
      final b = base64.decode(s);
      if (b.length != 32) return null;
      var v = BigInt.zero;
      for (var i = 31; i >= 0; i--) {
        v = (v << 8) | BigInt.from(b[i]);
      }
      return v == BigInt.zero || v >= p ? null : v;
    } catch (_) {
      return null;
    }
  }

  static String hashPoint(BigInt u) => c.sha256.convert(utf8.encode('wasl/deal/blank|${enc(u)}')).toString();

  /// مصفوفة من/إلى الشبكة: صفوف من نصوص base64. null لو الشكل غلط.
  static List<List<BigInt>>? matrixFrom(Object? raw, int n) {
    if (raw is! List || raw.length != n) return null;
    final out = <List<BigInt>>[];
    for (final row in raw) {
      if (row is! List || row.length != n) return null;
      final r = <BigInt>[];
      for (final x in row) {
        final v = dec(x);
        if (v == null) return null;
        r.add(v);
      }
      out.add(r);
    }
    return out;
  }

  static List<List<String>> matrixTo(List<List<BigInt>> m) => [for (final r in m) [for (final x in r) enc(x)]];
}

/// أسرار لاعب واحد في توزيعة واحدة (بتفضل على موبايله لحد الكشف في الآخر).
///
/// كل لاعب بيعمل: "فاضية" B، و(n-1) نقط مختلفة Kᵣ (واحدة لكل صف غير صف الجاسوس — عشان محدش يلاقي الصف المختلف
/// من برا)، ورقم سري ω. وبيعلن "صناديق": لكل Kᵣ كود tag(Kᵣ) وقيمة ω ⊕ H(Kᵣ). اللي جاله Kᵣ بس يقدر يفتح الصندوق
/// ويعرف ω، والكلمة = H(ω₁‖…‖ωₙ) — فالجاسوس (اللي جاله فاضيات) ميعرفهاش.
class DealSecrets {
  DealSecrets({required this.e, required this.blank, required this.shares, required this.omega});

  factory DealSecrets.random(int n, [Random? rng]) {
    final r = rng ?? Random.secure();
    return DealSecrets(
      e: FairDeal.randomScalar(r),
      blank: FairDeal.randomPoint(r),
      shares: [for (var i = 1; i < n; i++) FairDeal.randomPoint(r)],
      omega: List.generate(8, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  final BigInt e;
  final BigInt blank;
  final List<BigInt> shares;

  /// جزئي من الكلمة (16 هيكس).
  final String omega;

  BigInt get d => FairDeal.inverse(e);

  Map<String, dynamic> toJson() => {
        'e': e.toRadixString(16),
        'b': FairDeal.enc(blank),
        'k': [for (final k in shares) FairDeal.enc(k)],
        'w': omega,
      };

  static DealSecrets? fromJson(Object? raw, int n) {
    if (raw is! Map) return null;
    final e = BigInt.tryParse('${raw['e']}', radix: 16);
    final b = FairDeal.dec(raw['b']);
    final k = raw['k'], w = raw['w'];
    if (e == null || e <= BigInt.one || e >= FairDeal.order || b == null || k is! List || k.length != n - 1) return null;
    if (w is! String || !RegExp(r'^[0-9a-f]{16}$').hasMatch(w)) return null;
    final shares = <BigInt>[];
    for (final x in k) {
      final v = FairDeal.dec(x);
      if (v == null) return null;
      shares.add(v);
    }
    return DealSecrets(e: e, blank: b, shares: shares, omega: w);
  }

  static String tag(BigInt k) => c.sha256.convert(utf8.encode('wasl/deal/tag|${FairDeal.enc(k)}')).toString().substring(0, 16);

  static String _mask(BigInt k) => c.sha256.convert(utf8.encode('wasl/deal/box|${FairDeal.enc(k)}')).toString().substring(0, 16);

  static String _xor(String a, String b) {
    final out = StringBuffer();
    for (var i = 0; i < a.length; i += 2) {
      final v = int.parse(a.substring(i, i + 2), radix: 16) ^ int.parse(b.substring(i, i + 2), radix: 16);
      out.write(v.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  /// الصناديق اللي بتتعلن: كود ← ω ⊕ H(K).
  Map<String, String> boxes() => {for (final k in shares) tag(k): _xor(omega, _mask(k))};

  /// عمودي: [e·B, e·K₁, …, e·Kₙ₋₁].
  List<BigInt> column() => [FairDeal.mul(e, blank), for (final k in shares) FairDeal.mul(e, k)];

  /// الخلط: طبقتي على كل الأعمدة إلا عمودي، وبعدين تقليب الصفوف.
  List<List<BigInt>> mix(List<List<BigInt>> m, int myColumn, [Random? rng]) {
    final out = [
      for (final row in m)
        [for (var c = 0; c < row.length; c++) c == myColumn ? row[c] : FairDeal.mul(e, row[c])],
    ];
    out.shuffle(rng ?? Random.secure());
    return out;
  }

  /// الفك: بشيل طبقتي من كل الصفوف إلا صفي.
  List<List<BigInt>> strip(List<List<BigInt>> m, int myRow) {
    final inv = d;
    return [
      for (var r = 0; r < m.length; r++)
        r == myRow ? m[r] : [for (final x in m[r]) FairDeal.mul(inv, x)],
    ];
  }

  /// صفي بعد ما الكل شال طبقاته: (جاسوس؟، أجزاء الكلمة ω) — null لو الصف متلخبط (حد غش).
  (bool, List<String>)? open(List<BigInt> row, List<String> blankHashes, List<Map<String, String>> boxes) {
    final inv = d;
    final plain = [for (final x in row) FairDeal.mul(inv, x)];
    if ([for (var c = 0; c < plain.length; c++) FairDeal.hashPoint(plain[c]) == blankHashes[c]].every((b) => b)) {
      return (true, const []);
    }
    final omegas = <String>[];
    for (var c = 0; c < plain.length; c++) {
      final box = boxes[c][tag(plain[c])];
      if (box == null) return null;
      omegas.add(_xor(box, _mask(plain[c])));
    }
    return (false, omegas);
  }
}

/// رقم الكلمة من أجزاء الكل (بترتيب اللاعبين).
int dealWord(List<String> omegas, int count) {
  final h = c.sha256.convert(utf8.encode('wasl/deal/word|${omegas.join('|')}')).bytes;
  var v = 0;
  for (final b in h.take(6)) {
    v = (v << 8) | b;
  }
  return v % count;
}

/// التأكد في الآخر بعد ما الكل كشف أسراره: (صف الجاسوس، الكلمة) — null لو حد غش.
class DealCheck {
  static (int, int)? verify({
    required List<List<BigInt>> finalMatrix,
    required List<DealSecrets> secrets,
    required List<String> blankHashes,
    required List<Map<String, String>> boxes,
    required int wordCount,
  }) {
    final n = secrets.length;
    if (finalMatrix.length != n || blankHashes.length != n || boxes.length != n) return null;
    for (var c = 0; c < n; c++) {
      // اللي اتعلن قبل التوزيع لازم يطابق اللي اتكشف
      if (FairDeal.hashPoint(secrets[c].blank) != blankHashes[c]) return null;
      final mine = secrets[c].boxes();
      if (mine.length != boxes[c].length || mine.entries.any((e) => boxes[c][e.key] != e.value)) return null;
    }
    final used = [for (var c = 0; c < n; c++) <BigInt>{}];
    int? spyRow;
    for (var r = 0; r < n; r++) {
      final plain = [for (final x in finalMatrix[r]) FairDeal.mul(secrets[r].d, x)];
      if ([for (var c = 0; c < n; c++) plain[c] == secrets[c].blank].every((b) => b)) {
        if (spyRow != null) return null;
        spyRow = r;
        continue;
      }
      for (var c = 0; c < n; c++) {
        if (!secrets[c].shares.contains(plain[c]) || !used[c].add(plain[c])) return null;
      }
    }
    if (spyRow == null) return null;
    return (spyRow, dealWord([for (final s in secrets) s.omega], wordCount));
  }
}
