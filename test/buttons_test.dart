import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/widgets/ui.dart';

/// كلام الزراير عمره ما يتقص بـ "…" — لو طويل بينزل سطرين أو يصغر.
void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('زرارين جنب بعض بكلام طويل (خط ×$scale)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const long = 'خلصت تلميحي وعاوز أعدّي الدور للي بعدي';
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.build(AccentTheme.all.first, Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(size: const Size(360, 640), textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: PrimaryButton(label: long, icon: Icons.check_rounded, height: 48, onPressed: () {})),
                    const SizedBox(width: 8),
                    Expanded(child: SecondaryButton(label: 'يلا نصوّت على الجاسوس دلوقتي', height: 48, onPressed: () {})),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      for (final p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
        expect(p.didExceedMaxLines, isFalse, reason: 'كلام مقصوص: ${p.text.toPlainText()}');
      }
    });
  }
}
