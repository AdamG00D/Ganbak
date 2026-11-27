import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../l10n/l10n.dart';
import '../../../mesh/mesh_router.dart';
import '../../chat/core/chat_session.dart';
import '../engines/engines.dart';
import 'game_kind.dart';
import 'game_room.dart';

/// وسيلة إرسال رسايل الألعاب (الشات الخاص أو الجروب).
abstract class GameTransport {
  String get myId;
  String get myName;

  /// فيه حد نقدر نبعتله دلوقتي.
  bool get online;

  /// للكل: في الخاص للطرف التاني، وفي الجروب لكل الأعضاء (مشفرة بمفتاح الجروب).
  Future<void> sendAll(Map<String, dynamic> m);

  /// لواحد بس: في الجروب بتتقفل بمفتاح مشترك بيننا (محدش غيره يقراها).
  Future<void> sendTo(String id, Map<String, dynamic> m);
}

/// ألعاب محادثة واحدة: الغرف، وكروتها في الشات، ونبض كل ثانية.
class GameCenter extends ChangeNotifier implements RoomLink {
  GameCenter({required this.transport, required this.session, required this.group, this.onInvite, Random? rng})
      : _rng = rng ?? Random.secure();

  final GameTransport transport;

  /// المحادثة اللي الكروت بتنزل فيها.
  final ChatSession session;
  final bool group;

  /// عزومة وصلت من حد (للإشعار).
  final void Function(ChatMessage card)? onInvite;
  final Random _rng;

  final Map<String, GameRoom> rooms = {};
  Timer? _timer;
  bool _disposed = false;

  static const maxRooms = 24;

  @override
  String get myId => transport.myId;

  @override
  String get myName => transport.myName;

  /// الغرفة اللي أنا فيها دلوقتي (لو فيه).
  GameRoom? get current {
    GameRoom? found;
    for (final r in rooms.values) {
      if (r.phase != RoomPhase.closed && r.joined) found = r;
    }
    return found;
  }

  /// أعزم الناس على لعبة. null = مينفعش دلوقتي (مفيش حد).
  GameRoom? invite(GameKind kind) {
    if (!transport.online || (group ? !kind.group : !kind.direct)) return null;
    // غرفة واحدة شغالة ليّا في نفس المحادثة
    current?.quit();
    final id = List.generate(6, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final room = _newRoom(id, kind, myId, transport.myName);
    _addCard(room, theirs: false);
    room.openLobby(transport.myName);
    return room;
  }

  GameRoom _newRoom(String id, GameKind kind, String host, String? hostName) {
    final room = GameRoom(
      id: id,
      kind: kind,
      host: host,
      hostName: hostName,
      link: this,
      engineFactory: createEngine,
      autoStart: !group,
      rng: _rng,
    );
    rooms[id] = room;
    // الغرف القديمة المقفولة بتتشال
    if (rooms.length > maxRooms) {
      final old = rooms.values.firstWhere((r) => r.phase == RoomPhase.closed, orElse: () => rooms.values.first);
      rooms.remove(old.id);
      old.dispose();
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _pulse());
    notifyListeners();
    return room;
  }

  static bool _validId(Object? g) => g is String && RegExp(r'^[0-9a-f]{8,32}$').hasMatch(g);

  /// رسالة لعبة وصلت من [from] (متأكدين منه: القناة المشفرة / مصدر الجروب / المفتاح المشترك).
  void receive(String from, Map<String, dynamic> m, {required bool private}) {
    if (_disposed || !MeshRouter.isId(from) || from == myId) return;
    final g = m['g'];
    final y = m['y'];
    if (!_validId(g) || y is! String) return;
    var room = rooms[g as String];
    if (room == null) {
      // عزومة جديدة — أو غرفة شغالة فاتتنا عزومتها (دخلنا الجروب متأخر)
      if (y != 'inv' && y != 'lobby' && y != 'view') return;
      final kind = GameKind.byId(m['kind']);
      if (kind == null || (group ? !kind.group : !kind.direct)) return;
      final hn = m['hn'];
      final nm = m['nm'];
      final hostName = hn is String ? hn : (nm is Map && nm[from] is String ? nm[from] as String : null);
      room = _newRoom(g, kind, from, hostName);
      final card = _addCard(room, theirs: true);
      if (y == 'inv') onInvite?.call(card);
      if (y == 'inv') return;
    }
    room.receive(from, m, private: private);
  }

  /// حد خرج من الشبكة.
  void nodeDown(String id) {
    for (final r in rooms.values) {
      if (r.isHost && r.phase == RoomPhase.lobby && r.players.contains(id)) {
        r.receive(id, {'g': r.id, 'y': 'unjoin'}, private: true);
      }
    }
  }

  void _pulse() {
    if (_disposed) return;
    final now = DateTime.now();
    for (final r in rooms.values.toList()) {
      r.pulse(now);
    }
  }

  // ---------------- RoomLink ----------------

  @override
  void sendAll(Map<String, dynamic> m) {
    final room = rooms[m['g']];
    // نوع اللعبة مع اللوبي والحالة عشان اللي فاتته العزومة يعرف يدخل
    if (room != null && (m['y'] == 'lobby' || m['y'] == 'view')) m['kind'] = room.kind.id;
    transport.sendAll(m).catchError((Object _) {});
  }

  @override
  void sendTo(String id, Map<String, dynamic> m) {
    final room = rooms[m['g']];
    if (room != null && (m['y'] == 'lobby' || m['y'] == 'view')) m['kind'] = room.kind.id;
    transport.sendTo(id, m).catchError((Object _) {});
  }

  @override
  void changed(GameRoom room) {
    // الحركات اللي بتحصل لوحدها (كشف الاختيار، الرد على ضربة) — بعد ما الحالة تخلص تتحدّث
    scheduleMicrotask(() {
      if (!_disposed) autoMoves(room);
    });
    final card = _cardOf(room.id);
    if (card != null) {
      final g = card.game!;
      final st = switch (room.phase) {
        RoomPhase.lobby => 'lobby',
        RoomPhase.playing => 'play',
        RoomPhase.closed => 'done',
      };
      final changed = g['st'] != st || g['p'] != room.players.length || g['w'].toString() != room.wins.toString();
      g
        ..['st'] = st
        ..['p'] = room.players.length
        ..['w'] = Map<String, int>.of(room.wins)
        ..['nm'] = {for (final p in {...room.players, ...room.wins.keys}) p: room.nameOf(p)};
      if (changed) session.notifyListeners();
    }
    notifyListeners();
  }

  // ---------------- الكروت في الشات ----------------

  ChatMessage? _cardOf(String roomId) {
    for (final m in session.messages.reversed) {
      if (m.game?['g'] == roomId) return m;
    }
    return null;
  }

  ChatMessage _addCard(GameRoom room, {required bool theirs}) {
    final name = gameNameOf(room.kind);
    final card = ChatMessage(
      id: 'game-${room.id}',
      text: theirs ? tr.gameInviteFrom(room.nameOf(room.host), name) : tr.gameInviteMine(name),
      kind: MessageKind.system,
      game: {'g': room.id, 'k': room.kind.id, 'h': room.host, 'st': 'lobby', 'p': 1, 'w': <String, int>{}},
    );
    session.messages.add(card);
    session.notifyListeners();
    return card;
  }

  /// قفل كل الغرف (الشبكة اتقفلت أو المحادثة اتمسحت).
  void closeAll() {
    for (final r in rooms.values) {
      if (r.phase == RoomPhase.closed) continue;
      if (r.isHost) {
        r.close(RoomEnd.ended);
      } else {
        r.quit();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final r in rooms.values) {
      r.dispose();
    }
    rooms.clear();
    super.dispose();
  }
}

/// اسم اللعبة باللغة الحالية (للكروت والإشعارات).
String gameNameOf(GameKind k) => switch (k) {
      GameKind.xo => tr.gameXo,
      GameKind.connect4 => tr.gameConnect4,
      GameKind.battleship => tr.gameBattleship,
      GameKind.rps => tr.gameRps,
      GameKind.dots => tr.gameDots,
      GameKind.memory => tr.gameMemory,
      GameKind.spy => tr.gameSpy,
      GameKind.quiz => tr.gameQuiz,
      GameKind.mafia => tr.gameMafia,
    };
