import 'dart:convert';
import 'dart:math';

import 'package:cryptography/dart.dart';

/// قواعد لعبة — بتشتغل على موبايل صاحب الغرفة بس.
///
/// اللاعبين بيبعتوا "حركات" ([act])، وصاحب الغرفة بيطبّقها لو مسموحة وبيبعت للكل الحالة الجديدة
/// ([view]) — ولكل لاعب حاجته السرية لو فيه ([viewFor]). الشاشات بترسم من الحالة دي بس.
abstract class GameEngine {
  GameEngine(this.players, this.rng);

  /// اللاعبين بالترتيب (أول واحد بيبدأ).
  final List<String> players;
  final Random rng;

  /// صاحب الغرفة (بيقدر يعدّي الأدوار ويختصر الوقت).
  String? host;

  /// الحالة اللي الكل يشوفها.
  Map<String, dynamic> view();

  /// حاجة سرية للاعب ده بس (دوره، الكلمة...). null = مفيش.
  Map<String, dynamic>? viewFor(String player) => null;

  /// حركة من لاعب. يرجّع true لو الحالة اتغيرت.
  bool act(String by, Map<String, dynamic> a);

  /// للألعاب اللي فيها وقت: بيتنادى كل ثانية تقريباً. يرجّع true لو الحالة اتغيرت.
  bool tick(DateTime now) => false;

  /// لاعب خرج من الغرفة وهي شغالة.
  void leave(String player) {}

  bool get over;

  /// الكسبانين (فاضية = تعادل).
  List<String> get winners;

  // ---------------- أدوات مشتركة ----------------

  /// بصمة لـ "اختيار مقفول": sha256(القيمة|الملح) بالهيكس.
  static String commit(String value, String salt) {
    final h = const DartSha256().hashSync(utf8.encode('wasl/game/commit|$value|$salt'));
    return h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String newSalt([Random? r]) {
    final rng = r ?? Random.secure();
    return List.generate(16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static int? intOf(Object? v, {int min = 0, int max = 1 << 30}) {
    if (v is! num) return null;
    final i = v.toInt();
    return i < min || i > max ? null : i;
  }
}

/// ألعاب بالدور بين لاعبين (اكس أو، أربعة في صف، مربعات...).
abstract class TurnEngine extends GameEngine {
  TurnEngine(super.players, super.rng);

  int turn = 0;
  bool _over = false;
  List<String> _winners = const [];

  String get current => players[turn % players.length];

  @override
  bool get over => _over;

  @override
  List<String> get winners => _winners;

  void finish(List<String> winners) {
    _over = true;
    _winners = winners;
  }

  /// اللي خرجوا وهي شغالة (دورهم بيتنط).
  final Set<String> gone = {};

  void nextTurn() {
    for (var k = 0; k < players.length; k++) {
      turn = (turn + 1) % players.length;
      if (!gone.contains(current)) return;
    }
  }

  /// الكسبانين = أعلى نقط من اللي لسه موجودين (لو الكل متعادل = تعادل).
  List<String> bestOf(List<int> scores) {
    final here = [for (var k = 0; k < players.length; k++) if (!gone.contains(players[k])) k];
    if (here.isEmpty) return const [];
    final best = here.map((k) => scores[k]).reduce((x, y) => x > y ? x : y);
    final w = [for (final k in here) if (scores[k] == best) players[k]];
    return w.length == here.length && here.length > 1 ? const [] : w;
  }

  @override
  void leave(String player) {
    if (_over || !players.contains(player) || gone.contains(player)) return;
    gone.add(player);
    final left = [for (final p in players) if (!gone.contains(p)) p];
    if (left.length < 2) {
      finish(left);
    } else if (current == player) {
      nextTurn();
    }
  }

  Map<String, dynamic> base() => {
        'turn': _over ? null : current,
        'over': _over,
        'win': _winners,
        if (gone.isNotEmpty) 'gone': gone.toList(),
      };
}
