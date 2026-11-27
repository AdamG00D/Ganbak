import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/identity.dart';
import '../core/game_kind.dart';
import 'game_look.dart';

/// صفحة "إزاي بتتلعب؟" لكل لعبة: الهدف، الخطوات، الأدوار، نصايح، وأسئلة.
class GameHelpPage extends StatelessWidget {
  const GameHelpPage({super.key, required this.kind});

  final GameKind kind;

  static Future<void> open(BuildContext context, GameKind kind) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameHelpPage(kind: kind)),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final color = GameLook.color(kind);
    final fg = Palette.onColor(color);
    final (goal, how, roles, tips) = GameLook.help(kind, l);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // راس الصفحة: قماش اللعبة بنقشة خيامية
          Material(
            color: color,
            child: CustomPaint(
              painter: KhayamiyaPainter(color: fg.withValues(alpha: 0.10)),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8, top + 4, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: l.back,
                      onPressed: () => Navigator.maybePop(context),
                      icon: const BackButtonIcon(),
                      color: fg,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.howToPlay,
                            style: TextStyle(color: fg.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: fg.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(GameLook.icon(kind), color: fg, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  GameLook.name(kind, l),
                                  style: TextStyle(color: fg, fontSize: 28, fontWeight: FontWeight.w700, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(GameLook.tag(kind, l), style: TextStyle(color: fg.withValues(alpha: 0.9), fontSize: 15)),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Fact(Icons.group_rounded, l.playersRange(GameLook.players(kind)), fg),
                              _Fact(Icons.timer_outlined, l.helpMinutes(GameLook.minutes(kind)), fg),
                              if (kind.direct) _Fact(Icons.person_rounded, l.helpWhereDirect, fg),
                              if (kind.group) _Fact(Icons.groups_rounded, l.helpWhereGroup, fg),
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(title: l.helpGoal, icon: Icons.flag_rounded, child: _Para(goal)),
                _Section(title: l.helpHow, icon: Icons.format_list_numbered_rounded, child: _Steps(how, color)),
                if (roles != null) _Section(title: l.helpRoles, icon: Icons.badge_rounded, child: _Lines(roles)),
                _Section(title: l.helpTips, icon: Icons.tips_and_updates_rounded, child: _Lines(tips, bullet: true)),
                _Section(
                  title: l.helpFaq,
                  icon: Icons.help_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Faq(l.helpFaqHostQ, l.helpFaqHostA),
                      _Faq(l.helpFaqLeaveQ, l.helpFaqLeaveA),
                      _Faq(l.helpFaqCheatQ, l.helpFaqCheatA),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text, this.fg);
  final IconData icon;
  final String text;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: p.accentInk),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 15, height: 1.75, color: context.palette.text));
}

/// خطوات بالترتيب (الترتيب هنا معلومة: اللعبة بتمشي كده).
class _Steps extends StatelessWidget {
  const _Steps(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final steps = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i == 0 ? p.ink : p.saffron, borderRadius: BorderRadius.circular(9)),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: i == 0 ? p.saffron : p.ink, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(steps[i], style: TextStyle(fontSize: 15, height: 1.7, color: p.text))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines(this.text, {this.bullet = false});
  final String text;
  final bool bullet;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bullet) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: p.accentInk, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(lines[i], style: TextStyle(fontSize: 14.5, height: 1.7, color: p.text))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq(this.q, this.a);
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.border)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
          title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: p.accentInk,
          collapsedIconColor: p.textMuted,
          children: [Text(a, style: TextStyle(color: p.textMuted, height: 1.7, fontSize: 14))],
          ),
        ),
      ),
    );
  }
}
