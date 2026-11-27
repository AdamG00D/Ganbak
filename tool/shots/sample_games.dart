import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ganbak/features/chat/core/chat_session.dart';
import 'package:ganbak/features/games/core/game_center.dart';
import 'package:ganbak/features/games/core/game_engine.dart';
import 'package:ganbak/features/games/core/game_kind.dart';
import 'package:ganbak/features/games/core/game_room.dart';
import 'package:ganbak/features/games/engines/engines.dart';

import 'sample.dart';

/// غرف ألعاب تجريبية للصور: أجهزة وهمية بتلعب مع بعض في الذاكرة.
class GameNet {
  final Map<String, GamePeer> peers = {};

  GamePeer add(String id, String name, {bool group = true}) => peers[id] = GamePeer(this, id, name, group);

  void deliver(String from, String? to, Map<String, dynamic> m) {
    final wire = jsonEncode(m);
    scheduleMicrotask(() {
      for (final p in peers.values) {
        if (p.id == from || (to != null && p.id != to)) continue;
        p.center.receive(from, jsonDecode(wire) as Map<String, dynamic>, private: to != null);
      }
    });
  }
}

class GamePeer implements GameTransport {
  GamePeer(this.net, this.id, this.name, bool group) {
    center = GameCenter(transport: this, session: ChatSession(myName: name), group: group, rng: Random(7));
  }

  final GameNet net;
  final String id;
  final String name;
  late final GameCenter center;

  @override
  String get myId => id;

  @override
  String get myName => name;

  @override
  bool get online => true;

  @override
  Future<void> sendAll(Map<String, dynamic> m) async => net.deliver(id, null, m);

  @override
  Future<void> sendTo(String to, Map<String, dynamic> m) async => net.deliver(id, to, m);
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

/// بيرجّع الغرفة من ناحيتي ([me]) بعد ما اللعبة توصل للحالة المطلوبة.
class GameSamples {
  GameSamples._();

  /// اللاعبين التانيين بالترتيب (كريم، سلمى، منى، عمر، نور) — صور الـ README بتحط ناسها الحقيقيين.
  static List<String> people = [Sample.karim, Sample.salma, Sample.mona, Sample.omar, Sample.nour];

  /// لعبة لاتنين: أنا وكريم. [hostMe] = أنا اللي فتحتها.
  static Future<(GameRoom mine, GameRoom theirs)> duel(String me, GameKind kind, {bool hostMe = true}) async {
    final net = GameNet();
    final a = net.add(me, 'زياد', group: false);
    final b = net.add(people[0], 'كريم', group: false);
    final host = hostMe ? a : b;
    final guest = hostMe ? b : a;
    final room = host.center.invite(kind)!;
    await _settle();
    guest.center.rooms[room.id]!.join();
    await _settle();
    return (a.center.rooms[room.id]!, b.center.rooms[room.id]!);
  }

  static Future<GameRoom> xo(String me) async {
    final (mine, theirs) = await duel(me, GameKind.xo);
    for (final (r, i) in [(mine, 4), (theirs, 0), (mine, 2), (theirs, 6)]) {
      r.act({'t': 'put', 'i': i});
      await _settle();
    }
    return mine;
  }

  static Future<GameRoom> xoWon(String me) async {
    final (mine, theirs) = await duel(me, GameKind.xo);
    for (final (r, i) in [(mine, 4), (theirs, 0), (mine, 2), (theirs, 1), (mine, 6)]) {
      r.act({'t': 'put', 'i': i});
      await _settle();
    }
    return mine;
  }

  static Future<GameRoom> connect4(String me) async {
    final (mine, theirs) = await duel(me, GameKind.connect4);
    for (final (r, c) in [(mine, 3), (theirs, 3), (mine, 2), (theirs, 4), (mine, 4), (theirs, 2), (mine, 3), (theirs, 5)]) {
      r.act({'t': 'drop', 'c': c});
      await _settle();
    }
    return mine;
  }

  static Future<GameRoom> dots(String me) async {
    final (mine, theirs) = await duel(me, GameKind.dots);
    final moves = [
      (mine, true, 0), (theirs, true, 4), (mine, false, 0), (theirs, false, 1), // b قفل (0,0) ويلعب تاني
      (theirs, true, 1), (mine, true, 5), (theirs, false, 6), (mine, true, 10), (theirs, false, 3),
    ];
    for (final (r, h, i) in moves) {
      r.act({'t': 'line', 'h': h, 'i': i});
      await _settle();
    }
    return mine;
  }

  static Future<GameRoom> memory(String me) async {
    MemoryEngine.showMiss = const Duration(hours: 1);
    final (mine, theirs) = await duel(me, GameKind.memory);
    final engine = mine.engine! as MemoryEngine;
    final cards = engine.cards;
    // أنا ألاقي زوج، وبعدين أقلب كارتين مش شبه بعض
    final a = 5, twin = cards.indexOf(cards[5], 6) == -1 ? cards.indexOf(cards[5]) : cards.indexOf(cards[5], 6);
    for (final i in [a, twin]) {
      mine.act({'t': 'flip', 'i': i});
      await _settle();
    }
    final x = List.generate(cards.length, (i) => i).firstWhere((i) => i != a && i != twin);
    final y = List.generate(cards.length, (i) => i).firstWhere((i) => i != a && i != twin && i != x && cards[i] != cards[x]);
    for (final i in [x, y]) {
      mine.act({'t': 'flip', 'i': i});
      await _settle();
    }
    MemoryEngine.showMiss = const Duration(milliseconds: 1500);
    return mine;
  }

  static Future<GameRoom> rps(String me) async {
    final (mine, theirs) = await duel(me, GameKind.rps);
    for (final (r, c) in [(mine, 'r'), (theirs, 's')]) {
      final salt = GameEngine.newSalt();
      r.local['pick'] = {'c': c, 's': salt, 'k': r.view['k'], 'r': r.round};
      r.act({'t': 'commit', 'h': GameEngine.commit(c, salt)});
      await _settle();
    }
    await _settle();
    await _settle();
    return mine;
  }

  static Future<GameRoom> battleship(String me, {bool placing = false}) async {
    final (mine, theirs) = await duel(me, GameKind.battleship);
    if (placing) return mine;
    final boards = <GameRoom, String>{};
    for (final r in [mine, theirs]) {
      final board = BattleshipEngine.randomBoard(Random(r.myId.hashCode));
      final salt = GameEngine.newSalt();
      boards[r] = board;
      r.local
        ..['board'] = board
        ..['salt'] = salt
        ..['boardRound'] = r.round;
      r.act({'t': 'ready', 'h': GameEngine.commit(board, salt)});
      await _settle();
    }
    final theirBoard = boards[theirs]!;
    final ship = theirBoard.indexOf('a');
    final water = theirBoard.indexOf('.');
    for (final i in [ship, ship + 1, water]) {
      mine.act({'t': 'shot', 'i': i});
      await _settle();
      await _settle();
    }
    final myBoard = boards[mine]!;
    for (final i in [myBoard.indexOf('.'), myBoard.indexOf('b')]) {
      theirs.act({'t': 'shot', 'i': i});
      await _settle();
      await _settle();
    }
    return mine;
  }

  /// لعبة جروب: أنا + سلمى + كريم + منى (+ عمر ونور للمافيا).
  static Future<(GameRoom mine, GameNet net, String roomId)> party(String me, GameKind kind, {int players = 4}) async {
    final net = GameNet();
    final ids = [me, ...people].take(players).toList();
    final names = ['زياد', 'كريم', 'سلمى', 'منى', 'عمر', 'نور'];
    for (var i = 0; i < ids.length; i++) {
      net.add(ids[i], names[i]);
    }
    final host = net.peers[me]!;
    final room = host.center.invite(kind)!;
    await _settle();
    for (final id in ids.skip(1)) {
      net.peers[id]!.center.rooms[room.id]!.join();
    }
    await _settle();
    return (room, net, room.id);
  }

  static Future<GameRoom> lobby(String me) async => (await party(me, GameKind.mafia, players: 3)).$1;

  static Future<GameRoom> spy(String me, {bool vote = false, bool deal = false}) async {
    final (room, net, id) = await party(me, GameKind.spy);
    room.start();
    if (deal) {
      // لسه بيتوزع: نوقف في نص الخلط
      for (var k = 0; k < 200 && room.view['phase'] != 'mix'; k++) {
        await _settle();
      }
      return room;
    }
    // التوزيع العادل بيمشي لوحده بين الموبايلات (الوهمية)
    for (var k = 0; k < 400 && room.view['phase'] != 'clue'; k++) {
      await _settle();
    }
    for (var k = 0; k < 50 && room.local['role@${room.round}'] == null; k++) {
      await _settle();
    }
    if (vote) {
      for (var i = 0; i < 8; i++) {
        final who = room.view['turn'] as String;
        net.peers[who]!.center.rooms[id]!.act({'t': 'done'});
        await _settle();
      }
    } else {
      room.say('بتتاكل في الشارع');
      net.peers[people[0]]!.center.rooms[id]!.say('ريحتها حلوة');
      await _settle();
      room.act({'t': 'done'});
      await _settle();
    }
    return room;
  }

  static Future<GameRoom> quiz(String me, {bool answer = false}) async {
    final (room, net, id) = await party(me, GameKind.quiz);
    room.start();
    await _settle();
    if (answer) {
      final engine = room.engine! as QuizEngine;
      for (final (pid, ok, ms) in [(me, true, 3000), (people[0], false, 2000), (people[1], true, 6000), (people[2], true, 9000)]) {
        final r = net.peers[pid]!.center.rooms[id]!;
        final i = ok ? engine.correct[0] : (engine.correct[0] + 1) % 4;
        r.local['ans0@0'] = i;
        r.act({'t': 'ans', 'q': 0, 'i': i, 'ms': ms});
        await _settle();
      }
    }
    return room;
  }

  /// المافيا من ناحيتي: [day] = بعد أول ليلة (النقاش).
  static Future<GameRoom> mafia(String me, {bool day = false}) async {
    final (room, net, id) = await party(me, GameKind.mafia, players: 6);
    room.start();
    await _settle();
    if (!day) return room;
    final engine = room.engine! as MafiaEngine;
    final roles = engine.roles;
    final victim = roles.keys.firstWhere((p) => roles[p] == 'citizen' && p != me);
    for (final e in roles.entries) {
      final r = net.peers[e.key]!.center.rooms[id]!;
      switch (e.value) {
        case 'mafia':
          r.act({'t': 'kill', 'for': victim});
        case 'doctor':
          r.act({'t': 'save', 'for': e.key});
        case 'detective':
          r.act({'t': 'check', 'for': roles.keys.firstWhere((p) => p != e.key)});
      }
      await _settle();
    }
    room.act({'t': 'skip'});
    await _settle();
    net.peers[people[1]]!.center.rooms[id]!.say('أنا شاكة في كريم');
    await _settle();
    return room;
  }
}
