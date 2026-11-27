import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/identity.dart';
import '../../hub/chat_hub.dart';
import '../core/game_kind.dart';
import 'game_help.dart';
import 'game_look.dart';
import 'game_screen.dart';

/// زرار 🎮 في الشات: قايمة الألعاب اللي تنفع للمحادثة دي، واللي يختار واحدة تتفتح.
Future<void> showGamePicker(BuildContext context, Conversation c) async {
  final l = context.l10n;
  if (!c.games.transport.online) {
    showToast(context, c.isGroup ? l.gameNobody : l.gameNeedConnection, error: true);
    return;
  }
  final kind = await pickGame(context, group: c.isGroup, title: c.isGroup ? l.playWithGroup : l.playWith(c.title));
  if (kind == null || !context.mounted) return;
  final room = c.games.invite(kind);
  if (room == null) {
    showToast(context, l.gameNobody, error: true);
    return;
  }
  await GameScreen.open(context, c, room);
}

/// القايمة نفسها: كروت الألعاب اللي تنفع للمحادثة (خاص أو جروب).
Future<GameKind?> pickGame(BuildContext context, {required bool group, required String title}) {
  final kinds = GameKind.forChat(group: group);
  return showActionSheet<GameKind>(
    context,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        ),
        LayoutBuilder(
          builder: (_, box) {
            final w = (box.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final k in kinds)
                  SizedBox(
                    width: w,
                    child: _GameTile(kind: k, onTap: () => Navigator.pop(ctx, k)),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

/// كارت لعبة في القايمة: قماش بلون اللعبة ونقشة وزرار شرح.
class _GameTile extends StatelessWidget {
  const _GameTile({required this.kind, required this.onTap});

  final GameKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = GameLook.color(kind);
    final fg = Palette.onColor(color);
    return StitchedBox(
      color: color,
      radius: 18,
      pattern: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SizedBox(
        height: 96,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(GameLook.icon(kind), color: fg, size: 26),
                const Spacer(),
                Text(
                  GameLook.name(kind, l),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14, height: 1.25),
                ),
                Text(
                  l.playersRange(GameLook.players(kind)),
                  style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                ),
              ],
            ),
            PositionedDirectional(
              top: -4,
              end: -4,
              child: HelpButton(size: 30, onDark: fg == Colors.white, onPressed: () => GameHelpPage.open(context, kind)),
            ),
          ],
        ),
      ),
    );
  }
}
