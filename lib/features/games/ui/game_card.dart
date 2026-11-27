import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/identity.dart';
import '../../chat/core/chat_session.dart';
import '../../hub/chat_hub.dart';
import '../core/game_kind.dart';
import '../core/game_room.dart';
import '../core/view_read.dart';
import 'game_look.dart';
import 'game_screen.dart';

/// كارت لعبة جوه المحادثة: العزومة (العب / انضم)، وهي شغالة (افتح)، وبعد ما تخلص (النتيجة).
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.conversation, required this.message});

  final Conversation conversation;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final g = message.game!;
    final kind = GameKind.byId(g['k']);
    if (kind == null) return const SizedBox.shrink();
    final room = conversation.games.rooms[g['g']];
    if (room == null) return _card(context, kind, null);
    return ListenableBuilder(listenable: room, builder: (context, _) => _card(context, kind, room));
  }

  Widget _card(BuildContext context, GameKind kind, GameRoom? room) {
    final p = context.palette;
    final l = context.l10n;
    final g = message.game!;
    final color = GameLook.color(kind);
    final live = room != null && room.phase != RoomPhase.closed;
    final wins = room?.wins ?? ViewRead.intMap(g['w']);
    final names = ViewRead.strMap(g['nm']);
    String nameOf(String id) => room?.nameOf(id) ?? (names[id] ?? '…');

    String status;
    Widget? action;
    if (!live) {
      status = wins.isEmpty
          ? l.gameClosedCard
          : wins.entries.map((e) => '${nameOf(e.key)} ${e.value}').join('  •  ');
    } else if (room.phase == RoomPhase.lobby) {
      if (room.autoStart) {
        status = room.isHost ? l.gameWaitingPeer(conversation.title) : l.gameInviteFrom(nameOf(room.host), GameLook.name(kind, l));
      } else {
        final missing = kind.minPlayers - room.players.length;
        status = '${l.gameSeats('${room.players.length}', '${kind.maxPlayers}')} — '
            '${missing > 0 ? l.gameNeedMore('$missing') : l.gameWaitingHost(nameOf(room.host))}';
      }
      if (!room.isHost && !room.joined) {
        action = _Button(
          label: room.autoStart ? l.gamePlay : l.gameJoin,
          onTap: () {
            room.join();
            GameScreen.open(context, conversation, room);
          },
        );
      } else {
        action = _Button(label: l.gameOpen, onTap: () => GameScreen.open(context, conversation, room), quiet: true);
      }
    } else {
      status = room.over ? l.gameDoneCard : (room.joined ? GameLook.tag(kind, l) : l.gameSpectating);
      action = _Button(
        label: room.joined ? l.gameOpen : l.gameWatch,
        onTap: () => GameScreen.open(context, conversation, room),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: StitchedBox(
            color: live ? color : p.surfaceAlt,
            pattern: live,
            stitch: live ? null : p.border,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Builder(
              builder: (context) {
                final fg = live ? Palette.onColor(color) : p.text;
                return Row(
                  children: [
                    Icon(GameLook.icon(kind), color: fg, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            GameLook.name(kind, l),
                            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
                          ),
                          Text(
                            status,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (action != null) ...[const SizedBox(width: 8), action],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.quiet = false});
  final String label;
  final VoidCallback onTap;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: quiet ? Colors.white.withValues(alpha: 0.18) : p.saffron,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(color: quiet ? Colors.white : p.ink, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

/// شريط فوق الشات لما يكون فيه لعبة أنا فيها شغالة.
class GameRunningBanner extends StatelessWidget {
  const GameRunningBanner({super.key, required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: conversation.games,
      builder: (context, _) {
        final room = conversation.games.current;
        if (room == null || room.phase != RoomPhase.playing) return const SizedBox.shrink();
        final l = context.l10n;
        final color = GameLook.color(room.kind);
        final fg = Palette.onColor(color);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => GameScreen.open(context, conversation, room),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Icon(GameLook.icon(room.kind), color: fg, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.gameRunningBanner(GameLook.name(room.kind, l)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(l.gameBackToGame, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
