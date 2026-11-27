import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/chat/core/chat_session.dart';
import 'package:wasl/features/games/core/game_center.dart';
import 'package:wasl/features/games/core/game_engine.dart';
import 'package:wasl/features/games/core/game_kind.dart';
import 'package:wasl/features/games/core/game_room.dart';
import 'package:wasl/features/games/engines/engines.dart';

import 'support.dart';

/// شبكة ألعاب وهمية: كل جهاز ليه GameCenter، والرسايل بتتسلّم في دورة تانية زي الحقيقة.
/// الرسايل بتعدّي على JSON (زي الشبكة) عشان نتأكد إن كل حاجة بتتبعت صح.
class _Net {
  final Map<String, _Peer> peers = {};

  /// رسايل "خاصة" شافها مين (عشان نتأكد إن السر مبيروحش لحد غلط).
  final List<(String from, String to, Map<String, dynamic> m)> privateLog = [];

  /// رسايل عامة اتبعتت.
  final List<(String from, Map<String, dynamic> m)> publicLog = [];

  _Peer add(String id, String name, {bool group = true}) {
    final p = _Peer(this, id, name, group);
    peers[id] = p;
    return p;
  }

  void deliver(String from, String? to, Map<String, dynamic> m) {
    final wire = jsonDecode(jsonEncode(m)) as Map<String, dynamic>;
    if (to == null) {
      publicLog.add((from, wire));
    } else {
      privateLog.add((from, to, wire));
    }
    scheduleMicrotask(() {
      for (final p in peers.values) {
        if (p.id == from || p.down) continue;
        if (to != null && p.id != to) continue;
        p.center.receive(from, jsonDecode(jsonEncode(wire)) as Map<String, dynamic>, private: to != null);
      }
    });
  }
}

class _Peer implements GameTransport {
  _Peer(this.net, this.id, this.name, bool group) {
    session = ChatSession(myName: name);
    center = GameCenter(transport: this, session: session, group: group, rng: Random(id.hashCode));
  }

  final _Net net;
  final String id;
  final String name;
  late final ChatSession session;
  late final GameCenter center;
  bool down = false;

  @override
  String get myId => id;

  @override
  String get myName => name;

  @override
  bool get online => true;

  @override
  Future<void> sendAll(Map<String, dynamic> m) async {
    if (!down) net.deliver(id, null, m);
  }

  @override
  Future<void> sendTo(String to, Map<String, dynamic> m) async {
    if (!down) net.deliver(id, to, m);
  }

  GameRoom room(String gid) => center.rooms[gid]!;
}

const a = 'aaaaaaaaaaaaaaa1', b = 'aaaaaaaaaaaaaaa2', c = 'aaaaaaaaaaaaaaa3', d = 'aaaaaaaaaaaaaaa4', e = 'aaaaaaaaaaaaaaa5';
const f = 'aaaaaaaaaaaaaaa6';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  setUp(() {
    GameCenter.newRoomEvery = const Duration(seconds: 8);
    GameRoom.heartbeat = const Duration(seconds: 5);
    GameRoom.hostSilence = const Duration(seconds: 25);
  });

  group('القواعد', () {
    test('إكس أو: 3 في صف تكسب، والحركة في غير دورك مرفوضة', () {
      final g = XoEngine([a, b], Random(1));
      expect(g.act(b, {'t': 'put', 'i': 0}), isFalse);
      for (final (p, i) in [(a, 0), (b, 3), (a, 1), (b, 4)]) {
        expect(g.act(p, {'t': 'put', 'i': i}), isTrue);
      }
      expect(g.act(a, {'t': 'put', 'i': 3}), isFalse, reason: 'خانة مليانة');
      expect(g.act(a, {'t': 'put', 'i': 2}), isTrue);
      expect(g.over, isTrue);
      expect(g.winners, [a]);
      expect(g.view()['line'], [0, 1, 2]);
    });

    test('إكس أو: تعادل', () {
      final g = XoEngine([a, b], Random(1));
      for (final (p, i) in [(a, 0), (b, 1), (a, 2), (b, 4), (a, 3), (b, 5), (a, 7), (b, 6), (a, 8)]) {
        expect(g.act(p, {'t': 'put', 'i': i}), isTrue);
      }
      expect(g.over, isTrue);
      expect(g.winners, isEmpty);
    });

    test('أربعة في صف: القطعة بتنزل لتحت، والمايل بيكسب', () {
      final g = Connect4Engine([a, b], Random(1));
      // a يبني سلم مايل: أعمدة 0..3
      for (final (p, col) in [(a, 0), (b, 1), (a, 1), (b, 2), (a, 2), (b, 3), (a, 2), (b, 3), (a, 3), (b, 6), (a, 3)]) {
        expect(g.act(p, {'t': 'drop', 'c': col}), isTrue, reason: '$p → $col');
      }
      expect(g.over, isTrue);
      expect(g.winners, [a]);
      expect((g.view()['line'] as List).length, greaterThanOrEqualTo(4));
      // العمود المليان مرفوض
      final h = Connect4Engine([a, b], Random(1));
      for (var i = 0; i < 6; i++) {
        h.act(i.isEven ? a : b, {'t': 'drop', 'c': 0});
      }
      expect(h.act(a, {'t': 'drop', 'c': 0}), isFalse);
    });

    test('مربعات ونقط: اللي يقفل مربع ياخده ويلعب تاني', () {
      final g = DotsEngine([a, b], Random(1));
      final n = g.size;
      // مربع (0,0): فوق h0، تحت h[n]، شمال v0، يمين v1
      expect(g.act(a, {'t': 'line', 'h': true, 'i': 0}), isTrue);
      expect(g.act(b, {'t': 'line', 'h': true, 'i': n}), isTrue);
      expect(g.act(a, {'t': 'line', 'h': false, 'i': 0}), isTrue);
      expect(g.current, b);
      expect(g.act(b, {'t': 'line', 'h': false, 'i': 1}), isTrue);
      expect(g.boxes[0], 1, reason: 'b (رقم 1) قفل المربع');
      expect(g.current, b, reason: 'قفل مربع = يلعب تاني');
      expect(g.act(b, {'t': 'line', 'h': false, 'i': 1}), isFalse, reason: 'الخط مرسوم');
    });

    test('الذاكرة: الشبه بيتاخد والمش شبه بيتقلب بعد لحظة', () {
      MemoryEngine.showMiss = Duration.zero;
      final g = MemoryEngine([a, b], Random(3));
      expect(g.cards.length, 16);
      final first = g.cards[0];
      final twin = g.cards.indexOf(first, 1);
      final other = List.generate(16, (i) => i).firstWhere((i) => g.cards[i] != first);
      // a يقلب كارتين مش شبه بعض
      expect(g.act(a, {'t': 'flip', 'i': 0}), isTrue);
      expect(g.act(a, {'t': 'flip', 'i': other}), isTrue);
      expect(g.view()['miss'], isTrue);
      expect(g.act(a, {'t': 'flip', 'i': twin}), isFalse, reason: 'لسه ظاهرين');
      expect(g.tick(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      expect(g.current, b);
      // b يقلب الشبه
      expect(g.act(b, {'t': 'flip', 'i': 0}), isTrue);
      expect(g.act(b, {'t': 'flip', 'i': twin}), isTrue);
      expect(g.scores[1], 1);
      expect(g.current, b, reason: 'شبه = يلعب تاني');
      // الكروت المقفولة مبتظهرش في الحالة
      final faces = g.view()['c'] as List;
      expect(faces.where((x) => x != -1).length, 2);
      MemoryEngine.showMiss = const Duration(milliseconds: 1500);
    });

    test('حرب السفن: لوح عشوائي صحيح والرد صح', () {
      final rng = Random(5);
      for (var i = 0; i < 50; i++) {
        final board = BattleshipEngine.randomBoard(rng);
        expect(BattleshipEngine.validBoard(board), isTrue);
        expect(board.split('').where((x) => x != '.').length, BattleshipEngine.shipCells);
      }
      final board = ['aaaa....', 'bbb.....', 'ccc.....', 'dd......', '.' * 32].join();
      expect(BattleshipEngine.validBoard(board), isTrue);
      expect(BattleshipEngine.answer(board, {}, 4), 0);
      expect(BattleshipEngine.answer(board, {}, 0), 1);
      expect(BattleshipEngine.answer(board, {0, 1, 2}, 3), 2, reason: 'آخر خانة = غرّقت');
      expect(BattleshipEngine.validBoard('a' * 64), isFalse);
    });

    test('حجر ورقة مقص: بصمة غلط = غش وخسارة', () {
      final g = RpsEngine([a, b], Random(1));
      final sa = GameEngine.newSalt(), sb = GameEngine.newSalt();
      expect(g.act(a, {'t': 'reveal', 'c': 'r', 's': sa}), isFalse, reason: 'لسه محدش بعت بصمته');
      expect(g.act(a, {'t': 'commit', 'h': GameEngine.commit('r', sa)}), isTrue);
      expect(g.act(b, {'t': 'commit', 'h': GameEngine.commit('s', sb)}), isTrue);
      expect(g.view()['phase'], 'reveal');
      expect(g.act(a, {'t': 'reveal', 'c': 'r', 's': sa}), isTrue);
      // b غيّر رأيه بعد ما شاف إن a حجر
      expect(g.act(b, {'t': 'reveal', 'c': 'p', 's': sb}), isTrue);
      expect(g.over, isTrue);
      expect(g.cheat, b);
      expect(g.winners, [a]);
    });

    test('حجر ورقة مقص: اللي مبيكشفش بعد ما التاني كشف بيخسر', () {
      RpsEngine.revealTime = Duration.zero;
      final g = RpsEngine([a, b], Random(1));
      final sa = GameEngine.newSalt();
      g.act(a, {'t': 'commit', 'h': GameEngine.commit('r', sa)});
      g.act(b, {'t': 'commit', 'h': GameEngine.commit('s', GameEngine.newSalt())});
      expect(g.tick(DateTime.now()), isFalse, reason: 'لسه محدش كشف');
      g.act(a, {'t': 'reveal', 'c': 'r', 's': sa});
      expect(g.tick(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      expect(g.cheat, b);
      expect(g.winners, [a]);
      RpsEngine.revealTime = const Duration(seconds: 20);
    });

    test('حرب السفن: اللي مبيكشفش لوحه في الآخر بيتحسب غشاش', () {
      BattleshipEngine.revealTime = Duration.zero;
      final g = BattleshipEngine([a, b], Random(1));
      final boardB = BattleshipEngine.randomBoard(Random(2));
      final sa = GameEngine.newSalt(), sb = GameEngine.newSalt();
      final boardA = BattleshipEngine.randomBoard(Random(3));
      g.act(a, {'t': 'ready', 'h': GameEngine.commit(boardA, sa)});
      g.act(b, {'t': 'ready', 'h': GameEngine.commit(boardB, sb)});
      for (var i = 0; i < 64; i++) {
        if (boardB[i] == '.') continue;
        g.act(a, {'t': 'shot', 'i': i});
        g.act(b, {'t': 'ans', 'i': i, 'r': 1});
      }
      expect(g.over, isTrue);
      expect(g.winners, [a]);
      // a كشف لوحه، b لأ
      g.act(a, {'t': 'reveal', 'b': boardA, 's': sa});
      expect(g.tick(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      expect(g.cheat, b);
      expect(g.winners, [a]);
      BattleshipEngine.revealTime = const Duration(seconds: 20);
    });

    test('مين الجاسوس: جاسوس واحد، والكلمة مبتظهرش في الحالة العامة', () {
      final g = SpyEngine([a, b, c, d], Random(7))..host = a;
      final spies = [a, b, c, d].where((p) => g.viewFor(p)!['spy'] == true).toList();
      expect(spies, hasLength(1));
      for (final p in [a, b, c, d]) {
        if (p != g.spy) expect(g.viewFor(p)!['word'], g.word);
      }
      expect(g.viewFor(g.spy)!.containsKey('word'), isFalse);
      expect(jsonEncode(g.view()), isNot(contains(g.word)));
      expect(jsonEncode(g.view()), isNot(contains(g.spy == a ? 'xx' : '"spy":"${g.spy}"')));
      // 4 لاعبين = لفّتين تلميحات
      for (var i = 0; i < 8; i++) {
        expect(g.act(g.current, {'t': 'done'}), isTrue);
      }
      expect(g.phase, 'vote');
      for (final p in [a, b, c, d]) {
        final target = p == g.spy ? [a, b, c, d].firstWhere((x) => x != p) : g.spy;
        expect(g.act(p, {'t': 'vote', 'for': target}), isTrue);
      }
      expect(g.phase, 'guess');
      expect(g.view().containsKey('word'), isFalse, reason: 'الاختيارات بس، مش الإجابة');
      expect(g.view()['options'], contains(g.word));
      final right = g.options.indexOf(g.word);
      expect(g.act(g.spy, {'t': 'guess', 'i': right}), isTrue);
      expect(g.winners, [g.spy]);
      expect(g.view()['word'], g.word);
    });

    test('المسابقة: النقط على الصح والسرعة، والإجابة مبتظهرش قبل ما السؤال يخلص', () {
      final g = QuizEngine([a, b, c], Random(2), count: 5);
      expect(g.questions, hasLength(5));
      expect(g.view().containsKey('right'), isFalse);
      final right = g.correct[0];
      expect(g.act(a, {'t': 'ans', 'q': 0, 'i': right, 'ms': 1000}), isTrue);
      expect(g.act(a, {'t': 'ans', 'q': 0, 'i': right, 'ms': 0}), isFalse, reason: 'جاوب خلاص');
      expect(g.act(b, {'t': 'ans', 'q': 0, 'i': (right + 1) % 4, 'ms': 500}), isTrue);
      expect(g.act(c, {'t': 'ans', 'q': 0, 'i': right, 'ms': 9000}), isTrue);
      expect(g.phase, 'a');
      expect(g.score[a]! > g.score[c]!, isTrue, reason: 'a أسرع');
      expect(g.score[b], 0);
      expect(g.view()['right'], right);
    });

    test('المافيا: الأدوار، الليل، والشات السري للمافيا بس', () {
      final players = [a, b, c, d, e, f];
      final g = MafiaEngine(players, Random(4))..host = a;
      final roles = g.roles.values.toList();
      expect(roles.where((r) => r == 'mafia'), hasLength(1));
      expect(roles.where((r) => r == 'doctor'), hasLength(1));
      expect(roles.where((r) => r == 'detective'), hasLength(1));
      expect(jsonEncode(g.view()), isNot(contains('mafia')), reason: 'الأدوار سرية');
      final mafia = g.roles.entries.firstWhere((x) => x.value == 'mafia').key;
      final doctor = g.roles.entries.firstWhere((x) => x.value == 'doctor').key;
      final detective = g.roles.entries.firstWhere((x) => x.value == 'detective').key;
      final victim = players.firstWhere((p) => g.roles[p] == 'citizen');
      expect(g.secretChatOf(mafia), [mafia]);
      expect(g.secretChatOf(victim), isEmpty);
      expect(g.act(mafia, {'t': 'kill', 'for': mafia}), isFalse, reason: 'مافيا مبتقتلش نفسها');
      expect(g.act(mafia, {'t': 'kill', 'for': victim}), isTrue);
      expect(g.act(doctor, {'t': 'save', 'for': doctor}), isTrue);
      expect(g.act(detective, {'t': 'check', 'for': mafia}), isTrue);
      expect(g.phase, 'morning');
      expect(g.died, victim);
      expect(g.alive.contains(victim), isFalse);
      expect((g.viewFor(detective)!['checks'] as List).single, [mafia, true]);
      expect((g.view()['mute'] as List), contains(victim));
      expect((g.view()['roles'] as Map)[victim], 'citizen', reason: 'اللي مات دوره بيتكشف');
      // الصبح ← النقاش ← التصويت
      g.act(a, {'t': 'skip'});
      expect(g.phase, 'talk');
      g.act(a, {'t': 'skip'});
      expect(g.phase, 'vote');
      for (final p in g.alive.toList()) {
        g.act(p, {'t': 'vote', 'for': p == mafia ? doctor : mafia});
      }
      expect(g.over, isTrue);
      expect(g.winSide, 'town');
      expect(g.winners, isNot(contains(mafia)));
      expect(g.winners, contains(victim), reason: 'الميتين من المواطنين كسبوا برضه');
    });
  });

  group('الغرف على الشبكة', () {
    test('الخاص: عزومة ← موافقة ← اللعبة تبدأ لوحدها ← كسب ← ماتش تاني', () async {
      final net = _Net();
      final pa = net.add(a, 'آدم', group: false), pb = net.add(b, 'كريم', group: false);
      final room = pa.center.invite(GameKind.xo)!;
      await settle();
      // الكارت نزل عند الاتنين
      expect(pa.session.messages.single.game!['g'], room.id);
      final card = pb.session.messages.single;
      expect(card.game!['k'], 'xo');
      expect(card.text, contains('آدم'));
      final rb = pb.room(room.id);
      rb.join('كريم');
      await settle();
      expect(room.phase, RoomPhase.playing);
      expect(rb.phase, RoomPhase.playing);
      expect(rb.names[a], 'آدم');
      // آدم بيبدأ (X)
      for (final (p, i) in [(a, 0), (b, 3), (a, 1), (b, 4), (a, 2)]) {
        (p == a ? room : rb).act({'t': 'put', 'i': i});
        await settle();
      }
      expect(rb.over, isTrue);
      expect(rb.winners, [a]);
      expect(rb.wins[a], 1);
      expect(pb.session.messages.single.game!['w'], {a: 1});
      // ماتش تاني: الاتنين لازم يوافقوا (حتى لو صاحب الغرفة طلب الأول)، واللي بيبدأ يتبدّل
      room.act({'t': 'again'});
      await settle();
      expect(room.round, 0);
      expect(rb.view['again'], [a]);
      rb.act({'t': 'again'});
      await settle();
      expect(rb.round, 1);
      expect(rb.over, isFalse);
      expect(rb.view['turn'], b);
    });

    test('حجر ورقة مقص على الشبكة: الكشف بيحصل لوحده وصاحب الغرفة ميعرفش الاختيار بدري', () async {
      final net = _Net();
      final pa = net.add(a, 'آدم', group: false), pb = net.add(b, 'كريم', group: false);
      final room = pa.center.invite(GameKind.rps)!;
      await settle();
      pb.room(room.id).join('كريم');
      await settle();

      Future<void> pick(GameRoom r, String choice) async {
        final salt = GameEngine.newSalt();
        r.local['pick'] = {'c': choice, 's': salt, 'k': r.view['k'], 'r': r.round};
        r.act({'t': 'commit', 'h': GameEngine.commit(choice, salt)});
        await settle();
      }

      final rb = pb.room(room.id);
      await pick(rb, 'p');
      // اختيار كريم مبيوصلش لصاحب الغرفة غير كبصمة
      expect(net.privateLog.where((x) => x.$1 == b && jsonEncode(x.$3).contains('"c":"p"')), isEmpty);
      await pick(room, 'r');
      await settle();
      expect(rb.view['s'], {b: 1});
      await pick(room, 's');
      await pick(rb, 'r');
      await settle();
      expect(rb.over, isTrue);
      expect(rb.winners, [b]);
    });

    test('حرب السفن على الشبكة: الرد بيحصل لوحده، والكدب بيتكشف في الآخر', () async {
      final net = _Net();
      final pa = net.add(a, 'آدم', group: false), pb = net.add(b, 'كريم', group: false);
      final room = pa.center.invite(GameKind.battleship)!;
      await settle();
      final rb = pb.room(room.id)..join('كريم');
      await settle();
      final boards = <String, String>{};
      for (final (id, r) in [(a, room), (b, rb)]) {
        final board = BattleshipEngine.randomBoard(Random(id.hashCode));
        final salt = GameEngine.newSalt();
        boards[id] = board;
        r.local
          ..['board'] = board
          ..['salt'] = salt
          ..['boardRound'] = r.round;
        r.act({'t': 'ready', 'h': GameEngine.commit(board, salt)});
        await settle();
      }
      expect(room.view['phase'], 'fire');
      expect(room.view['turn'], a);
      // آدم بيضرب كل سفن كريم (عارفينها في الاختبار) — الرد بييجي لوحده من موبايل كريم
      final targets = [for (var i = 0; i < 64; i++) if (boards[b]![i] != '.') i];
      for (final t in targets) {
        room.act({'t': 'shot', 'i': t});
        await settle();
        await settle();
      }
      expect(room.over, isTrue);
      expect(room.winners, [a]);
      await settle();
      await settle();
      // الاتنين كشفوا ألواحهم ومحدش غش
      expect((room.view['revealed'] as Map).keys.toSet(), {a, b});
      expect(room.view['cheat'], isNull);
      // اللوح الحقيقي مكانش بيتبعت قبل الآخر
      final early = net.privateLog.where((x) => x.$1 == b && x.$3['y'] == 'act' && (x.$3['a'] as Map)['t'] != 'reveal');
      expect(early.any((x) => jsonEncode(x.$3).contains(boards[b]!)), isFalse);
    });

    test('الجروب: لوبي ← بدء ← السر بيروح لصاحبه بس، والتصويت مقفول', () async {
      final net = _Net();
      final peers = [net.add(a, 'آدم'), net.add(b, 'كريم'), net.add(c, 'سلمى'), net.add(d, 'منى')];
      final room = peers[0].center.invite(GameKind.spy)!;
      await settle();
      for (final p in peers.skip(1)) {
        expect(p.session.messages.single.game!['k'], 'spy');
        p.room(room.id).join(p.name);
      }
      await settle();
      expect(room.players, hasLength(4));
      expect(room.canStart, isTrue);
      room.start();
      await settle();
      final engine = room.engine! as SpyEngine;
      // كل واحد وصله سره هو بس
      for (final p in peers) {
        final s = p.id == a ? room.secret : p.room(room.id).secret;
        expect(s['spy'], p.id == engine.spy);
      }
      final secrets = net.privateLog.where((x) => x.$3['y'] == 'pv');
      for (final (_, to, m) in secrets) {
        expect((m['v'] as Map)['spy'], to == engine.spy);
      }
      // الكلمة مبتعدّيش على الرسايل العامة
      expect(net.publicLog.any((x) => jsonEncode(x.$2).contains(engine.word)), isFalse);
      // التلميحات بالدور
      for (var i = 0; i < 8; i++) {
        final who = room.view['turn'] as String;
        peers.firstWhere((p) => p.id == who).center.rooms[room.id]!.act({'t': 'done'});
        await settle();
      }
      expect(room.view['phase'], 'vote');
      for (final p in peers) {
        p.center.rooms[room.id]!.act({'t': 'vote', 'for': p.id == engine.spy ? (p.id == a ? b : a) : engine.spy});
        await settle();
      }
      // الأصوات راحت لصاحب الغرفة بس
      expect(net.publicLog.any((x) => jsonEncode(x.$2).contains('"t":"vote"')), isFalse);
      await settle();
      expect(peers[1].room(room.id).view['phase'], 'guess');
    });

    test('المافيا على الشبكة: شات المافيا السري ميوصلش لغيرهم، والميت ميتكلمش', () async {
      final net = _Net();
      final ids = [a, b, c, d, e, f];
      final peers = [for (final id in ids) net.add(id, 'p${id.substring(15)}')];
      final room = peers[0].center.invite(GameKind.mafia)!;
      await settle();
      for (final p in peers.skip(1)) {
        p.room(room.id).join(p.name);
      }
      await settle();
      room.start();
      await settle();
      final engine = room.engine! as MafiaEngine;
      final mafia = engine.roles.entries.firstWhere((x) => x.value == 'mafia').key;
      final mafiaRoom = peers.firstWhere((p) => p.id == mafia).center.rooms[room.id]!;
      expect(mafiaRoom.secret['role'], 'mafia');
      // كلام المافيا بالليل
      mafiaRoom.say('هنقتل مين؟', secret: true);
      await settle();
      for (final p in peers) {
        final r = p.center.rooms[room.id]!;
        final heard = r.chat.any((x) => x.text == 'هنقتل مين؟');
        expect(heard, engine.roles[p.id] == 'mafia', reason: '${p.id} (${engine.roles[p.id]})');
      }
      // الشات العام مقفول بالليل
      peers.firstWhere((p) => p.id != mafia).center.rooms[room.id]!.say('صباح الخير');
      await settle();
      expect(peers.every((p) => p.center.rooms[room.id]!.chat.every((x) => x.text != 'صباح الخير')), isTrue);
    });

    test('صاحب الغرفة اختفى: الغرفة بتتقفل عند الباقيين', () async {
      GameRoom.hostSilence = const Duration(milliseconds: 1200);
      final net = _Net();
      final pa = net.add(a, 'آدم', group: false), pb = net.add(b, 'كريم', group: false);
      final room = pa.center.invite(GameKind.connect4)!;
      await settle();
      final rb = pb.room(room.id)..join('كريم');
      await settle();
      expect(rb.phase, RoomPhase.playing);
      pa.down = true;
      await waitFor(() => rb.phase == RoomPhase.closed, timeout: const Duration(seconds: 5));
      expect(rb.end, RoomEnd.hostLeft);
      expect(pb.session.messages.single.game!['st'], 'done');
    });

    test('الأمان: في الجروب حركة مش مقفولة (ممكن تكون مزوّرة) بتترمي', () async {
      final net = _Net();
      final peers = [net.add(a, 'آدم'), net.add(b, 'كريم'), net.add(c, 'سلمى')];
      final room = peers[0].center.invite(GameKind.spy)!;
      await settle();
      for (final p in peers.skip(1)) {
        p.room(room.id).join();
      }
      await settle();
      room.start();
      await settle();
      final turn = room.view['turn'] as String;
      final clue = room.view['clue'];
      // حد بيبعت "خلصت" باسم اللي عليه الدور في رسالة جروب عامة (من غير المفتاح المشترك)
      net.deliver(turn == a ? b : turn, null, {'g': room.id, 'y': 'act', 'c': 99, 'a': {'t': 'done'}});
      await settle();
      expect(room.view['clue'], clue);
      expect(room.view['turn'], turn);
    });

    test('الأمان: عزومات كتير ورا بعض من نفس الشخص بتترمي', () async {
      final net = _Net();
      final pb = net.add(b, 'كريم', group: false);
      for (var i = 0; i < 10; i++) {
        pb.center.receive(a, {'g': '0123456789a$i', 'y': 'inv', 'kind': 'xo', 'hn': 'آدم'}, private: false);
      }
      expect(pb.center.rooms, hasLength(1));
      expect(pb.session.messages.where((m) => m.game != null), hasLength(1));
    });

    test('الأمان: حالة بايظة الشكل من صاحب الغرفة بتترمي', () async {
      final net = _Net();
      final pa = net.add(a, 'آدم', group: false), pb = net.add(b, 'كريم', group: false);
      final room = pa.center.invite(GameKind.xo)!;
      await settle();
      final rb = pb.room(room.id)..join();
      await settle();
      final good = rb.view;
      for (final bad in [
        {'o': [a, b], 'b': [0, 0, 0]}, // لوح ناقص
        {'o': [a, b], 'b': List.filled(9, 7)}, // لاعب مش موجود
        {'o': [a, b], 'b': List.filled(9, 'x')},
        {'o': 'nope', 'b': List.filled(9, -1)},
      ]) {
        rb.receive(a, {'g': room.id, 'y': 'view', 'n': rb.n + 1, 'v': bad}, private: false);
      }
      expect(rb.view, same(good));
    });

    test('رسايل غريبة بتترمي', () async {
      final net = _Net();
      final pb = net.add(b, 'كريم', group: false);
      pb.center.receive(a, {'g': 'zz', 'y': 'inv', 'kind': 'xo'}, private: false);
      pb.center.receive(a, {'g': '0123456789ab', 'y': 'inv', 'kind': 'nope'}, private: false);
      pb.center.receive(a, {'g': '0123456789ab', 'y': 'inv', 'kind': 'spy'}, private: false); // لعبة جروب في الخاص
      pb.center.receive('not-an-id', {'g': '0123456789ab', 'y': 'inv', 'kind': 'xo'}, private: false);
      expect(pb.center.rooms, isEmpty);
      pb.center.receive(a, {'g': '0123456789ab', 'y': 'inv', 'kind': 'xo', 'hn': 'آدم'}, private: false);
      expect(pb.center.rooms, hasLength(1));
      // حالة من حد مش صاحب الغرفة
      pb.center.receive(c, {'g': '0123456789ab', 'y': 'view', 'n': 9, 'v': {'over': true}}, private: false);
      expect(pb.room('0123456789ab').view, isEmpty);
    });
  });
}
