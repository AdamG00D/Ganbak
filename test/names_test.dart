import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganbak/core/profile/names.dart';
import 'package:ganbak/core/theme/app_theme.dart';
import 'package:ganbak/widgets/fingerprint.dart';

/// مقارنة الأسامي للتحذير، ورسم البصمة.
void main() {
  test('نفس الاسم حتى لو اتكتب بشكل تاني', () {
    expect(NameMatch.same('آمال', 'امال'), isTrue);
    expect(NameMatch.same('أحمد', 'احمد'), isTrue);
    expect(NameMatch.same('مُنى', 'منى'), isTrue, reason: 'تشكيل');
    expect(NameMatch.same('سلمى', 'سلمي'), isTrue);
    expect(NameMatch.same('فاطمة', 'فاطمه'), isTrue);
    expect(NameMatch.same('كـريم', 'كريم'), isTrue, reason: 'تطويل');
    expect(NameMatch.same('Ziad', 'ziad '), isTrue);
    expect(NameMatch.same('Аmal', 'Amal'), isTrue, reason: 'A روسي');
    expect(NameMatch.same('Zi\u200Bad', 'Ziad'), isTrue, reason: 'حرف مخفي');
    expect(NameMatch.same('\u202Eلامآ', 'لامآ'), isTrue, reason: 'علامة اتجاه');
    expect(NameMatch.same('آمال', 'أحمد'), isFalse);
    expect(NameMatch.same('', ''), isFalse, reason: 'الفاضي مش اسم');
  });

  testWidgets('البصمة بتترسم ومبتوقعش مع معرّف بايظ', (tester) async {
    for (final id in ['0123456789abcdef', 'zz', '']) {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.build(AccentTheme.all.first, Brightness.light),
        home: Scaffold(body: Center(child: Fingerprint(id: id))),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
