import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';

/// عناصر هوية وصل ("الخيامية"): الغرزة، والنقشة، والزينة، وزرار المساعدة.
/// شوف docs/DESIGN.md: إمتى نستخدم كل واحدة (وبحساب — مش في كل حتة).

// ---------------- الغرزة ----------------

/// خط متقطع زي الخياطة: شكل "الاتصال" في التطبيق كله.
class StitchPainter extends CustomPainter {
  StitchPainter({required this.points, required this.color, this.width = 2, this.dash = 6, this.gap = 5});

  /// خط متصل بيعدي على النقط دي بالترتيب.
  final List<Offset> points;
  final Color color;
  final double width;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 1 < points.length; i++) {
      drawStitch(canvas, points[i], points[i + 1], paint, dash: dash, gap: gap);
    }
  }

  static void drawStitch(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 6, double gap = 5}) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final dir = d / len;
    for (var t = 0.0; t < len; t += dash + gap) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + dash, len), paint);
    }
  }

  @override
  bool shouldRepaint(StitchPainter old) => old.points != points || old.color != color;
}

/// غرزة أفقية بين حاجتين (بتاخد المساحة المتاحة).
class StitchLine extends StatelessWidget {
  const StitchLine({super.key, this.color, this.width = 2, this.height = 2});

  final Color? color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.textMuted.withValues(alpha: 0.55);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (_, box) => CustomPaint(
          size: Size(box.maxWidth, height),
          painter: StitchPainter(
            points: [Offset(0, height / 2), Offset(box.maxWidth, height / 2)],
            color: c,
            width: width,
            dash: 5,
            gap: 4,
          ),
        ),
      ),
    );
  }
}

/// إطار متخيّط جوه حواف مستطيل مدوّر (كروت الدعوة، اللوح...).
class StitchBorderPainter extends CustomPainter {
  StitchBorderPainter({required this.color, this.radius = 16, this.inset = 5, this.width = 1.6});

  final Color color;
  final double radius;
  final double inset;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(inset);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(math.max(0, radius - inset))));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var t = 0.0; t < metric.length; t += 10) {
        canvas.drawPath(metric.extractPath(t, math.min(t + 5.5, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(StitchBorderPainter old) => old.color != color || old.radius != radius;
}

/// صندوق بخلفية ولون وغرزة جوه حوافه.
class StitchedBox extends StatelessWidget {
  const StitchedBox({
    super.key,
    required this.child,
    required this.color,
    this.stitch,
    this.radius = 18,
    this.padding = const EdgeInsets.all(14),
    this.pattern = false,
    this.onTap,
  });

  final Widget child;
  final Color color;

  /// لون الغرزة (null = أبيض شفاف أو حبر شفاف حسب الخلفية).
  final Color? stitch;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// نقشة خيامية خفيفة ورا المحتوى.
  final bool pattern;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onColor = Palette.onColor(color);
    final s = stitch ?? onColor.withValues(alpha: 0.38);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          painter: pattern ? KhayamiyaPainter(color: onColor.withValues(alpha: 0.10)) : null,
          foregroundPainter: StitchBorderPainter(color: s, radius: radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ---------------- نقشة الخيامية ----------------

/// نقشة هندسية متكررة: نجمة تمانية (مربعين فوق بعض) + نقطة في النص + مثلثات في الأركان.
class KhayamiyaPainter extends CustomPainter {
  KhayamiyaPainter({required this.color, this.cell = 40, this.stroke = 1.6});

  final Color color;
  final double cell;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fill = Paint()..color = color;
    final half = cell / 2;
    final r = cell * 0.25;
    final corner = cell * 0.13;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final c = Offset(x + half, y + half);
        canvas.drawRect(Rect.fromCenter(center: c, width: r * 2, height: r * 2), line);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2), line);
        canvas.restore();
        canvas.drawCircle(c, cell * 0.06, fill);
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x + corner, y)
            ..lineTo(x, y + corner)
            ..close(),
          fill,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(KhayamiyaPainter old) => old.color != color || old.cell != cell;
}

/// خلفية بالنقشة (بتملا المكان اللي هي فيه).
class KhayamiyaBackground extends StatelessWidget {
  const KhayamiyaBackground({super.key, required this.color, this.cell = 40, this.child});

  final Color color;
  final double cell;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: KhayamiyaPainter(color: color, cell: cell), child: child);
}

// ---------------- الزينة ----------------

/// ألوان مثلثات الزينة بالترتيب.
List<Color> buntingColors(Palette p) => [p.saffron, p.tentRed, p.teal, p.isDark ? const Color(0xFFEEF0FA) : p.ink];

/// زينة رمضان: خيط ومثلثات ملوّنة.
class BuntingPainter extends CustomPainter {
  BuntingPainter({required this.colors, this.flag = 22, this.sag = 10, this.swing = 0, required this.string});

  final List<Color> colors;
  final double flag;

  /// قد إيه الخيط بيهبط في النص.
  final double sag;

  /// ميل المثلثات (للحركة).
  final double swing;
  final Color string;

  @override
  void paint(Canvas canvas, Size size) {
    double yAt(double x) {
      final t = size.width == 0 ? 0 : x / size.width;
      return 2 + sag * math.sin(math.pi * t);
    }

    final stringPaint = Paint()
      ..color = string
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, yAt(0));
    for (var x = 0.0; x <= size.width; x += 6) {
      path.lineTo(x, yAt(x));
    }
    canvas.drawPath(path, stringPaint);
    var i = 0;
    for (var x = flag * 0.2; x + flag <= size.width; x += flag * 1.15) {
      final y0 = yAt(x), y1 = yAt(x + flag);
      final mid = x + flag / 2 + swing * flag * 0.25 * (i.isEven ? 1 : -1);
      final tri = Path()
        ..moveTo(x, y0)
        ..lineTo(x + flag, y1)
        ..lineTo(mid, (y0 + y1) / 2 + flag * 1.05)
        ..close();
      canvas.drawPath(tri, Paint()..color = colors[i % colors.length]);
      i++;
    }
  }

  @override
  bool shouldRepaint(BuntingPainter old) => old.swing != swing || old.colors != colors;
}

/// زينة ثابتة (عرض كامل).
class Bunting extends StatelessWidget {
  const Bunting({super.key, this.height = 36, this.flag = 22, this.sag = 8});

  final double height;
  final double flag;
  final double sag;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: BuntingPainter(colors: buntingColors(p), flag: flag, sag: sag, string: p.textMuted.withValues(alpha: 0.5)),
      ),
    );
  }
}

/// احتفال الكسبان: الزينة بتنزل من فوق الشاشة وبتتمرجح شوية وبعدين بتطلع.
Future<void> celebrate(BuildContext context, {Duration hold = const Duration(milliseconds: 2600)}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final p = context.palette;
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Celebration(palette: p, hold: hold, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.palette, required this.hold, required this.onDone});

  final Palette palette;
  final Duration hold;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.hold + const Duration(milliseconds: 900))
    ..forward().whenComplete(() => widget.onDone());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final top = MediaQuery.paddingOf(context).top;
    final total = _c.duration!.inMilliseconds;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final ms = _c.value * total;
          // بتنزل في 450ms، وبتطلع في آخر 450ms
          final drop = Curves.easeOutBack.transform((ms / 450).clamp(0.0, 1.0));
          final lift = Curves.easeIn.transform(((ms - (total - 450)) / 450).clamp(0.0, 1.0));
          final offset = -90 + 90 * drop - 110 * lift;
          final swing = math.sin(ms / 180) * math.exp(-ms / 1400);
          return Stack(
            children: [
              for (final (dy, sag, flag) in const [(0.0, 18.0, 26.0), (34.0, 12.0, 20.0)])
                Positioned(
                  top: top + offset + dy,
                  left: -8,
                  right: -8,
                  height: 70,
                  child: CustomPaint(
                    painter: BuntingPainter(
                      colors: dy == 0 ? buntingColors(p) : buntingColors(p).reversed.toList(),
                      flag: flag,
                      sag: sag,
                      swing: swing,
                      string: p.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------- زرار المساعدة ----------------

/// زرار "؟" (أو "?" بالإنجليزي) بيفتح صفحة شرح.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.onPressed, this.size = 36, this.onDark = false, this.label});

  final VoidCallback onPressed;
  final double size;

  /// وصف الزرار (الافتراضي "إزاي بتتلعب؟").
  final String? label;

  /// فوق خلفية غامقة (كروت الألعاب).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = onDark ? Colors.white.withValues(alpha: 0.18) : (p.isDark ? p.surfaceAlt : p.ink);
    final fg = onDark ? Colors.white : p.saffron;
    final text = label ?? context.l10n.howToPlay;
    return Semantics(
      button: true,
      label: text,
      child: Tooltip(
        message: text,
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Text(
                  context.l10n.helpMark,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: size * 0.5, height: 1.1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
