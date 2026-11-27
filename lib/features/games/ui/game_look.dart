import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../hub/chat_hub.dart';
import '../core/game_kind.dart';
import '../core/game_room.dart';
import '../../../core/profile/profile.dart';
import '../../../widgets/ui.dart';

/// شكل كل لعبة: لونها وأيقونتها واسمها وشرحها.
class GameLook {
  GameLook._();

  static Color color(GameKind k) => switch (k) {
        GameKind.xo => GameColors.xo,
        GameKind.connect4 => GameColors.connect4,
        GameKind.battleship => GameColors.battleship,
        GameKind.rps => GameColors.rps,
        GameKind.dots => GameColors.dots,
        GameKind.memory => GameColors.memory,
        GameKind.spy => GameColors.spy,
        GameKind.quiz => GameColors.quiz,
        GameKind.mafia => GameColors.mafia,
      };

  static IconData icon(GameKind k) => switch (k) {
        GameKind.xo => Icons.grid_3x3_rounded,
        GameKind.connect4 => Icons.blur_circular_rounded,
        GameKind.battleship => Icons.directions_boat_filled_rounded,
        GameKind.rps => Icons.back_hand_rounded,
        GameKind.dots => Icons.grid_on_rounded,
        GameKind.memory => Icons.style_rounded,
        GameKind.spy => Icons.person_search_rounded,
        GameKind.quiz => Icons.lightbulb_rounded,
        GameKind.mafia => Icons.theater_comedy_rounded,
      };

  static String name(GameKind k, AppLocalizations l) => switch (k) {
        GameKind.xo => l.gameXo,
        GameKind.connect4 => l.gameConnect4,
        GameKind.battleship => l.gameBattleship,
        GameKind.rps => l.gameRps,
        GameKind.dots => l.gameDots,
        GameKind.memory => l.gameMemory,
        GameKind.spy => l.gameSpy,
        GameKind.quiz => l.gameQuiz,
        GameKind.mafia => l.gameMafia,
      };

  static String tag(GameKind k, AppLocalizations l) => switch (k) {
        GameKind.xo => l.tagXo,
        GameKind.connect4 => l.tagConnect4,
        GameKind.battleship => l.tagBattleship,
        GameKind.rps => l.tagRps,
        GameKind.dots => l.tagDots,
        GameKind.memory => l.tagMemory,
        GameKind.spy => l.tagSpy,
        GameKind.quiz => l.tagQuiz,
        GameKind.mafia => l.tagMafia,
      };

  /// عدد اللاعبين ("2" أو "3–12").
  static String players(GameKind k) =>
      k.minPlayers == k.maxPlayers ? '${k.minPlayers}' : '${k.minPlayers}–${k.maxPlayers}';

  /// المدة التقريبية بالدقايق.
  static String minutes(GameKind k) => switch (k) {
        GameKind.xo => '2–5',
        GameKind.connect4 => '5–10',
        GameKind.battleship => '10–20',
        GameKind.rps => '1–3',
        GameKind.dots => '5–15',
        GameKind.memory => '5–15',
        GameKind.spy => '5–10',
        GameKind.quiz => '5–10',
        GameKind.mafia => '15–30',
      };

  static (String goal, String how, String? roles, String tips) help(GameKind k, AppLocalizations l) => switch (k) {
        GameKind.xo => (l.helpXoGoal, l.helpXoHow, null, l.helpXoTips),
        GameKind.connect4 => (l.helpConnect4Goal, l.helpConnect4How, null, l.helpConnect4Tips),
        GameKind.battleship => (l.helpBattleshipGoal, l.helpBattleshipHow, null, l.helpBattleshipTips),
        GameKind.rps => (l.helpRpsGoal, l.helpRpsHow, null, l.helpRpsTips),
        GameKind.dots => (l.helpDotsGoal, l.helpDotsHow, null, l.helpDotsTips),
        GameKind.memory => (l.helpMemoryGoal, l.helpMemoryHow, null, l.helpMemoryTips),
        GameKind.spy => (l.helpSpyGoal, l.helpSpyHow, l.helpSpyRoles, l.helpSpyTips),
        GameKind.quiz => (l.helpQuizGoal, l.helpQuizHow, null, l.helpQuizTips),
        GameKind.mafia => (l.helpMafiaGoal, l.helpMafiaHow, l.helpMafiaRoles, l.helpMafiaTips),
      };
}

/// شكل لاعب (اسم ولون وأفاتار) — من الشبكة أو من بروفايلي.
class PlayerLook {
  const PlayerLook({required this.name, required this.color, this.avatar, this.cartoon});
  final String name;
  final int color;
  final String? avatar;
  final int? cartoon;

  static PlayerLook of(GameRoom room, String id) {
    final me = ProfileStore.instance.current;
    if (me != null && id == me.id) {
      return PlayerLook(name: me.name, color: me.color, avatar: me.avatarHash, cartoon: me.cartoon);
    }
    final n = ChatHub.instance.nodeFor(id);
    return PlayerLook(
      name: n?.name ?? room.nameOf(id),
      color: n?.color ?? id.codeUnits.fold(0, (s, c) => s + c),
      avatar: n?.avatar,
      cartoon: n?.cartoon,
    );
  }
}

/// أفاتار لاعب في غرفة.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.room, required this.id, this.size = 36, this.dim = false});

  final GameRoom room;
  final String id;
  final double size;

  /// باهت (خرج / مات).
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final look = PlayerLook.of(room, id);
    final a = Avatar(name: look.name, color: look.color, avatarHash: look.avatar, cartoon: look.cartoon, size: size);
    return dim ? Opacity(opacity: 0.4, child: a) : a;
  }
}
