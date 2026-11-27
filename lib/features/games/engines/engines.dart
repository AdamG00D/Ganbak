import 'dart:math';

import '../core/fair_deal.dart';
import '../core/game_engine.dart';
import '../core/game_kind.dart';
import '../core/game_room.dart';
import '../data/quiz_bank.dart';
import '../data/spy_words.dart';
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
    case GameKind.spy:
      spyMoves(room);
    case GameKind.mafia:
      mafiaCheck(room);
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

/// التوزيع العادل في "مين الجاسوس" على موبايلي: أدّي عمودي، أخلط، أفك، أعرف دوري، وأكشف لما يتطلب.
/// أسراري في room.local['deal@<ماتش>'] ودوري في room.local['role@<ماتش>'] = {spy: bool, w: رقم الكلمة}.
void spyMoves(GameRoom room) {
  final v = room.view;
  final me = room.myId;
  final order = [for (final x in (v['o'] as List? ?? const [])) if (x is String) x];
  final n = order.length;
  final idx = order.indexOf(me);
  if (idx < 0 || n < 3) return;
  final r = room.round;
  final key = 'deal@$r';
  var sec = DealSecrets.fromJson(room.local[key], n);
  bool once(String what) {
    final k = '$what@$r';
    if (room.local[k] == true) return false;
    room.local[k] = true;
    return true;
  }

  switch (v['phase']) {
    case 'give':
      final given = v['given'];
      if (given is List && given.contains(me)) return;
      if (sec == null) {
        sec = DealSecrets.random(n);
        room.local[key] = sec.toJson();
      }
      if (!once('gave')) return;
      room.act({
        't': 'give',
        'col': [for (final x in sec.column()) FairDeal.enc(x)],
        'bh': FairDeal.hashPoint(sec.blank),
        'bx': sec.boxes(),
        'pk': FairDeal.enc(FairDeal.mul(sec.e, FairDeal.base)),
      });
    case 'mix' || 'strip' when v['step'] == me && sec != null:
      final m = FairDeal.matrixFrom(v['m'], n);
      if (m == null || !once('${v['phase']}')) return;
      final out = v['phase'] == 'mix' ? sec.mix(m, idx) : sec.strip(m, idx);
      room.act({'t': v['phase'], 'm': FairDeal.matrixTo(out)});
  }
  // بعد الفك: أعرف دوري من صفي (مرة واحدة)
  final phase = v['phase'];
  if (sec != null && room.local['role@$r'] == null && phase != 'give' && phase != 'mix' && phase != 'strip') {
    final m = FairDeal.matrixFrom(v['m'], n);
    final bh = v['bh'], bx = v['bx'];
    if (m != null && bh is List && bx is List && bh.length == n && bx.length == n) {
      final opened = sec.open(
        m[idx],
        [for (final h in bh) '$h'],
        [for (final b in bx) b is Map ? {for (final e in b.entries) '${e.key}': '${e.value}'} : <String, String>{}],
      );
      if (opened != null) {
        final words = SpyWords.categories[v['cat']]?.length ?? 15;
        room.local['role@$r'] = {'spy': opened.$1, 'w': opened.$1 ? null : dealWord(opened.$2, words)};
      }
    }
  }
  if (sec == null) return;
  if (phase == 'prove' && v['caught'] == me && once('proved')) room.act({'t': 'prove', 'e': sec.e.toRadixString(16)});
  if (phase == 'open' && once('opened')) room.act({'t': 'open', 's': sec.toJson()});
}

/// المافيا: بنحفظ بصمة الأدوار ودوري من أول ما وصلوا، وفي الآخر بنتأكد إن الأدوار اللي اتكشفت هي هي
/// (room.local['rolesOk@<ماتش>'] = true / false).
void mafiaCheck(GameRoom room) {
  final v = room.view;
  final r = room.round;
  final rc = v['rc'];
  if (rc is String && room.local['rc@$r'] == null) room.local['rc@$r'] = rc;
  final mine = room.secret['role'];
  if (mine is String && room.local['myRole@$r'] == null) room.local['myRole@$r'] = mine;
  if (v['over'] != true || room.local['rolesOk@$r'] != null) return;
  final roles = v['roles'], salt = v['rs'], first = room.local['rc@$r'];
  if (roles is! Map || salt is! String || first is! String) return;
  final order = [for (final x in (v['o'] as List? ?? const [])) if (x is String) x];
  var ok = GameEngine.commit(MafiaEngine.rolesText(order, roles), salt) == first;
  final myRole = room.local['myRole@$r'];
  if (room.joined && myRole is String && roles[room.myId] != myRole) ok = false;
  room.local['rolesOk@$r'] = ok;
}
