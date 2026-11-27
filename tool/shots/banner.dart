import 'package:flutter/material.dart';
import 'package:wasl/widgets/cartoon_avatar.dart';
import 'package:wasl/widgets/identity.dart';

/// بانر الـ README (1280×640): شبكة أفاتارات متخيّطة على حبر الليل بنقشة خيامية + الاسم والشعار.
class ReadmeBanner extends StatelessWidget {
  const ReadmeBanner({super.key, required this.arabic});

  final bool arabic;

  static const ink = Color(0xFF0F1226);
  static const night = Color(0xFF1B1F3B);
  static const saffron = Color(0xFFF4B400);
  static const red = Color(0xFFD7263D);
  static const teal = Color(0xFF0F8B8D);

  @override
  Widget build(BuildContext context) {
    final title = arabic ? 'وَصْل' : 'Wasl';
    final other = arabic ? 'Wasl' : 'وَصْل';
    final tagline = arabic ? 'شات مشفّر من غير إنترنت ولا سيرفر' : 'Encrypted chat. No internet, no server.';
    final sub = arabic
        ? 'الرسايل بتتخيّط من موبايل لموبايل لحد ما توصل'
        : 'Messages are stitched from phone to phone until they arrive';
    final chips = arabic
        ? const ['بلوتوث', 'واي فاي', 'Mesh', 'ألعاب', 'مشفّر من طرف لطرف']
        : const ['Bluetooth', 'Wi-Fi', 'Mesh', 'Games', 'End-to-end encrypted'];
    final foot = arabic
        ? 'Offline mesh chat for Android  •  open source (GPL-3.0)'
        : 'شات من غير إنترنت لأندرويد  •  مفتوح المصدر (GPL-3.0)';
    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Plex', fontFamilyFallback: ['ShotsEmoji']),
          child: Container(
            color: ink,
            child: CustomPaint(
              painter: KhayamiyaPainter(color: saffron.withValues(alpha: 0.05), cell: 64, stroke: 2),
              child: Stack(
                children: [
                  // زينة فوق
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: CustomPaint(
                      painter: BuntingPainter(
                        colors: const [saffron, red, teal, Color(0xFFEEF0FA)],
                        flag: 30,
                        sag: 0,
                        string: Colors.white24,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(70, 64, 20, 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const _Logo(size: 84),
                                  const SizedBox(width: 20),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 80,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: Text(
                                      other,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text(
                                tagline,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                sub,
                                style: const TextStyle(
                                  color: saffron,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final c in chips)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                foot,
                                textDirection: arabic ? TextDirection.ltr : TextDirection.rtl,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(flex: 9, child: _Graph()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// الأيقونة: فقاعة زعفراني جواها 3 أجهزة متوصلة.
class _Logo extends StatelessWidget {
  const _Logo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(26 * s)),
      Paint()..color = ReadmeBanner.night,
    );
    final bubble = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(17 * s, 19 * s, 66 * s, 49 * s), Radius.circular(17 * s)))
      ..moveTo(29 * s, 63 * s)
      ..lineTo(26 * s, 80 * s)
      ..lineTo(44 * s, 67 * s)
      ..close();
    canvas.drawPath(bubble, Paint()..color = ReadmeBanner.saffron);
    final nodes = [Offset(34 * s, 50 * s), Offset(50 * s, 36 * s), Offset(66 * s, 50 * s)];
    final line = Paint()
      ..color = ReadmeBanner.night
      ..strokeWidth = 3.4 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(nodes[0], nodes[1], line);
    canvas.drawLine(nodes[1], nodes[2], line);
    canvas.drawLine(nodes[0], nodes[2], line);
    for (final n in nodes) {
      canvas.drawCircle(n, 5.4 * s, Paint()..color = ReadmeBanner.night);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

/// شبكة أفاتارات كرتون متوصلة بغرز.
class _Graph extends StatelessWidget {
  const _Graph();

  static const _avatars = [
    (0.50, 0.50, 3, 0xFF0EA5E9), // في النص
    (0.20, 0.22, 13, 0xFF14B8A6),
    (0.78, 0.18, 7, 0xFFEAB308),
    (0.88, 0.55, 18, 0xFFEC4899),
    (0.72, 0.86, 11, 0xFFEF4444),
    (0.28, 0.84, 21, 0xFF22C55E),
    (0.10, 0.55, 5, 0xFFA855F7),
  ];
  static const _edges = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 6), (6, 5), (2, 3), (3, 4)];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          Offset at(int i) => Offset(_avatars[i].$1 * (w - 120) + 60, _avatars[i].$2 * (h - 160) + 90);
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _Edges([for (final (a, b) in _edges) (at(a), at(b))]))),
              for (var i = 0; i < _avatars.length; i++)
                Positioned(
                  left: at(i).dx - (i == 0 ? 56 : 44),
                  top: at(i).dy - (i == 0 ? 56 : 44),
                  child: _Face(size: i == 0 ? 112 : 88, cartoon: _avatars[i].$3, color: Color(_avatars[i].$4)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Edges extends CustomPainter {
  _Edges(this.edges);
  final List<(Offset, Offset)> edges;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = ReadmeBanner.saffron.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in edges) {
      StitchPainter.drawStitch(canvas, a, b, p, dash: 12, gap: 9);
    }
  }

  @override
  bool shouldRepaint(_Edges old) => false;
}

class _Face extends StatelessWidget {
  const _Face({required this.size, required this.cartoon, required this.color});
  final double size;
  final int cartoon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.34),
      border: Border.all(color: ReadmeBanner.ink, width: 5),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8))],
    ),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(painter: CartoonPainter(cartoon)),
  );
}
