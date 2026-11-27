import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// "بصمة" الشخص: نقشة خيامية صغيرة 4×4 (متماثلة) من معرّفه — والمعرّف هاش مفتاحيه، فكل واحد ليه نقشته.
/// بتساعد العين تفرّق بين اتنين بنفس الاسم؛ التطبيق نفسه بيقارن المعرّف كله.
class Fingerprint extends StatelessWidget {
  const Fingerprint({super.key, required this.id, this.size = 96, this.framed = true});

  /// معرّف الشخص (16 هيكس).
  final String id;
  final double size;
  final bool framed;

  static List<int> _bytes(String id) => [
        for (var i = 0; i + 1 < id.length && i < 16; i += 2) int.tryParse(id.substring(i, i + 2), radix: 16) ?? 0,
      ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = [p.saffron, p.teal, p.tentRed, p.isDark ? const Color(0xFF8C93D9) : p.ink];
    return Semantics(
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(framed ? size * 0.08 : 0),
        decoration: framed
            ? BoxDecoration(
                color: p.isDark ? const Color(0xFF1A1E3A) : const Color(0xFFFBF6EC),
                borderRadius: BorderRadius.circular(size * 0.22),
                border: Border.all(color: p.saffron.withValues(alpha: 0.5), width: size > 40 ? 2 : 1),
              )
            : null,
        child: CustomPaint(painter: _FingerprintPainter(_bytes(id), colors)),
      ),
    );
  }
}

class _FingerprintPainter extends CustomPainter {
  _FingerprintPainter(this.bytes, this.colors);
  final List<int> bytes;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (bytes.length < 8) return;
    final cell = size.width / 4;
    for (var r = 0; r < 4; r++) {
      for (var k = 0; k < 2; k++) {
        final v = bytes[r * 2 + k];
        final paint = Paint()
          ..color = colors[v & 3]
          ..style = (v >> 2) & 1 == 1 ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = cell * 0.12;
        for (final col in [k, 3 - k]) {
          final cx = col * cell + cell / 2, cy = r * cell + cell / 2, h = cell * 0.42;
          canvas.drawPath(
            Path()
              ..moveTo(cx, cy - h)
              ..lineTo(cx + h, cy)
              ..lineTo(cx, cy + h)
              ..lineTo(cx - h, cy)
              ..close(),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FingerprintPainter old) => old.bytes.join() != bytes.join();
}
