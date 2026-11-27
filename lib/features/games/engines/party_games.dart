import 'dart:math';

import '../core/fair_deal.dart';
import '../core/game_engine.dart';
import '../core/game_room.dart';
import '../data/quiz_bank.dart';
import '../data/spy_words.dart';

/// اختيار من ضمن ناس (تصويت / ليل المافيا): معرّف واحد منهم أو null.
String? _pick(Map<String, dynamic> a, Iterable<String> allowed) {
  final f = a['for'];
  return f is String && allowed.contains(f) ? f : null;
}

/// أكتر حد اتختار. لو فيه تعادل على الأول = null.
String? _top(Iterable<String> votes) {
  final count = <String, int>{};
  for (final v in votes) {
    count[v] = (count[v] ?? 0) + 1;
  }
  if (count.isEmpty) return null;
  final best = count.values.reduce(max);
  final tops = [for (final e in count.entries) if (e.value == best) e.key];
  return tops.length == 1 ? tops.first : null;
}

Map<String, int> _tally(Iterable<String> votes) {
  final count = <String, int>{};
  for (final v in votes) {
    count[v] = (count[v] ?? 0) + 1;
  }
  return count;
}

// =====================================================================
// مين الجاسوس
// =====================================================================

/// الكل بياخد نفس الكلمة إلا واحد (الجاسوس) بياخد الفئة بس.
/// توزيع عادل ← تلميحات بالدور ← تصويت ← اللي اتمسك يكشف كارته ← لو جاسوس يخمّن الكلمة ← الكل يكشف ونتأكد.
///
/// صاحب الغرفة مبيعرفش مين الجاسوس ولا الكلمة: الأدوار بتتوزع بـ [FairDeal] (كل موبايل بيخلط ويفك دوره)،
/// وكل لاعب بيعرف دوره لوحده. صاحب الغرفة بس بينظّم الخطوات، وفي الآخر الكل بيكشف أسراره والنتيجة بتتحسب
/// وبتتأكد على كل الموبايلات.
class SpyEngine extends GameEngine {
  SpyEngine(super.players, super.rng) {
    final cats = SpyWords.categoryKeys;
    category = cats[rng.nextInt(cats.length)];
    words = SpyWords.categories[category]!;
    // 4 لاعبين أو أقل: لفّتين تلميحات
    rounds = players.length <= 4 ? 2 : 1;
    stepEnds = DateTime.now().add(dealTime);
  }

  late final String category;
  late final List<String> words;
  late final int rounds;

  /// give ← mix ← strip ← clue ← vote ← prove ← guess ← open ← done
  String phase = 'give';

  // ---- التوزيع ----
  final Map<String, List<String>> _cols = {};
  final Map<String, String> blankHash = {};
  final Map<String, Map<String, String>> boxes = {};

  /// المفتاح العام لكل لاعب (e·G) — عشان محدش يكشف مفتاح غير بتاعه.
  final Map<String, String> pk = {};
  List<List<String>>? matrix;
  int chain = 0;
  DateTime? stepEnds;
  static Duration dealTime = const Duration(seconds: 45);

  // ---- اللعب ----
  int turn = 0;
  int clueCount = 0;
  final Map<String, String> votes = {};
  final Set<String> gone = {};
  String? caught;

  /// اللي اتمسك كشف كارته: spy / not / cheat.
  String? proved;
  int? guess;
  DateTime? voteEnds, proveEnds, guessEnds, openEnds;
  static Duration voteTime = const Duration(seconds: 60);
  static Duration guessTime = const Duration(seconds: 45);
  static Duration revealTime = const Duration(seconds: 30);

  // ---- الآخر ----
  final Map<String, Map<String, dynamic>> opened = {};
  String? spy;
  int? word;
  final Set<String> cheats = {};
  bool _over = false;
  bool failed = false;
  List<String> _winners = const [];

  @override
  bool get over => _over;

  @override
  List<String> get winners => _winners;

  int get n => players.length;
  List<String> get _active => [for (final p in players) if (!gone.contains(p)) p];
  String get current => players[turn % n];

  void _fail() {
    _over = true;
    failed = true;
    phase = 'done';
    _winners = const [];
  }

  bool _validMatrix(Object? raw) => FairDeal.matrixFrom(raw, n) != null;

  void _next() {
    chain++;
    stepEnds = DateTime.now().add(dealTime);
    if (chain < n) return;
    chain = 0;
    if (phase == 'mix') {
      phase = 'strip';
    } else {
      phase = 'clue';
      stepEnds = null;
      _skipGone();
    }
  }

  void _skipGone() {
    for (var k = 0; k < n && gone.contains(current); k++) {
      turn++;
    }
  }

  void _startVote() {
    phase = 'vote';
    voteEnds = DateTime.now().add(voteTime);
  }

  void _count() {
    caught = _top(votes.values);
    if (caught == null) {
      _startOpen();
    } else {
      phase = 'prove';
      proveEnds = DateTime.now().add(revealTime);
    }
  }

  void _startOpen() {
    phase = 'open';
    openEnds = DateTime.now().add(revealTime);
    if (opened.length >= _active.length) _finish();
  }

  /// اللي اتمسك كشف مفتاحه: بنفك صفه ونشوف هو الجاسوس ولا لأ.
  void _prove(String who, BigInt e) {
    final row = players.indexOf(who);
    final m = FairDeal.matrixFrom(matrix, n);
    if (m == null) return;
    final plain = [for (final x in m[row]) FairDeal.mul(FairDeal.inverse(e), x)];
    final blank = [for (var c = 0; c < n; c++) FairDeal.hashPoint(plain[c]) == blankHash[players[c]]];
    final share = [for (var c = 0; c < n; c++) boxes[players[c]]!.containsKey(DealSecrets.tag(plain[c]))];
    if (blank.every((b) => b)) {
      proved = 'spy';
      spy = who;
      phase = 'guess';
      guessEnds = DateTime.now().add(guessTime);
    } else {
      proved = share.every((b) => b) ? 'not' : 'cheat';
      if (proved == 'cheat') cheats.add(who);
      _startOpen();
    }
  }

  void _finish() {
    final secrets = <DealSecrets>[];
    for (final p in players) {
      final s = DealSecrets.fromJson(opened[p], n);
      if (s == null) {
        cheats.add(p);
      } else {
        secrets.add(s);
      }
    }
    final m = FairDeal.matrixFrom(matrix, n);
    (int, int)? check;
    if (secrets.length == n && m != null) {
      check = DealCheck.verify(
        finalMatrix: m,
        secrets: secrets,
        blankHashes: [for (final p in players) blankHash[p]!],
        boxes: [for (final p in players) boxes[p]!],
        wordCount: words.length,
      );
      if (check == null) failed = true;
    }
    _over = true;
    phase = 'done';
    if (check != null) {
      spy = players[check.$1];
      word = check.$2;
    }
    final s = spy;
    if (s == null) {
      // مش عارفين مين الجاسوس (حد مكشفش أو غش): محدش كسب
      _winners = const [];
      return;
    }
    final others = [for (final p in players) if (p != s && !cheats.contains(p)) p];
    if (proved == 'spy') {
      _winners = word != null && guess == word ? [s] : others;
    } else if (cheats.contains(s)) {
      _winners = others;
    } else {
      _winners = [s];
    }
  }

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (_over || !players.contains(by)) return false;
    switch (a['t']) {
      case 'give' when phase == 'give' && !_cols.containsKey(by):
        final col = a['col'], bh = a['bh'], bx = a['bx'], key = a['pk'];
        if (col is! List || col.length != n || !col.every((x) => FairDeal.dec(x) != null)) return false;
        if (bh is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(bh) || FairDeal.dec(key) == null) return false;
        if (bx is! Map || bx.length != n - 1) return false;
        final box = <String, String>{};
        for (final e in bx.entries) {
          if (e.key is! String || e.value is! String) return false;
          if (!RegExp(r'^[0-9a-f]{16}$').hasMatch(e.key as String) || !RegExp(r'^[0-9a-f]{16}$').hasMatch(e.value as String)) {
            return false;
          }
          box[e.key as String] = e.value as String;
        }
        _cols[by] = col.cast<String>();
        blankHash[by] = bh;
        boxes[by] = box;
        pk[by] = key as String;
        if (_cols.length == n) {
          matrix = [for (var r = 0; r < n; r++) [for (final p in players) _cols[p]![r]]];
          phase = 'mix';
          chain = 0;
          stepEnds = DateTime.now().add(dealTime);
        }
        return true;
      case 'mix' || 'strip' when phase == a['t'] && by == players[chain]:
        if (!_validMatrix(a['m'])) return false;
        matrix = [for (final r in a['m'] as List) [for (final x in r as List) x as String]];
        _next();
        return true;
      case 'done' when phase == 'clue':
        // اللي عليه الدور خلّص تلميحه (أو صاحب الغرفة بيعدّي دوره)
        if (by != current && by != host) return false;
        clueCount++;
        turn++;
        _skipGone();
        if (clueCount >= _active.length * rounds) _startVote();
        return true;
      case 'skip' when phase == 'clue' && by == host:
        _startVote();
        return true;
      case 'vote' when phase == 'vote' && !gone.contains(by):
        final f = _pick(a, _active.where((p) => p != by));
        if (f == null) return false;
        votes[by] = f;
        if (votes.length >= _active.length) _count();
        return true;
      case 'prove' when phase == 'prove' && by == caught:
        final e = BigInt.tryParse('${a['e']}', radix: 16);
        if (e == null || e <= BigInt.one || e >= FairDeal.order) return false;
        // المفتاح لازم يطابق اللي أعلنه في الأول (محدش يكشف مفتاح مزيف)
        if (FairDeal.enc(FairDeal.mul(e, FairDeal.base)) != pk[by]) return false;
        _prove(by, e);
        return true;
      case 'guess' when phase == 'guess' && by == spy:
        final i = GameEngine.intOf(a['i'], max: words.length - 1);
        if (i == null) return false;
        guess = i;
        _startOpen();
        return true;
      case 'open' when phase == 'open' && !opened.containsKey(by):
        final s = DealSecrets.fromJson(a['s'], n);
        if (s == null || FairDeal.enc(FairDeal.mul(s.e, FairDeal.base)) != pk[by]) return false;
        opened[by] = s.toJson();
        if (opened.length >= _active.length) _finish();
        return true;
    }
    return false;
  }

  @override
  bool tick(DateTime now) {
    final ends = stepEnds;
    if ((phase == 'give' || phase == 'mix' || phase == 'strip') && ends != null && now.isAfter(ends)) {
      _fail();
      return true;
    }
    if (phase == 'vote' && voteEnds != null && now.isAfter(voteEnds!)) {
      _count();
      return true;
    }
    if (phase == 'prove' && proveEnds != null && now.isAfter(proveEnds!)) {
      // رفض يكشف كارته: بنعتبره الجاسوس واتمسك
      cheats.add(caught!);
      proved = 'spy';
      spy = caught;
      _startOpen();
      return true;
    }
    if (phase == 'guess' && guessEnds != null && now.isAfter(guessEnds!)) {
      _startOpen();
      return true;
    }
    if (phase == 'open' && openEnds != null && now.isAfter(openEnds!)) {
      _finish();
      return true;
    }
    return false;
  }

  @override
  void leave(String player) {
    if (_over || !players.contains(player)) return;
    if (phase == 'give' || phase == 'mix' || phase == 'strip') {
      _fail();
      return;
    }
    gone.add(player);
    votes.remove(player);
    votes.removeWhere((_, v) => v == player);
    if (_active.length < 3) {
      _fail();
    } else if (phase == 'clue') {
      _skipGone();
    } else if (phase == 'vote' && votes.length >= _active.length) {
      _count();
    } else if (phase == 'open' && opened.length >= _active.length) {
      _finish();
    }
  }

  Map<String, dynamic>? _left() {
    final DateTime? ends = switch (phase) {
      'give' || 'mix' || 'strip' => stepEnds,
      'vote' => voteEnds,
      'prove' => proveEnds,
      'guess' => guessEnds,
      'open' => openEnds,
      _ => null,
    };
    return ends == null ? null : {'left': ends.difference(DateTime.now()).inMilliseconds};
  }

  @override
  Map<String, dynamic> view() => {
        'o': players,
        'over': _over,
        'win': _winners,
        'phase': phase,
        'cat': category,
        'gone': gone.toList(),
        ...?_left(),
        if (phase == 'give') 'given': _cols.keys.toList(),
        if (phase == 'mix' || phase == 'strip') 'step': players[chain],
        if (phase == 'mix' || phase == 'strip') 'chain': chain,
        if (matrix != null) 'm': matrix,
        if (matrix != null) 'bh': [for (final p in players) blankHash[p]],
        if (matrix != null) 'bx': [for (final p in players) boxes[p]],
        if (matrix != null) 'pk': pk,
        'turn': phase == 'clue' ? current : null,
        'clue': clueCount,
        'clues': _active.length * rounds,
        'voted': votes.keys.toList(),
        if (caught != null) 'caught': caught,
        'proved': ?proved,
        if (phase == 'guess') 'options': words,
        if (_over) ...{
          'spy': spy,
          'word': word == null ? null : words[word!],
          'votes': votes,
          'guess': guess == null ? null : words[guess!],
          'secrets': opened,
          'cheat': cheats.toList(),
          'failed': failed,
        },
      };
}

// =====================================================================
// المسابقة
// =====================================================================

/// أسئلة باختيارات، 15 ثانية لكل سؤال، نقط على الصح والسرعة.
/// الإجابات بتروح لصاحب الغرفة بس (مقفولة) وبتتكشف للكل بعد ما السؤال يخلص.
class QuizEngine extends GameEngine {
  QuizEngine(super.players, super.rng, {String? category, int count = 10}) {
    final pool = [for (final q in QuizBank.all) if (category == null || q.category == category) q]..shuffle(rng);
    questions = pool.take(count).toList();
    for (final q in questions) {
      // الصح أول واحد في البنك: نلخبط ونفتكر مكانه
      final order = List.generate(q.options.length, (i) => i)..shuffle(rng);
      shuffled.add([for (final i in order) q.options[i]]);
      correct.add(order.indexOf(0));
    }
    for (final p in players) {
      score[p] = 0;
    }
    _ask();
  }

  late final List<QuizQuestion> questions;
  final List<List<String>> shuffled = [];
  final List<int> correct = [];

  static Duration answerTime = const Duration(seconds: 15);
  static Duration showTime = const Duration(seconds: 5);

  int index = 0;

  /// q = السؤال ظاهر • a = الإجابة ظاهرة • done
  String phase = 'q';
  DateTime _until = DateTime.now();
  final Map<String, (int, int)> answers = {}; // اللاعب ← (الاختيار، الوقت بالملّي)
  final Map<String, int> score = {};
  Map<String, int> gained = {};
  bool _over = false;
  List<String> _winners = const [];

  @override
  bool get over => _over;

  @override
  List<String> get winners => _winners;

  void _ask() {
    phase = 'q';
    answers.clear();
    _until = DateTime.now().add(answerTime);
  }

  void _close() {
    phase = 'a';
    gained = {};
    for (final e in answers.entries) {
      final (choice, ms) = e.value;
      if (choice != correct[index]) continue;
      // 500 على الإجابة الصح + لحد 500 على السرعة
      final speed = (500 * (1 - ms / answerTime.inMilliseconds)).clamp(0, 500).round();
      gained[e.key] = 500 + speed;
      score[e.key] = (score[e.key] ?? 0) + 500 + speed;
    }
    _until = DateTime.now().add(showTime);
  }

  void _next() {
    index++;
    if (index >= questions.length) {
      _over = true;
      phase = 'done';
      final best = score.values.isEmpty ? 0 : score.values.reduce(max);
      final w = [for (final e in score.entries) if (e.value == best && best > 0) e.key];
      _winners = w.length == players.length && players.length > 1 ? const [] : w;
      return;
    }
    _ask();
  }

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (_over || !players.contains(by) || a['t'] != 'ans' || phase != 'q') return false;
    if (GameEngine.intOf(a['q']) != index || answers.containsKey(by)) return false;
    final i = GameEngine.intOf(a['i'], max: 3);
    // الوقت بيتحسب على موبايل اللاعب (من ساعة ما السؤال ظهر عنده) عشان التأخير ميظلمش حد
    final ms = GameEngine.intOf(a['ms'], max: answerTime.inMilliseconds) ?? answerTime.inMilliseconds;
    if (i == null) return false;
    answers[by] = (i, ms);
    if (answers.length == players.length) _close();
    return true;
  }

  @override
  bool tick(DateTime now) {
    if (_over || now.isBefore(_until)) return false;
    if (phase == 'q') {
      _close();
    } else {
      _next();
    }
    return true;
  }

  @override
  void leave(String player) {
    players.remove(player);
    if (players.isEmpty) {
      _over = true;
      return;
    }
    if (phase == 'q' && answers.length >= players.length) _close();
  }

  @override
  Map<String, dynamic> view() {
    final q = _over ? null : questions[index];
    return {
      'o': players,
      'over': _over,
      'win': _winners,
      'phase': phase,
      'i': index,
      'count': questions.length,
      if (q != null) 'q': q.question,
      if (q != null) 'opts': shuffled[index],
      if (q != null) 'cat': q.category,
      'left': _over ? null : _until.difference(DateTime.now()).inMilliseconds,
      'answered': answers.keys.toList(),
      if (phase == 'a') 'right': correct[index],
      if (phase == 'a') 'picks': {for (final e in answers.entries) e.key: e.value.$1},
      if (phase == 'a') 'gain': gained,
      's': score,
    };
  }
}

// =====================================================================
// المافيا
// =====================================================================

/// المافيا: ليل (المافيا تختار ضحية، الدكتور يحمي، المحقق يسأل) ← الصبح (إعلان) ←
/// نقاش ← تصويت (اللي يطلع بيتكشف دوره) ← ليل تاني. صاحب الغرفة هو الراوي (موبايله).
class MafiaEngine extends GameEngine implements SecretChat {
  MafiaEngine(super.players, super.rng) {
    final n = players.length;
    final mafiaCount = n <= 7 ? 1 : (n <= 11 ? 2 : 3);
    final shuffled = List.of(players)..shuffle(rng);
    for (var i = 0; i < n; i++) {
      roles[shuffled[i]] = i < mafiaCount
          ? 'mafia'
          : i == mafiaCount
              ? 'doctor'
              : i == mafiaCount + 1
                  ? 'detective'
                  : 'citizen';
    }
    alive.addAll(players);
    // بصمة مقفولة للأدوار من الأول — في الآخر بتتكشف وكل موبايل بيتأكد إنها متغيرتش في النص
    rolesSalt = GameEngine.newSalt();
    rolesCommit = GameEngine.commit(rolesText(players, roles), rolesSalt);
    _night();
  }

  late final String rolesSalt;
  late final String rolesCommit;

  /// شكل ثابت للأدوار عشان البصمة.
  static String rolesText(List<String> players, Map<Object?, Object?> roles) =>
      ([for (final p in players) '$p:${roles[p]}']..sort()).join(',');

  static Duration nightTime = const Duration(seconds: 60);
  static Duration morningTime = const Duration(seconds: 8);
  static Duration talkTime = const Duration(minutes: 3);
  static Duration voteTime = const Duration(seconds: 60);

  final Map<String, String> roles = {};
  final Set<String> alive = {};

  /// night ← morning ← talk ← vote ← (out) ← night ... ← done
  String phase = 'night';
  int day = 0;
  DateTime _until = DateTime.now();

  // الليل
  final Map<String, String> kills = {}; // مافيا ← اختيارها
  String? saved;
  String? lastSaved; // الدكتور ميحميش نفس الشخص ليلتين ورا بعض
  String? checked;
  final Map<String, List<(String, bool)>> checks = {}; // المحقق ← (مين، مافيا؟)

  // نتيجة الليل
  String? died;
  bool rescued = false;

  // النهار
  final Map<String, String> votes = {}; // 'none' = محدش
  String? out;

  bool _over = false;
  List<String> _winners = const [];
  String? winSide;

  @override
  bool get over => _over;

  @override
  List<String> get winners => _winners;

  bool _isMafia(String p) => roles[p] == 'mafia';
  Iterable<String> get _aliveMafia => alive.where(_isMafia);
  String? _aliveRole(String role) => alive.where((p) => roles[p] == role).firstOrNull;

  void _night() {
    phase = 'night';
    day++;
    kills.clear();
    saved = null;
    checked = null;
    _until = DateTime.now().add(nightTime);
  }

  /// الليل خلص لو كل اللي عندهم دور بالليل عملوه.
  bool get _nightDone {
    if (_aliveMafia.any((m) => !kills.containsKey(m))) return false;
    if (_aliveRole('doctor') != null && saved == null) return false;
    if (_aliveRole('detective') != null && checked == null) return false;
    return true;
  }

  void _dawn() {
    final target = _top(kills.values) ?? (kills.values.isEmpty ? null : kills.values.first);
    died = null;
    rescued = false;
    if (target != null) {
      if (target == saved) {
        rescued = true;
      } else {
        alive.remove(target);
        died = target;
      }
    }
    lastSaved = saved;
    phase = 'morning';
    _until = DateTime.now().add(morningTime);
    _checkWin();
  }

  void _startVote() {
    phase = 'vote';
    votes.clear();
    _until = DateTime.now().add(voteTime);
  }

  void _countVotes() {
    final real = votes.values.where((v) => v != 'none');
    final t = _tally(votes.values);
    final top = _top(votes.values);
    out = top == null || top == 'none' || real.isEmpty || (t[top] ?? 0) < 1 ? null : top;
    if (out != null) alive.remove(out);
    phase = 'out';
    _until = DateTime.now().add(morningTime);
    _checkWin();
  }

  void _checkWin() {
    final mafia = _aliveMafia.length;
    final town = alive.length - mafia;
    if (mafia == 0) {
      winSide = 'town';
    } else if (mafia >= town) {
      winSide = 'mafia';
    } else {
      return;
    }
    _over = true;
    phase = 'done';
    _winners = [for (final p in players) if ((roles[p] == 'mafia') == (winSide == 'mafia')) p];
  }

  @override
  bool act(String by, Map<String, dynamic> a) {
    if (_over || !players.contains(by)) return false;
    final t = a['t'];
    if (t == 'skip' && by == host) {
      // صاحب الغرفة بيختصر الوقت (النقاش أو الصبح)
      if (phase == 'talk') {
        _startVote();
        return true;
      }
      if (phase == 'morning' || phase == 'out') return tick(DateTime.now().add(const Duration(days: 1)));
      return false;
    }
    if (!alive.contains(by)) return false;
    switch (phase) {
      case 'night':
        final role = roles[by];
        if (t == 'kill' && role == 'mafia') {
          final f = _pick(a, alive.where((p) => !_isMafia(p)));
          if (f == null) return false;
          kills[by] = f;
        } else if (t == 'save' && role == 'doctor') {
          final f = _pick(a, alive.where((p) => p != lastSaved));
          if (f == null || saved != null) return false;
          saved = f;
        } else if (t == 'check' && role == 'detective') {
          final f = _pick(a, alive.where((p) => p != by));
          if (f == null || checked != null) return false;
          checked = f;
          checks.putIfAbsent(by, () => []).add((f, _isMafia(f)));
        } else {
          return false;
        }
        if (_nightDone) _dawn();
        return true;
      case 'vote':
        if (t != 'vote') return false;
        final f = a['for'] == 'none' ? 'none' : _pick(a, alive.where((p) => p != by));
        if (f == null) return false;
        votes[by] = f;
        if (votes.length >= alive.length) _countVotes();
        return true;
    }
    return false;
  }

  @override
  bool tick(DateTime now) {
    if (_over || now.isBefore(_until)) return false;
    switch (phase) {
      case 'night':
        _dawn();
      case 'morning':
        phase = 'talk';
        _until = DateTime.now().add(talkTime);
      case 'talk':
        _startVote();
      case 'vote':
        _countVotes();
      case 'out':
        _night();
    }
    return true;
  }

  @override
  void leave(String player) {
    if (_over || !alive.remove(player)) return;
    kills.remove(player);
    votes.remove(player);
    _checkWin();
    if (_over) return;
    if (phase == 'night' && _nightDone) _dawn();
    if (phase == 'vote' && votes.length >= alive.length) _countVotes();
  }

  @override
  List<String> secretChatOf(String from) =>
      phase == 'night' && alive.contains(from) && _isMafia(from) ? _aliveMafia.toList() : const [];

  @override
  Map<String, dynamic> view() {
    final dead = [for (final p in players) if (!alive.contains(p)) p];
    return {
      'o': players,
      'over': _over,
      'win': _winners,
      'phase': phase,
      'day': day,
      'alive': alive.toList(),
      'left': _over ? null : _until.difference(DateTime.now()).inMilliseconds,
      // بالليل محدش يتكلم في الشات العام، والميتين ميتكلموش خالص
      'mute': phase == 'night' ? players : dead,
      if (phase != 'night') 'died': died,
      if (phase != 'night') 'rescued': rescued,
      if (phase == 'vote') 'voted': votes.keys.toList(),
      if (phase == 'out' || phase == 'done') ...{
        'votes': votes,
        'out': out,
      },
      // اللي مات أو خرج دوره بيتكشف
      'roles': _over ? roles : {for (final p in dead) p: roles[p]},
      'rc': rolesCommit,
      if (_over) 'rs': rolesSalt,
      if (_over) 'side': winSide,
    };
  }

  @override
  Map<String, dynamic>? viewFor(String player) {
    final role = roles[player];
    if (role == null) return null;
    return {
      'role': role,
      if (role == 'mafia') 'team': [for (final p in players) if (_isMafia(p)) p],
      if (role == 'mafia' && phase == 'night') 'kills': kills,
      if (role == 'doctor') 'saved': saved,
      if (role == 'doctor') 'noSave': lastSaved,
      if (role == 'detective') 'checked': checked,
      if (role == 'detective') 'checks': [for (final (who, bad) in checks[player] ?? const <(String, bool)>[]) [who, bad]],
      if (phase == 'vote') 'myVote': votes[player],
    };
  }
}
