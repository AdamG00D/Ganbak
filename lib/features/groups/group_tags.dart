import 'dart:convert';

import 'package:crypto/crypto.dart' as c;

import '../../core/crypto/kdf.dart';

/// العضوية المخفية في الجروبات الخاصة (بكلمة سر / بطلب انضمام): العضو العادي مبيعلنش اسم الجروب ولا رقمه،
/// بيعلن كود سري الأعضاء بس يعرفوه — ومختلف لكل عضو وبيتغير كل 10 دقايق، فاللي برا ميعرفش مين مع مين.
///   tag = أول 8 بايت من HMAC-SHA256(مفتاح الجروب، "wasl/group-tag/v1|" + معرّف العضو + "|" + الفترة)
/// وبصمة حالة الإدارة (digest) بتتبعت متغطية: XOR مع HMAC(مفتاح الجروب، "wasl/group-digest/v1|" + tag).
/// صاحب الجروب والمديرين بس اللي بيعلنوا الجروب عادي (عشان اللي عايز يدخل يلاقيه).
class GroupTags {
  GroupTags._();

  static const epochLength = Duration(minutes: 10);

  static int epochAt(DateTime t) => t.millisecondsSinceEpoch ~/ epochLength.inMilliseconds;

  static final Map<String, String> _memo = {};
  static int _memoEpoch = -1;

  static String tag(List<int> key, String member, int epoch) {
    final now = epochAt(DateTime.now());
    if (now != _memoEpoch) {
      _memo.clear();
      _memoEpoch = now;
    }
    final k = '${base64.encode(key)}|$member|$epoch';
    return _memo[k] ??= Kdf.hex(
      c.Hmac(c.sha256, key).convert(utf8.encode('wasl/group-tag/v1|$member|$epoch')).bytes.sublist(0, 8),
    );
  }

  /// [member] بيعلن الجروب ده دلوقتي؟ (الفترة اللي فاتت والحالية واللي جاية — فرق الساعات)
  static bool matches(List<int> key, String member, String announced, [DateTime? now]) {
    final e = epochAt(now ?? DateTime.now());
    return announced == tag(key, member, e) || announced == tag(key, member, e - 1) || announced == tag(key, member, e + 1);
  }

  static String _xor(List<int> key, String tag, String hex) {
    final mask = c.Hmac(c.sha256, key).convert(utf8.encode('wasl/group-digest/v1|$tag')).bytes;
    final out = StringBuffer();
    for (var i = 0; i + 1 < hex.length && i ~/ 2 < mask.length; i += 2) {
      final b = int.tryParse(hex.substring(i, i + 2), radix: 16) ?? 0;
      out.write((b ^ mask[i ~/ 2]).toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  static String hideDigest(List<int> key, String tag, String digest) => _xor(key, tag, digest);
  static String showDigest(List<int> key, String tag, String hidden) => _xor(key, tag, hidden);
}
