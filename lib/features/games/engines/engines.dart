import 'dart:math';

import '../core/game_engine.dart';
import '../core/game_kind.dart';
import '../core/game_room.dart';
import '../data/quiz_bank.dart';
import 'board_games.dart';
import 'party_games.dart';
import 'secret_games.dart';

export 'board_games.dart';
export 'party_games.dart';
export 'secret_games.dart';

/// بيعمل قواعد اللعبة (عند صاحب الغرفة).
GameEngine createEngine(GameKind kind, List<String> players, Random rng, Map<String, dynamic> options) =>
    switch (kind) {
      GameKind.xo => XoEngine(players, rng),
      GameKind.connect4 => Connect4Engine(players, rng),
      GameKind.battleship => BattleshipEngine(players, rng),
      GameKind.rps => RpsEngine(players, rng, target: options['bestOf'] == 5 ? 3 : 2),
      GameKind.dots => DotsEngine(players, rng),
      GameKind.memory => MemoryEngine(players, rng),
      GameKind.spy => SpyEngine(players, rng),
      GameKind.quiz => QuizEngine(
          players,
          rng,
          category: QuizBank.categories.contains(options['cat']) ? options['cat'] as String : null,
          count: switch (options['count']) { 5 => 5, 20 => 20, _ => 10 },
        ),
      GameKind.mafia => MafiaEngine(players, rng),
    };

/// حركات بتحصل لوحدها من غير ما اللاعب يدوس (حتى لو شاشة اللعبة مقفولة):
/// كشف اختيار حجر ورقة مقص، والرد على ضربة في حرب السفن، وكشف اللوح في الآخر.
void autoMoves(GameRoom room) {
  if (room.phase != RoomPhase.playing || !room.joined) return;
  final v = room.view;
  final me = room.myId;
  switch (room.kind) {
    case GameKind.rps:
      final pick = room.local['pick'];
      final shown = v['shown'];
      final key = '${room.round}:${v['k']}';
      if (v['phase'] == 'reveal' &&
          pick is Map &&
          pick['k'] == v['k'] &&
          pick['r'] == room.round &&
          shown is List &&
          !shown.contains(me) &&
          room.local['revealed'] != key) {
        room.local['revealed'] = key;
        room.act({'t': 'reveal', 'c': pick['c'], 's': pick['s']});
      }
    case GameKind.battleship:
      final board = room.local['board'];
      final salt = room.local['salt'];
      if (board is! String || salt is! String || room.local['boardRound'] != room.round) return;
      final order = (v['o'] as List?)?.cast<String>() ?? const [];
      if (order.length != 2 || !order.contains(me)) return;
      final other = order[0] == me ? order[1] : order[0];
      final pending = v['pending'];
      // الضربة عليّا: موبايلي هو اللي بيرد
      if (v['phase'] == 'fire' && v['turn'] == other && pending is int) {
        final key = '$pending@${room.round}';
        if (room.local['answered'] == key) return;
        room.local['answered'] = key;
        final theirShots = (v['shots'] as Map?)?[other] as Map? ?? const {};
        final hitBefore = <int>{
          for (final e in theirShots.entries)
            if (e.value is int && (e.value as int) > 0) int.parse('${e.key}'),
        };
        room.act({'t': 'ans', 'i': pending, 'r': BattleshipEngine.answer(board, hitBefore, pending)});
      }
      final revealed = v['revealed'];
      if (v['over'] == true && revealed is Map && !revealed.containsKey(me) && room.local['shown'] != room.round) {
        room.local['shown'] = room.round;
        room.act({'t': 'reveal', 'b': board, 's': salt});
      }
    default:
      break;
  }
}
