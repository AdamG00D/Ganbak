import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganbak/features/games/core/fair_deal.dart';

/// التوزيع العادل: محاكاة لاعبين على موبايل واحد.
void main() {
  test('التشفير التبادلي: الترتيب مش فارق، والمعكوس بيفك', () {
    final r = Random(1);
    final pt = FairDeal.randomPoint(r);
    final a = FairDeal.randomScalar(r), b = FairDeal.randomScalar(r);
    expect(FairDeal.mul(a, FairDeal.mul(b, pt)), FairDeal.mul(b, FairDeal.mul(a, pt)));
    expect(FairDeal.mul(FairDeal.inverse(a), FairDeal.mul(a, pt)), pt);
    expect(FairDeal.dec(FairDeal.enc(pt)), pt);
    expect(FairDeal.dec('zz'), isNull);
  });

  for (final n in [3, 5]) {
    test('توزيعة كاملة لـ $n لاعبين: جاسوس واحد بس، والباقي نفس الكلمة، والكل يتأكد في الآخر', () {
      final rng = Random(n);
      final secrets = [for (var i = 0; i < n; i++) DealSecrets.random(n, rng)];
      final hashes = [for (final s in secrets) FairDeal.hashPoint(s.blank)];
      final boxes = [for (final s in secrets) s.boxes()];
      // 1) الأعمدة
      final cols = [for (final s in secrets) s.column()];
      var m = [for (var r = 0; r < n; r++) [for (var c = 0; c < n; c++) cols[c][r]]];
      // 2) الخلط
      for (var j = 0; j < n; j++) {
        m = secrets[j].mix(m, j, rng);
      }
      // 3) الفك
      for (var j = 0; j < n; j++) {
        m = secrets[j].strip(m, j);
      }
      // 4) كل واحد يفك صفه
      final results = [for (var r = 0; r < n; r++) secrets[r].open(m[r], hashes, boxes)];
      expect(results.every((x) => x != null), isTrue);
      expect(results.where((x) => x!.$1).length, 1, reason: 'جاسوس واحد بالظبط');
      final words = {for (final x in results) if (!x!.$1) dealWord(x.$2, 15)};
      expect(words.length, 1, reason: 'كل غير الجواسيس عندهم نفس الكلمة');
      // 5) التأكد في الآخر
      final check = DealCheck.verify(finalMatrix: m, secrets: secrets, blankHashes: hashes, boxes: boxes, wordCount: 15);
      expect(check, isNotNull);
      expect(results[check!.$1]!.$1, isTrue);
      expect(check.$2, words.single);
      // من برا كل القيم مختلفة (في الصفوف والأعمدة) — محدش يعرف صف الجاسوس
      expect({for (final row in m) ...row}.length, n * n);
    });
  }

  test('لو حد غيّر حاجة في المصفوفة: بيتكشف', () {
    final rng = Random(7);
    const n = 3;
    final secrets = [for (var i = 0; i < n; i++) DealSecrets.random(n, rng)];
    final cols = [for (final s in secrets) s.column()];
    var m = [for (var r = 0; r < n; r++) [for (var c = 0; c < n; c++) cols[c][r]]];
    for (var j = 0; j < n; j++) {
      m = secrets[j].mix(m, j, rng);
    }
    for (var j = 0; j < n; j++) {
      m = secrets[j].strip(m, j);
    }
    m[0][1] = FairDeal.randomPoint(rng);
    final hashes = [for (final s in secrets) FairDeal.hashPoint(s.blank)];
    final boxes = [for (final s in secrets) s.boxes()];
    expect(DealCheck.verify(finalMatrix: m, secrets: secrets, blankHashes: hashes, boxes: boxes, wordCount: 15), isNull);
  });
}
