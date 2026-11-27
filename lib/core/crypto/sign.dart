import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// توقيعات Ed25519: الاسم والصورة في "أنا موجود"، ورسايل الجروبات.
///
/// مفتاح التوقيع بيتعمل من نفس بذرة الهوية (HKDF)، ومعرّف الشخص = هاش مفتاح التشفير ومفتاح التوقيع مع بعض
/// (شوف [Profile.idOf])، فمحدش يقدر يحط مفتاح توقيع تاني على معرّف حد.
class Sign {
  Sign._();

  static final Ed25519 _ed = Ed25519();

  static Future<SimpleKeyPair> keyPairFromSeed(List<int> seed32) => _ed.newKeyPairFromSeed(seed32);

  /// توقيع (base64، 64 بايت).
  static Future<String> sign(SimpleKeyPair keyPair, List<int> data) async =>
      base64.encode((await _ed.sign(data, keyPair: keyPair)).bytes);

  /// صح ولا لأ (أي حاجة بايظة = لأ).
  static Future<bool> verify(List<int> publicKey, List<int> data, Object? signature) async {
    if (signature is! String || signature.length > 100 || publicKey.length != 32) return false;
    try {
      final sig = base64.decode(signature);
      if (sig.length != 64) return false;
      return await _ed.verify(
        data,
        signature: Signature(sig, publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519)),
      );
    } catch (_) {
      return false;
    }
  }

  /// مفتاح عام 32 بايت من base64 (أو null).
  static List<int>? key(Object? raw) {
    if (raw is! String || raw.length > 64) return null;
    try {
      final k = base64.decode(raw);
      return k.length == 32 ? k : null;
    } catch (_) {
      return null;
    }
  }
}
