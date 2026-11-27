import 'dart:math';

import '../core/game_engine.dart';

/// حجر ورقة مقص — أول واحد يكسب [target] رميات.
///
/// كل رمية على مرحلتين عشان محدش يغش (ولا حتى صاحب الغرفة):
///   1. كل واحد يبعت بصمة اختياره بس: commit(اختيار، ملح).
///   2. لما الاتنين يبعتوا، كل واحد يكشف اختياره والملح، والقواعد تتأكد إنهم نفس البصمة.
/// الكشف بيحصل لوحده (شوف autoMoves) — اللاعب بيختار مرة واحدة بس.
class RpsEngine extends GameEngine {
  RpsEngine(super.players, super.rng, {this.target = 2});

  final int target;
  static const choices = ['r', 'p', 's'];

  final Map<String, String> commits = {};
  final Map<String, String> reveals = {};
  final Map<String, int> score = {};

  /// الرميات اللي خلصت: [{p1: اختيار, p2: اختيار, w: الكسبان أو null}]
  final List<Map<String, dynamic>> history = [];
  bool _over = false;
  List<String> _winners = const [];

  /// اللي كشف حاجة غير اللي كان باعت بصمتها.
  String? cheat;

  @override
  bool get over => _over;

  @override
  List<String> get winners => _winners;

  static int beats(String a, String b) {
    if (a == b) return 0;
    return (a == 'r' && b == 's') || (a == 's' && b == 'p') || (a == 'p' && b == 'r') ? 1 : -1;
  }

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (_over || !players.contains(by)) return false;
    switch (a['t']) {
      case 'commit':
        final h = a['h'];
        if (commits.containsKey(by) || h is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(h)) return false;
        commits[by] = h;
        return true;
      case 'reveal':
        if (commits.length < players.length || reveals.containsKey(by)) return false;
        final c = a['c'], s = a['s'];
        if (c is! String || s is! String || s.length > 64) return false;
        if (!choices.contains(c) || GameEngine.commit(c, s) != commits[by]) {
          // كشف حاجة غير اللي اختارها: خسر الماتش
          cheat = by;
          _over = true;
          _winners = [for (final p in players) if (p != by) p];
          return true;
        }
        reveals[by] = c;
        if (reveals.length == players.length) _resolve();
        return true;
    }
    return false;
  }

  void _resolve() {
    final a = players[0], b = players[1];
    final r = beats(reveals[a]!, reveals[b]!);
    final w = r == 0 ? null : (r > 0 ? a : b);
    history.add({a: reveals[a], b: reveals[b], 'w': w});
    if (w != null) score[w] = (score[w] ?? 0) + 1;
    commits.clear();
    reveals.clear();
    if (w != null && score[w]! >= target) {
      _over = true;
      _winners = [w];
    }
  }

  @override
  void leave(String player) {
    if (_over) return;
    _over = true;
    _winners = [for (final p in players) if (p != player) p];
  }

  @override
  Map<String, dynamic> view() => {
        'o': players,
        'over': _over,
        'win': _winners,
        'target': target,
        'phase': commits.length < players.length ? 'pick' : 'reveal',
        'ready': commits.keys.toList(),
        'shown': reveals.keys.toList(),
        's': score,
        'hist': history,
        'cheat': cheat,
        // رقم الرمية: عشان كل لاعب يعرف اختياره المحلي بتاع أنهي رمية
        'k': history.length,
      };
}

/// حرب السفن على لوح 8×8 — سفن بطول 4 و3 و3 و2.
///
/// اللوح بتاعك مبيخرجش من موبايلك: بتبعت بصمته بس في الأول، وكل ضربة عليك موبايلك هو اللي
/// بيرد عليها (مياه / إصابة / غرّقت). في الآخر الاتنين بيكشفوا اللوح والقواعد بتتأكد إن
/// محدش كدب في رد ولا غيّر سفنه.
class BattleshipEngine extends GameEngine {
  BattleshipEngine(super.players, super.rng);

  static const size = 8;
  static const ships = [4, 3, 3, 2];
  static int get shipCells => ships.fold(0, (s, x) => s + x);

  final Map<String, String> commits = {};

  /// ضربات كل لاعب على التاني: الخانة ← -1 مستني الرد • 0 مياه • 1 إصابة • 2 غرّقت.
  final Map<String, Map<int, int>> shots = {};
  final Map<String, int> hits = {};
  int turn = 0;

  /// الضربة اللي مستنية رد (عند [target]).
  int? pending;

  bool _over = false;
  List<String> _winners = const [];
  final Map<String, String> revealed = {};
  String? cheat;

  String get current => players[turn];
  String other(String p) => players[0] == p ? players[1] : players[0];

  String get phase => commits.length < 2 ? 'place' : (_over ? 'done' : 'fire');

  @override
  bool get over => _over;

  @override
  List<String> get winners => _winners;

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (!players.contains(by)) return false;
    switch (a['t']) {
      case 'ready':
        final h = a['h'];
        if (_over || commits.containsKey(by) || h is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(h)) return false;
        commits[by] = h;
        return true;
      case 'shot':
        if (_over || phase != 'fire' || by != current || pending != null) return false;
        final i = GameEngine.intOf(a['i'], max: size * size - 1);
        final mine = shots.putIfAbsent(by, () => {});
        if (i == null || mine.containsKey(i)) return false;
        mine[i] = -1;
        pending = i;
        return true;
      case 'ans':
        // الرد بييجي من صاحب اللوح اللي اتضرب
        final p = pending;
        if (_over || p == null || by != other(current)) return false;
        final r = GameEngine.intOf(a['r'], max: 2);
        if (r == null || GameEngine.intOf(a['i']) != p) return false;
        shots[current]![p] = r;
        pending = null;
        if (r > 0) {
          final h = hits[current] = (hits[current] ?? 0) + 1;
          if (h >= shipCells) {
            _over = true;
            _winners = [current];
          }
          // إصابة = تضرب تاني
        } else {
          turn = 1 - turn;
        }
        return true;
      case 'reveal':
        // بعد الآخر: كل واحد يكشف لوحه والملح
        final b = a['b'], s = a['s'];
        if (!_over || revealed.containsKey(by) || b is! String || s is! String || s.length > 64) return false;
        if (b.length != size * size || GameEngine.commit(b, s) != commits[by] || !_honest(by, b)) {
          cheat = by;
          _winners = [other(by)];
        }
        revealed[by] = b;
        return true;
    }
    return false;
  }

  /// اللوح سليم (السفن صح) وكل ردود صاحبه على الضربات كانت صادقة.
  bool _honest(String owner, String board) {
    if (!validBoard(board)) return false;
    final against = shots[other(owner)] ?? const {};
    for (final e in against.entries) {
      final ship = board[e.key] != '.';
      if (e.value == -1) continue;
      if ((e.value > 0) != ship) return false;
    }
    return true;
  }

  /// لوح نصّي 64 حرف: '.' مياه، وحرف لكل سفينة ('a'..'d') — السفن مستقيمة ومش لازقة في بعض بالطول.
  static bool validBoard(String b) {
    if (b.length != size * size) return false;
    for (var s = 0; s < ships.length; s++) {
      final ch = String.fromCharCode(97 + s);
      final cells = [for (var i = 0; i < b.length; i++) if (b[i] == ch) i];
      if (cells.length != ships[s]) return false;
      final rows = cells.map((c) => c ~/ size).toSet(), cols = cells.map((c) => c % size).toSet();
      if (rows.length == 1) {
        if (cells.last - cells.first != cells.length - 1) return false;
      } else if (cols.length == 1) {
        if (cells.last - cells.first != (cells.length - 1) * size) return false;
      } else {
        return false;
      }
    }
    for (var i = 0; i < b.length; i++) {
      final ch = b[i];
      if (ch != '.' && (ch.codeUnitAt(0) < 97 || ch.codeUnitAt(0) >= 97 + ships.length)) return false;
    }
    return true;
  }

  /// لوح عشوائي صحيح (السفن مبتلمسش بعض حتى من الجنب).
  static String randomBoard(Random rng) {
    while (true) {
      final b = List.filled(size * size, '.');
      var ok = true;
      for (var s = 0; s < ships.length && ok; s++) {
        var placed = false;
        for (var tries = 0; tries < 200 && !placed; tries++) {
          final horizontal = rng.nextBool();
          final len = ships[s];
          final r = rng.nextInt(horizontal ? size : size - len + 1);
          final c = rng.nextInt(horizontal ? size - len + 1 : size);
          final cells = [for (var k = 0; k < len; k++) horizontal ? r * size + c + k : (r + k) * size + c];
          bool free(int cell) {
            final cr = cell ~/ size, cc = cell % size;
            for (var dr = -1; dr <= 1; dr++) {
              for (var dc = -1; dc <= 1; dc++) {
                final nr = cr + dr, nc = cc + dc;
                if (nr < 0 || nc < 0 || nr >= size || nc >= size) continue;
                if (b[nr * size + nc] != '.') return false;
              }
            }
            return true;
          }

          if (cells.every(free)) {
            for (final cell in cells) {
              b[cell] = String.fromCharCode(97 + s);
            }
            placed = true;
          }
        }
        ok = placed;
      }
      if (ok) return b.join();
    }
  }

  /// موبايل صاحب اللوح بيحسب الرد على ضربة.
  static int answer(String board, Set<int> hitBefore, int cell) {
    final ch = board[cell];
    if (ch == '.') return 0;
    final shipCellsOf = [for (var i = 0; i < board.length; i++) if (board[i] == ch) i];
    final sunk = shipCellsOf.every((c) => c == cell || hitBefore.contains(c));
    return sunk ? 2 : 1;
  }

  @override
  void leave(String player) {
    if (_over) return;
    _over = true;
    _winners = [other(player)];
  }

  @override
  Map<String, dynamic> view() => {
        'o': players,
        'over': _over,
        'win': _winners,
        'phase': phase,
        'ready': commits.keys.toList(),
        'turn': _over || phase != 'fire' ? null : current,
        'pending': pending,
        'shots': {for (final e in shots.entries) e.key: {for (final s in e.value.entries) '${s.key}': s.value}},
        'revealed': revealed,
        'cheat': cheat,
      };
}
