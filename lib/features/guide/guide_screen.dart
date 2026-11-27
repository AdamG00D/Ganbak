import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/identity.dart';
import '../../widgets/ui.dart';
import '../games/core/game_kind.dart';
import '../games/ui/game_help.dart';
import '../games/ui/game_look.dart';

/// أقسام الدليل (عشان نفتح على قسم معيّن).
enum GuideSection { connect, groups, games, safety }

/// "دليل وصل": طرق الاتصال (بالرسم)، الشبكة، الجروبات، الألعاب، والأمان.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key, this.section});

  final GuideSection? section;

  static Future<void> open(BuildContext context, {GuideSection? section}) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GuideScreen(section: section)),
      );

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _keys = {for (final s in GuideSection.values) s: GlobalKey()};

  @override
  void initState() {
    super.initState();
    final s = widget.section;
    if (s != null && s != GuideSection.connect) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jump(s, animate: false));
    }
  }

  void _jump(GuideSection s, {bool animate = true}) {
    final ctx = _keys[s]!.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: animate ? const Duration(milliseconds: 350) : Duration.zero, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الراس: حبر الليل بنقشة خيامية
            Material(
              color: p.ink,
              child: CustomPaint(
                painter: KhayamiyaPainter(color: p.saffron.withValues(alpha: 0.10)),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(8, top + 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: l.back,
                        onPressed: () => Navigator.maybePop(context),
                        icon: const BackButtonIcon(),
                        color: Colors.white,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.guideTitle,
                              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, height: 1.3),
                            ),
                            Text(l.guideSub, style: TextStyle(color: p.saffron, fontSize: 14.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final (s, label) in [
                                  (GuideSection.connect, l.guideJumpConnect),
                                  (GuideSection.groups, l.guideJumpGroups),
                                  (GuideSection.games, l.guideJumpGames),
                                  (GuideSection.safety, l.guideJumpSafety),
                                ])
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _jump(s),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        child: Text(
                                          label,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Heading(key: _keys[GuideSection.connect], icon: Icons.cell_tower_rounded, text: l.guideConnectTitle),
                  Text(l.guideConnectIntro, style: TextStyle(color: p.textMuted, height: 1.7, fontSize: 14.5)),
                  const SizedBox(height: 14),
                  _Way(
                    kind: _Diagram.bluetooth,
                    color: p.isDark ? const Color(0xFF2A3060) : p.ink,
                    icon: Icons.bluetooth_rounded,
                    title: l.bluetooth,
                    what: l.guideBtWhat,
                    when: l.guideBtWhen,
                    facts: l.guideBtFacts,
                    how: l.guideBtHow,
                  ),
                  _Way(
                    kind: _Diagram.wifi,
                    color: p.isDark ? const Color(0xFF0E6F71) : p.teal,
                    icon: Icons.wifi_rounded,
                    title: l.wifi,
                    what: l.guideWifiWhat,
                    when: l.guideWifiWhen,
                    facts: l.guideWifiFacts,
                    how: l.guideWifiHow,
                  ),
                  _Way(
                    kind: _Diagram.both,
                    color: p.isDark ? const Color(0xFFB3213A) : p.tentRed,
                    icon: Icons.hub_rounded,
                    title: l.both,
                    what: l.guideBothWhat,
                    when: l.guideBothWhen,
                    facts: l.guideBothFacts,
                    how: l.guideBothHow,
                  ),
                  _Way(
                    kind: _Diagram.wasl,
                    color: p.isDark ? const Color(0xFF8A6500) : p.saffron,
                    icon: Icons.wifi_tethering_rounded,
                    title: l.guideNetTitle,
                    what: l.guideNetWhat,
                    when: l.guideNetWhen,
                    facts: l.guideNetFacts,
                    how: l.guideNetHow,
                  ),
                  _Item(icon: Icons.hub_rounded, title: l.howMeshTitle, body: '${l.howMeshBody}\n${l.guideMeshHops}'),
                  _Item(icon: Icons.hourglass_top_rounded, title: l.guideMailTitle, body: l.guideMailBody),
                  const SizedBox(height: 18),
                  _Heading(key: _keys[GuideSection.groups], icon: Icons.groups_rounded, text: l.guideGroupsTitle),
                  _Item(icon: Icons.groups_rounded, title: l.howGroupsTitle, body: l.howGroupsBody),
                  _Item(icon: Icons.admin_panel_settings_outlined, title: l.howAdminTitle, body: l.howAdminBody),
                  const SizedBox(height: 18),
                  _Heading(key: _keys[GuideSection.games], icon: Icons.sports_esports_rounded, text: l.guideGamesTitle),
                  Text(l.guideGamesBody, style: TextStyle(color: p.textMuted, height: 1.7, fontSize: 14.5)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, box) {
                      final w = (box.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in GameKind.values) SizedBox(width: w, child: _GameChip(kind: k)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _Heading(key: _keys[GuideSection.safety], icon: Icons.shield_rounded, text: l.guideSafetyTitle),
                  _Item(icon: Icons.cloud_off_rounded, title: l.howNoInternetTitle, body: l.howNoInternetBody),
                  _Item(icon: Icons.lock_rounded, title: l.howEncryptionTitle, body: l.howEncryptionBody),
                  _Item(icon: Icons.verified_user_outlined, title: l.howSafetyTitle, body: l.howSafetyBody),
                  _Item(icon: Icons.notifications_none_rounded, title: l.howNotifTitle, body: l.howNotifBody),
                  _Item(icon: Icons.bookmark_outline_rounded, title: l.howSaveTitle, body: l.howSaveBody),
                  _Item(icon: Icons.campaign_rounded, title: l.guideSosTitle, body: l.guideSosBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: p.accentInk),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(color: p.textMuted, height: 1.65, fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كارت طريقة اتصال: راس ملوّن فيه رسمة + إيه هو / إمتى / تعرف إيه / تبدأ إزاي.
class _Way extends StatelessWidget {
  const _Way({
    required this.kind,
    required this.color,
    required this.icon,
    required this.title,
    required this.what,
    required this.when,
    required this.facts,
    required this.how,
  });

  final _Diagram kind;
  final Color color;
  final IconData icon;
  final String title, what, when, facts, how;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final fg = Palette.onColor(color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: p.border)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: color,
              child: CustomPaint(
                painter: KhayamiyaPainter(color: fg.withValues(alpha: 0.08)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: kind == _Diagram.wasl ? p.ink : p.saffron,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(icon, color: kind == _Diagram.wasl ? p.saffron : p.ink, size: 21),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(title, style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // الرسمة نفسها مبتتقلبش مع اللغة
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _DiagramPainter(
                              kind: kind,
                              fg: fg,
                              accent: kind == _Diagram.wasl ? p.ink : p.saffron,
                              bridge: kind == _Diagram.wasl ? p.ink : p.saffron,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Part(label: l.guideWhat, text: what),
                  _Part(label: l.guideWhen, text: when),
                  _Part(label: l.guideFacts, text: facts, bullets: true),
                  _Part(label: l.guideHow, text: how, steps: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({required this.label, required this.text, this.bullets = false, this.steps = false});
  final String label;
  final String text;
  final bool bullets;
  final bool steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = text.split('\n').where((x) => x.trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          if (!bullets && !steps)
            Text(text, style: TextStyle(color: p.text, height: 1.7, fontSize: 14.5))
          else
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (steps)
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.saffron, borderRadius: BorderRadius.circular(8)),
                        child: Text('${i + 1}', style: TextStyle(color: p.ink, fontSize: 12, fontWeight: FontWeight.w700)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: p.textMuted, shape: BoxShape.circle)),
                      ),
                    SizedBox(width: steps ? 10 : 12),
                    Expanded(child: Text(lines[i], style: TextStyle(color: p.text, height: 1.65, fontSize: 14.5))),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _GameChip extends StatelessWidget {
  const _GameChip({required this.kind});
  final GameKind kind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = GameLook.color(kind);
    final fg = Palette.onColor(color);
    return StitchedBox(
      color: color,
      radius: 16,
      onTap: () => GameHelpPage.open(context, kind),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(GameLook.icon(kind), color: fg, size: 22),
            const SizedBox(height: 8),
            Text(
              GameLook.name(kind, l),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- الرسومات ----------------

enum _Diagram { bluetooth, wifi, both, wasl }

/// موبايلات صغيرة متوصلة: البلوتوث سلسلة غرز، الواي فاي حوالين هوت سبوت، والاتنين كوبري بين شبكتين.
class _DiagramPainter extends CustomPainter {
  _DiagramPainter({required this.kind, required this.fg, required this.accent, required this.bridge});

  final _Diagram kind;
  final Color fg;
  final Color accent;
  final Color bridge;

  void _phone(Canvas canvas, Offset c, {double s = 1, bool hot = false}) {
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 20 * s, height: 34 * s), Radius.circular(5 * s));
    canvas.drawRRect(body, Paint()..color = hot ? accent : fg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, -1.5 * s), width: 14 * s, height: 23 * s), Radius.circular(2 * s)),
      Paint()..color = (hot ? const Color(0xFF1B1F3B) : fg).withValues(alpha: hot ? 0.85 : 0.35),
    );
    canvas.drawCircle(c.translate(0, 13 * s), 1.6 * s, Paint()..color = hot ? const Color(0xFF1B1F3B) : const Color(0x55000000));
    if (hot) {
      // موجات الهوت سبوت
      final wave = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (final r in [16.0, 24.0]) {
        canvas.drawArc(Rect.fromCircle(center: c.translate(0, -18 * s), radius: r * s * 0.6), -math.pi * 0.8, math.pi * 0.6, false, wave);
      }
    }
  }

  void _stitch(Canvas canvas, Offset a, Offset b, Color color, {double w = 2.4}) {
    StitchPainter.drawStitch(canvas, a, b, Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round, dash: 6, gap: 5);
  }

  void _solid(Canvas canvas, Offset a, Offset b, Color color) {
    canvas.drawLine(a, b, Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final line = fg.withValues(alpha: 0.65);
    switch (kind) {
      case _Diagram.bluetooth:
        // سلسلة: الرسالة بتنط من موبايل للتاني
        final pts = [
          for (var i = 0; i < 5; i++) Offset(w * (0.1 + i * 0.2), h * (i.isEven ? 0.62 : 0.36)),
        ];
        for (var i = 0; i + 1 < pts.length; i++) {
          _stitch(canvas, pts[i], pts[i + 1], line);
        }
        for (final pt in pts) {
          _phone(canvas, pt, s: 1.05);
        }
      case _Diagram.wifi:
        final c = Offset(w / 2, h * 0.55);
        final around = [
          for (var i = 0; i < 6; i++)
            Offset(c.dx + math.cos(math.pi * (0.95 + i * 0.22)) * w * 0.36, c.dy + math.sin(math.pi * (0.95 + i * 0.22)) * h * 0.1 + (i.isEven ? 22 : -6)),
        ];
        for (final pt in around) {
          _solid(canvas, c, pt, line);
        }
        for (final pt in around) {
          _phone(canvas, pt, s: 0.95);
        }
        _phone(canvas, c, s: 1.2, hot: true);
      case _Diagram.both:
        // شبكتين واي فاي وكوبري بلوتوث في النص
        final l1 = Offset(w * 0.2, h * 0.55), l2 = Offset(w * 0.8, h * 0.55);
        final bridgeAt = Offset(w * 0.5, h * 0.42);
        final left = [Offset(w * 0.06, h * 0.3), Offset(w * 0.08, h * 0.82), Offset(w * 0.33, h * 0.85)];
        final right = [Offset(w * 0.94, h * 0.3), Offset(w * 0.92, h * 0.82), Offset(w * 0.67, h * 0.85)];
        for (final pt in left) {
          _solid(canvas, l1, pt, line);
        }
        for (final pt in right) {
          _solid(canvas, l2, pt, line);
        }
        _stitch(canvas, l1, bridgeAt, bridge, w: 3);
        _stitch(canvas, bridgeAt, l2, bridge, w: 3);
        for (final pt in [...left, ...right]) {
          _phone(canvas, pt, s: 0.85);
        }
        _phone(canvas, l1, s: 1.05, hot: true);
        _phone(canvas, l2, s: 1.05, hot: true);
        _phone(canvas, bridgeAt, s: 1.1);
      case _Diagram.wasl:
        // موبايل فاتح الشبكة في النص واللي حواليه داخلين عليها، وواحد لسه جاي بالبلوتوث (غرزة)
        final host = Offset(w * 0.42, h * 0.55);
        final joined = [Offset(w * 0.14, h * 0.3), Offset(w * 0.12, h * 0.82), Offset(w * 0.42, h * 0.9), Offset(w * 0.66, h * 0.3)];
        final coming = Offset(w * 0.88, h * 0.7);
        for (final pt in joined) {
          _solid(canvas, host, pt, line);
        }
        _stitch(canvas, host, coming, bridge, w: 3);
        for (final pt in joined) {
          _phone(canvas, pt, s: 0.9);
        }
        _phone(canvas, coming, s: 0.95);
        _phone(canvas, host, s: 1.2, hot: true);
    }
  }

  @override
  bool shouldRepaint(_DiagramPainter old) => old.kind != kind || old.fg != fg;
}
