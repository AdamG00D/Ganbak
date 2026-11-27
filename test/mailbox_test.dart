import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/crypto/kdf.dart';
import 'package:wasl/core/profile/profile.dart';
import 'package:wasl/features/mailbox/mailbox.dart';

/// "الرسالة تستنى صاحبها": القفل والفتح والإيصال وحدود اللي شايلين الرسايل.
void main() {
  late Profile a, b, c;

  setUpAll(() async {
    a = await Profile.fromSeed(Kdf.randomBytes(32), name: 'أحمد', color: 1);
    b = await Profile.fromSeed(Kdf.randomBytes(32), name: 'بسمة', color: 2);
    c = await Profile.fromSeed(Kdf.randomBytes(32), name: 'كريم', color: 3);
  });

  Future<Envelope> sealAtoB(String text) => MailCrypto.seal(
        me: a.keyPair,
        myKey: a.publicKey,
        myId: a.id,
        myName: a.name,
        to: b.id,
        recipientKey: b.publicKey,
        text: text,
      );

  test('بسمة بس اللي تفتحها، وبتعرف إنها من أحمد', () async {
    final env = await sealAtoB('هستناك عند البوابة');
    final wire = Envelope.fromWire(jsonDecode(jsonEncode(env.toWire())))!;
    final m = await MailCrypto.open(me: b.keyPair, myKey: b.publicKey, myId: b.id, env: wire);
    expect(m?.text, 'هستناك عند البوابة');
    expect(m?.name, 'أحمد');
    // كريم (شايلها في النص) ميقدرش يفتحها
    expect(await MailCrypto.open(me: c.keyPair, myKey: c.publicKey, myId: c.id, env: wire), isNull);
    expect(await MailCrypto.open(me: c.keyPair, myKey: c.publicKey, myId: b.id, env: wire), isNull);
    // المحتوى مش باين في اللي بيتبعت
    expect(jsonEncode(env.toWire()), isNot(contains('البوابة')));
  });

  test('محدش يقدر يبعت باسم حد تاني أو يغيّر الرسالة', () async {
    // كريم بيقفل رسالة لبسمة ويدّعي إنها من أحمد
    final fake = await MailCrypto.seal(
      me: c.keyPair, myKey: c.publicKey, myId: c.id, myName: 'أحمد', to: b.id, recipientKey: b.publicKey, text: 'هات فلوس');
    final forged = Envelope(
        id: fake.id, from: a.id, to: b.id, senderKey: fake.senderKey, ephemeral: fake.ephemeral, box: fake.box);
    expect(await MailCrypto.open(me: b.keyPair, myKey: b.publicKey, myId: b.id, env: forged), isNull);
    // ولو حط مفتاح أحمد: الصندوق ميتفكش (الجزء الثابت محتاج مفتاح أحمد الخاص)
    final forged2 = Envelope(
        id: fake.id, from: a.id, to: b.id, senderKey: base64.encode(a.publicKey), ephemeral: fake.ephemeral, box: fake.box);
    expect(await MailCrypto.open(me: b.keyPair, myKey: b.publicKey, myId: b.id, env: forged2), isNull);
    // تغيير الرقم أو الصندوق
    final env = await sealAtoB('أهلاً');
    final renamed = Envelope(id: 'ffffffffffffffff', from: env.from, to: env.to, senderKey: env.senderKey, ephemeral: env.ephemeral, box: env.box);
    expect(await MailCrypto.open(me: b.keyPair, myKey: b.publicKey, myId: b.id, env: renamed), isNull);
  });

  test('رسالة قديمة (أقدم من 3 أيام) متتقبلش — محدش يعيدها بعد ما ننساها', () async {
    final old = await MailCrypto.seal(
      me: a.keyPair,
      myKey: a.publicKey,
      myId: a.id,
      myName: a.name,
      to: b.id,
      recipientKey: b.publicKey,
      text: 'قديمة',
      at: DateTime.now().subtract(const Duration(days: 4)),
    );
    expect(await MailCrypto.open(me: b.keyPair, myKey: b.publicKey, myId: b.id, env: old), isNull);
    final fresh = await MailCrypto.seal(
      me: a.keyPair,
      myKey: a.publicKey,
      myId: a.id,
      myName: a.name,
      to: b.id,
      recipientKey: b.publicKey,
      text: 'جديدة',
      at: DateTime.now().subtract(const Duration(days: 2)),
    );
    expect((await MailCrypto.open(me: b.keyPair, myKey: b.publicKey, myId: b.id, env: fresh))?.text, 'جديدة');
  });

  test('الإيصال: بسمة بس تقدر تأكد الوصول لأحمد', () async {
    final env = await sealAtoB('أهلاً');
    final r = await MailCrypto.receipt(b.keyPair, b.id, a.publicKey, a.id, env.id);
    expect(await MailCrypto.openReceipt(a.keyPair, a.id, b.publicKey, b.id, env.id, r), env.id);
    // إيصال مزوّر من كريم
    final fake = await MailCrypto.receipt(c.keyPair, c.id, a.publicKey, a.id, env.id);
    expect(await MailCrypto.openReceipt(a.keyPair, a.id, b.publicKey, b.id, env.id, fake), isNull);
  });

  test('رسايل غريبة بتترمي', () {
    expect(Envelope.fromWire({'m': 'zz'}), isNull);
    expect(Envelope.fromWire({'m': '0123456789abcdef', 'f': a.id, 'to': a.id, 'sk': 'x', 'e': 'y', 'c': 'z'}), isNull,
        reason: 'لنفسه');
    expect(Envelope.fromWire({'m': '0123456789abcdef', 'f': a.id, 'to': b.id, 'sk': 'x', 'e': 'y', 'c': 'z' * 20000}), isNull);
  });

  test('اللي شايل رسايل لغيره: حدود للعدد ولكل مرسل وللمدة', () async {
    final box = CarryBox();
    final env = await sealAtoB('1');
    expect(box.add(env), isTrue);
    expect(box.add(env), isFalse, reason: 'مكررة');
    for (var i = 0; i < CarryBox.maxPerSender + 5; i++) {
      box.add(await sealAtoB('$i'));
    }
    expect(box.items.values.where((x) => x.env.from == a.id).length, CarryBox.maxPerSender);
    expect(box.dueFor(b.id).length, CarryBox.maxPerSender);
    expect(box.dueFor(c.id), isEmpty);
    box.prune(DateTime.now().add(const Duration(hours: 49)));
    expect(box.items, isEmpty, reason: 'بعد 48 ساعة بتتشال');
    expect(box.bytes, 0);
  });
}
