import '../core/game_engine.dart';

/// إكس أو: لوح 3×3، أول واحد يعمل 3 في صف يكسب. اللي بيبدأ = X.
class XoEngine extends TurnEngine {
  XoEngine(super.players, super.rng);

  final List<int> board = List.filled(9, -1); // رقم اللاعب في players أو -1
  List<int>? line;

  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], //
    [0, 3, 6], [1, 4, 7], [2, 5, 8], //
    [0, 4, 8], [2, 4, 6],
  ];

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (over || by != current || a['t'] != 'put') return false;
    final i = GameEngine.intOf(a['i'], max: 8);
    if (i == null || board[i] != -1) return false;
    board[i] = turn;
    for (final l in _lines) {
      if (l.every((c) => board[c] == turn)) {
        line = l;
        finish([by]);
        return true;
      }
    }
    if (!board.contains(-1)) {
      finish(const []);
    } else {
      nextTurn();
    }
    return true;
  }

  @override
  Map<String, dynamic> view() => {...base(), 'o': players, 'b': board, 'line': line};
}

/// أربعة في صف: 7 أعمدة × 6 صفوف، القطعة بتنزل لتحت.
class Connect4Engine extends TurnEngine {
  Connect4Engine(super.players, super.rng);

  static const cols = 7, rows = 6;
  final List<int> board = List.filled(cols * rows, -1); // صف 0 = فوق
  int? last;
  List<int>? line;

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (over || by != current || a['t'] != 'drop') return false;
    final c = GameEngine.intOf(a['c'], max: cols - 1);
    if (c == null) return false;
    var r = rows - 1;
    while (r >= 0 && board[r * cols + c] != -1) {
      r--;
    }
    if (r < 0) return false; // العمود مليان
    final at = r * cols + c;
    board[at] = turn;
    last = at;
    final win = _lineThrough(r, c, turn);
    if (win != null) {
      line = win;
      finish([by]);
    } else if (!board.contains(-1)) {
      finish(const []);
    } else {
      nextTurn();
    }
    return true;
  }

  List<int>? _lineThrough(int r, int c, int who) {
    for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
      final cells = <int>[r * cols + c];
      for (final s in const [1, -1]) {
        var rr = r + dr * s, cc = c + dc * s;
        while (rr >= 0 && rr < rows && cc >= 0 && cc < cols && board[rr * cols + cc] == who) {
          cells.add(rr * cols + cc);
          rr += dr * s;
          cc += dc * s;
        }
      }
      if (cells.length >= 4) return cells;
    }
    return null;
  }

  @override
  Map<String, dynamic> view() => {...base(), 'o': players, 'b': board, 'last': last, 'line': line};
}

/// مربعات ونقط: كل واحد بدوره يرسم خط، اللي يقفل مربع ياخده ويلعب تاني.
class DotsEngine extends TurnEngine {
  DotsEngine(super.players, super.rng) : size = players.length <= 2 ? 4 : 5 {
    h = List.filled((size + 1) * size, -1);
    v = List.filled(size * (size + 1), -1);
    boxes = List.filled(size * size, -1);
    scores = List.filled(players.length, 0);
  }

  /// عدد المربعات في كل صف/عمود.
  final int size;

  /// خطوط أفقية: صف r (0..size) عمود c (0..size-1) ← r*size+c. القيمة = مين رسمه.
  late final List<int> h;

  /// خطوط رأسية: صف r (0..size-1) عمود c (0..size) ← r*(size+1)+c.
  late final List<int> v;
  late final List<int> boxes;
  late final List<int> scores;
  String? lastLine;

  bool _closed(int r, int c) =>
      h[r * size + c] != -1 && h[(r + 1) * size + c] != -1 && v[r * (size + 1) + c] != -1 && v[r * (size + 1) + c + 1] != -1;

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (over || by != current || a['t'] != 'line') return false;
    final horizontal = a['h'] == true;
    final i = GameEngine.intOf(a['i'], max: horizontal ? h.length - 1 : v.length - 1);
    if (i == null) return false;
    final lines = horizontal ? h : v;
    if (lines[i] != -1) return false;
    lines[i] = turn;
    lastLine = '${horizontal ? 'h' : 'v'}$i';
    // المربعات اللي الخط ده ممكن يقفلها
    final candidates = <(int, int)>[];
    if (horizontal) {
      final r = i ~/ size, c = i % size;
      if (r > 0) candidates.add((r - 1, c));
      if (r < size) candidates.add((r, c));
    } else {
      final r = i ~/ (size + 1), c = i % (size + 1);
      if (c > 0) candidates.add((r, c - 1));
      if (c < size) candidates.add((r, c));
    }
    var gained = 0;
    for (final (r, c) in candidates) {
      if (boxes[r * size + c] == -1 && _closed(r, c)) {
        boxes[r * size + c] = turn;
        scores[turn]++;
        gained++;
      }
    }
    if (!boxes.contains(-1)) {
      finish(bestOf(scores));
    } else if (gained == 0) {
      nextTurn();
    }
    return true;
  }

  @override
  Map<String, dynamic> view() => {
        ...base(),
        'o': players,
        'n': size,
        'h': h,
        'v': v,
        'box': boxes,
        's': scores,
        'last': lastLine,
      };
}

/// الذاكرة: تقلب كارتين، لو شبه بعض تاخدهم وتلعب تاني، ولو لأ يتقلبوا والدور يروح.
/// الصور = أرقام الأفاتارات الكرتون (0..23).
class MemoryEngine extends TurnEngine {
  MemoryEngine(super.players, super.rng) : pairs = players.length <= 2 ? 8 : 12 {
    final faces = List.generate(24, (i) => i)..shuffle(rng);
    cards = [for (final f in faces.take(pairs)) ...[f, f]]..shuffle(rng);
    owner = List.filled(cards.length, -1);
    scores = List.filled(players.length, 0);
  }

  final int pairs;
  late final List<int> cards;
  late final List<int> owner;
  late final List<int> scores;

  /// الكروت المقلوبة دلوقتي (0 أو 1 أو 2).
  final List<int> open = [];

  /// كارتين مش شبه بعض: بيفضلوا ظاهرين لحد الوقت ده وبعدين يتقلبوا.
  DateTime? hideAt;
  static Duration showMiss = const Duration(milliseconds: 1500);

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (over || by != current || a['t'] != 'flip' || hideAt != null) return false;
    final i = GameEngine.intOf(a['i'], max: cards.length - 1);
    if (i == null || owner[i] != -1 || open.contains(i) || open.length >= 2) return false;
    open.add(i);
    if (open.length < 2) return true;
    if (cards[open[0]] == cards[open[1]]) {
      owner[open[0]] = turn;
      owner[open[1]] = turn;
      scores[turn]++;
      open.clear();
      if (!owner.contains(-1)) finish(bestOf(scores));
    } else {
      hideAt = DateTime.now().add(showMiss);
    }
    return true;
  }

  @override
  bool tick(DateTime now) {
    final at = hideAt;
    if (at == null || now.isBefore(at)) return false;
    hideAt = null;
    open.clear();
    nextTurn();
    return true;
  }

  @override
  Map<String, dynamic> view() => {
        ...base(),
        'o': players,
        // الصورة بتظهر بس للكروت المقلوبة أو اللي اتاخدت
        'c': [for (var i = 0; i < cards.length; i++) if (owner[i] != -1 || open.contains(i)) cards[i] else -1],
        'own': owner,
        'open': open,
        's': scores,
        'miss': hideAt != null,
      };
}
