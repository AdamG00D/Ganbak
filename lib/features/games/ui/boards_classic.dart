import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/cartoon_avatar.dart';
import '../../../widgets/identity.dart';
import '../core/game_room.dart';
import '../core/view_read.dart';
import 'game_screen.dart';

List<String> _order(GameRoom room) => ViewRead.order(room.view, room.players);
List<int> _ints(Object? raw) => ViewRead.ints(raw);

/// لون اللاعب رقم [i] (برقم برا الحدود = أول لون).
Color _playerColor(int i) => GameColors.players[i < 0 ? 0 : i % GameColors.players.length];

bool _myTurn(GameRoom room) => room.view['turn'] == room.myId && !room.over;

/// لوح مربع في نص المساحة المتاحة (أكبر حاجة ممكنة لحد [max]).
class _SquareArea extends StatelessWidget {
  const _SquareArea({required this.child, this.max = 380, this.aspect = 1});
  final Widget child;
  final double max;
  final double aspect;

  // اللوح نفسه مبيتقلبش مع العربي: اللاعبين الاتنين لازم يشوفوا نفس الشكل حتى لو لغاتهم مختلفة
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: AspectRatio(
              aspectRatio: aspect,
              child: Directionality(textDirection: TextDirection.ltr, child: child),
            ),
          ),
        ),
      );
}

// =====================================================================
// إكس أو
// =====================================================================

class XoBoard extends StatelessWidget {
  const XoBoard({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final order = _order(room);
    final board = _ints(room.view['b']);
    final line = _ints(room.view['line']);
    final mine = _myTurn(room);
    final colors = {for (var i = 0; i < order.length; i++) order[i]: _playerColor(i)};
    return Column(
      children: [
        DuelHeader(room: room, colors: colors),
        Expanded(
          child: _SquareArea(
            max: 360,
            child: StitchedBox(
              color: p.isDark ? const Color(0xFF262B66) : GameColors.xo,
              radius: 28,
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, box) {
                  final cell = box.maxWidth / 3;
                  return Stack(
                    children: [
                      // خطوط اللوح غرزة
                      Positioned.fill(
                        child: CustomPaint(painter: _XoGrid(color: Colors.white.withValues(alpha: 0.45))),
                      ),
                      for (var i = 0; i < 9; i++)
                        Positioned(
                          left: (i % 3) * cell,
                          top: (i ~/ 3) * cell,
                          width: cell,
                          height: cell,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: mine && board[i] == -1
                                ? () {
                                    HapticFeedback.selectionClick();
                                    room.act({'t': 'put', 'i': i});
                                  }
                                : null,
                            child: Padding(
                              padding: EdgeInsets.all(cell * 0.2),
                              child: board[i] == -1
                                  ? null
                                  : TweenAnimationBuilder<double>(
                                      key: ValueKey('$i-${board[i]}-${room.round}'),
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeOutBack,
                                      builder: (_, t, _) => CustomPaint(
                                        painter: _XoMark(
                                          cross: board[i] == 0,
                                          color: _playerColor(board[i]),
                                          t: t,
                                          glow: line.contains(i),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _XoGrid extends CustomPainter {
  _XoGrid({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final c = size.width / 3;
    for (var k = 1; k < 3; k++) {
      StitchPainter.drawStitch(canvas, Offset(c * k, 6), Offset(c * k, size.height - 6), paint, dash: 9, gap: 6);
      StitchPainter.drawStitch(canvas, Offset(6, c * k), Offset(size.width - 6, c * k), paint, dash: 9, gap: 6);
    }
  }

  @override
  bool shouldRepaint(_XoGrid old) => false;
}

class _XoMark extends CustomPainter {
  _XoMark({required this.cross, required this.color, required this.t, required this.glow});
  final bool cross;
  final Color color;
  final double t;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round;
    if (glow) {
      canvas.drawCircle(size.center(Offset.zero), w * 0.66, Paint()..color = Colors.white.withValues(alpha: 0.18));
    }
    canvas.save();
    canvas.translate(w / 2, w / 2);
    canvas.scale(t);
    canvas.translate(-w / 2, -w / 2);
    if (cross) {
      canvas.drawLine(Offset(w * 0.12, w * 0.12), Offset(w * 0.88, w * 0.88), paint);
      canvas.drawLine(Offset(w * 0.88, w * 0.12), Offset(w * 0.12, w * 0.88), paint);
    } else {
      canvas.drawCircle(Offset(w / 2, w / 2), w * 0.38, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_XoMark old) => old.t != t || old.glow != glow;
}

// =====================================================================
// أربعة في صف
// =====================================================================

class Connect4Board extends StatelessWidget {
  const Connect4Board({super.key, required this.room});
  final GameRoom room;

  static const cols = 7, rows = 6;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final order = _order(room);
    final board = _ints(room.view['b']);
    final line = _ints(room.view['line']);
    final last = room.view['last'];
    final mine = _myTurn(room);
    final colors = {for (var i = 0; i < order.length; i++) order[i]: _playerColor(i)};
    final hole = p.isDark ? const Color(0xFF0F1226) : const Color(0xFFF5F6FA);
    return Column(
      children: [
        DuelHeader(room: room, colors: colors),
        Expanded(
          child: _SquareArea(
            max: 420,
            aspect: cols / (rows + 0.35),
            child: StitchedBox(
              color: GameColors.connect4,
              radius: 24,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              child: LayoutBuilder(
                builder: (context, box) {
                  final cw = box.maxWidth / cols, ch = box.maxHeight / rows;
                  final d = math.min(cw, ch) * 0.82;
                  return Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: mine && board[c] == -1
                                ? () {
                                    HapticFeedback.selectionClick();
                                    room.act({'t': 'drop', 'c': c});
                                  }
                                : null,
                            child: Column(
                              children: [
                                for (var r = 0; r < rows; r++)
                                  Expanded(
                                    child: Center(
                                      child: _Disc(
                                        size: d,
                                        hole: hole,
                                        color: board[r * cols + c] == -1 ? null : _playerColor(board[r * cols + c]),
                                        dropFrom: last == r * cols + c ? r + 1 : 0,
                                        ring: line.contains(r * cols + c),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.hole, this.color, this.dropFrom = 0, this.ring = false});
  final double size;
  final Color hole;
  final Color? color;

  /// القطعة دي لسه نازلة من كام صف فوق (أنيميشن السقوط).
  final int dropFrom;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final holeBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hole,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1.5))],
      ),
    );
    final c = color;
    if (c == null) return holeBox;
    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.black.withValues(alpha: 0.12), width: 3),
      ),
    );
    if (dropFrom == 0) return Stack(alignment: Alignment.center, children: [holeBox, disc]);
    return Stack(
      alignment: Alignment.center,
      children: [
        holeBox,
        TweenAnimationBuilder<double>(
          tween: Tween(begin: -dropFrom * size * 1.2, end: 0),
          duration: Duration(milliseconds: 160 + dropFrom * 45),
          curve: Curves.bounceOut,
          builder: (_, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
          child: disc,
        ),
      ],
    );
  }
}

// =====================================================================
// مربعات ونقط
// =====================================================================

class DotsBoard extends StatelessWidget {
  const DotsBoard({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final order = _order(room);
    final n = ViewRead.integer(room.view['n']) ?? 4;
    final h = _ints(room.view['h']);
    final v = _ints(room.view['v']);
    final boxes = _ints(room.view['box']);
    final scores = _ints(room.view['s']);
    final mine = _myTurn(room);
    final colors = [for (var i = 0; i < order.length; i++) _playerColor(i)];
    return Column(
      children: [
        if (order.length == 2)
          DuelHeader(
            room: room,
            scores: {for (var i = 0; i < order.length; i++) order[i]: i < scores.length ? scores[i] : 0},
            colors: {for (var i = 0; i < order.length; i++) order[i]: colors[i]},
          )
        else
          ScoreStrip(room: room, scores: scores, colors: colors),
        Expanded(
          child: _SquareArea(
            max: 400,
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.border),
              ),
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, box) {
                  final cell = box.maxWidth / n;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: !mine
                        ? null
                        : (d) {
                            final hit = _nearestLine(d.localPosition, cell, n);
                            if (hit == null) return;
                            final (horizontal, i) = hit;
                            if ((horizontal ? h : v)[i] != -1) return;
                            HapticFeedback.selectionClick();
                            room.act({'t': 'line', 'h': horizontal, 'i': i});
                          },
                    child: CustomPaint(
                      size: Size.square(box.maxWidth),
                      painter: _DotsPainter(
                        n: n,
                        h: h,
                        v: v,
                        boxes: boxes,
                        colors: colors,
                        names: [for (final id in order) room.nameOf(id)],
                        dot: p.text,
                        empty: p.border,
                        last: ViewRead.str(room.view['last']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// أقرب خط للمكان اللي اتداس عليه.
  static (bool, int)? _nearestLine(Offset at, double cell, int n) {
    (bool, int)? best;
    var bestD = cell * 0.45;
    for (var r = 0; r <= n; r++) {
      for (var c = 0; c < n; c++) {
        final mid = Offset((c + 0.5) * cell, r * cell);
        final d = (at - mid).distance;
        if (d < bestD) {
          bestD = d;
          best = (true, r * n + c);
        }
      }
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c <= n; c++) {
        final mid = Offset(c * cell, (r + 0.5) * cell);
        final d = (at - mid).distance;
        if (d < bestD) {
          bestD = d;
          best = (false, r * (n + 1) + c);
        }
      }
    }
    return best;
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({
    required this.n,
    required this.h,
    required this.v,
    required this.boxes,
    required this.colors,
    required this.names,
    required this.dot,
    required this.empty,
    required this.last,
  });

  final int n;
  final List<int> h, v, boxes;
  final List<Color> colors;
  final List<String> names;
  final Color dot, empty;
  final String? last;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    // المربعات المقفولة
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final o = boxes[r * n + c];
        if (o < 0 || o >= colors.length) continue;
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell).deflate(4);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), Paint()..color = colors[o].withValues(alpha: 0.28));
        final tp = TextPainter(
          text: TextSpan(
            text: o < names.length && names[o].isNotEmpty ? names[o].characters.first : '?',
            style: TextStyle(color: colors[o], fontWeight: FontWeight.w700, fontSize: cell * 0.36, fontFamily: AppTheme.fontFamily),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
      }
    }
    final emptyPaint = Paint()
      ..color = empty
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    void line(Offset a, Offset b, int who, bool isLast) {
      if (who < 0 || who >= colors.length) {
        StitchPainter.drawStitch(canvas, a, b, emptyPaint, dash: 4, gap: 5);
        return;
      }
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = colors[who]
          ..strokeWidth = isLast ? 7 : 5.5
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var r = 0; r <= n; r++) {
      for (var c = 0; c < n; c++) {
        final i = r * n + c;
        line(Offset(c * cell, r * cell), Offset((c + 1) * cell, r * cell), h[i], last == 'h$i');
      }
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c <= n; c++) {
        final i = r * (n + 1) + c;
        line(Offset(c * cell, r * cell), Offset(c * cell, (r + 1) * cell), v[i], last == 'v$i');
      }
    }
    final dotPaint = Paint()..color = dot;
    for (var r = 0; r <= n; r++) {
      for (var c = 0; c <= n; c++) {
        canvas.drawCircle(Offset(c * cell, r * cell), 5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => true;
}

// =====================================================================
// الذاكرة
// =====================================================================

class MemoryBoard extends StatelessWidget {
  const MemoryBoard({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final order = _order(room);
    final faces = _ints(room.view['c']);
    final own = _ints(room.view['own']);
    final open = _ints(room.view['open']);
    final scores = _ints(room.view['s']);
    final miss = room.view['miss'] == true;
    final mine = _myTurn(room) && !miss && open.length < 2;
    final colors = [for (var i = 0; i < order.length; i++) _playerColor(i)];
    final cols = 4;
    final rows = (faces.length / cols).ceil();
    return Column(
      children: [
        if (order.length == 2)
          DuelHeader(
            room: room,
            scores: {for (var i = 0; i < order.length; i++) order[i]: i < scores.length ? scores[i] : 0},
            colors: {for (var i = 0; i < order.length; i++) order[i]: colors[i]},
          )
        else
          ScoreStrip(room: room, scores: scores, colors: colors),
        Expanded(
          child: _SquareArea(
            max: 400,
            aspect: cols / rows,
            child: GridView.count(
              crossAxisCount: cols,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var i = 0; i < faces.length; i++)
                  _MemoryCard(
                    face: faces[i],
                    owner: own[i] < 0 || own[i] >= colors.length ? null : colors[own[i]],
                    open: open.contains(i),
                    onTap: mine && faces[i] < 0
                        ? () {
                            HapticFeedback.selectionClick();
                            room.act({'t': 'flip', 'i': i});
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.face, this.owner, this.open = false, this.onTap});

  /// -1 = مقلوب.
  final int face;
  final Color? owner;
  final bool open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shown = face >= 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: shown ? 0 : 1, end: shown ? 1 : 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final front = t > 0.5;
        final angle = t * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: front
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _front(p),
                )
              : _back(p),
        );
      },
    );
  }

  Widget _back(Palette p) => Material(
        color: p.ink,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: CustomPaint(
            painter: KhayamiyaPainter(color: p.saffron.withValues(alpha: 0.35), cell: 22, stroke: 1.2),
            foregroundPainter: StitchBorderPainter(color: p.saffron.withValues(alpha: 0.55), radius: 14, inset: 4),
            child: const SizedBox.expand(),
          ),
        ),
      );

  Widget _front(Palette p) {
    final f = face < 0 ? 0 : face;
    return Container(
      decoration: BoxDecoration(
        color: avatarColor(f),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: owner ?? (open ? p.saffron : Colors.transparent), width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Opacity(
        opacity: owner != null ? 0.55 : 1,
        child: CustomPaint(painter: CartoonPainter((f % CartoonAvatars.count) + 1), child: const SizedBox.expand()),
      ),
    );
  }
}
