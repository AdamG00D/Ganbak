import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../mesh/mesh_router.dart';
import 'game_engine.dart';
import 'game_kind.dart';

enum RoomPhase {
  /// صاحب الغرفة عزم الناس ومستني يبدأ.
  lobby,

  /// اللعبة شغالة (أو خلصت ومستنيين ماتش تاني).
  playing,

  /// الغرفة اتقفلت (صاحبها قفلها أو خرج).
  closed,
}

/// ليه الغرفة اتقفلت.
enum RoomEnd { ended, hostLeft, canceled }

/// بيبعت رسايل الغرفة (الـ [GameCenter] بيوصّلها بالشات الخاص أو بالجروب).
abstract class RoomLink {
  String get myId;
  String get myName;

  /// للكل (اللي في المحادثة).
  void sendAll(Map<String, dynamic> m);

  /// لواحد بس، مقفولة (في الجروب) — في الخاص هي هي.
  void sendTo(String id, Map<String, dynamic> m);

  /// الغرفة اتغيرت (عشان الكارت في الشات يتحدّث).
  void changed(GameRoom room);
}

/// غرفة لعبة: نفس الكلاس عند صاحب الغرفة (بيشغّل القواعد) وعند اللاعبين (بيرسموا الحالة).
///
/// الرسايل (كلها فيها `g` = رقم الغرفة و`y` = النوع):
///   inv    صاحب الغرفة ← الكل: عزومة {kind, hn}
///   lobby  صاحب الغرفة ← الكل: مين دخل {p, nm}
///   view   صاحب الغرفة ← الكل: الحالة {n, p, nm, v, w, r, ac}
///   pv     صاحب الغرفة ← لاعب: حاجته السرية {n, v}
///   join / unjoin / quit / sync / act {c, a}   لاعب ← صاحب الغرفة
///   bye    صاحب الغرفة ← الكل: الغرفة اتقفلت {why}
///   rx     أي حد ← الكل: تفاعل سريع {e}
///   say    أي حد ← الكل: كلام في شات اللعبة {t}
///   psay   صاحب الغرفة ← لاعب: كلام في شات سري (المافيا بالليل) {f, t}
class GameRoom extends ChangeNotifier {
  GameRoom({
    required this.id,
    required this.kind,
    required this.host,
    required this.link,
    String? hostName,
    this.engineFactory,
    this.autoStart = false,
    Random? rng,
  }) : rng = rng ?? Random.secure() {
    if (hostName != null) names[host] = hostName;
  }

  final String id;
  final GameKind kind;
  final String host;
  final RoomLink link;
  final Random rng;

  /// بيعمل قواعد اللعبة (عند صاحب الغرفة بس).
  final GameEngine Function(GameKind kind, List<String> players, Random rng, Map<String, dynamic> options)?
      engineFactory;

  /// اختيارات صاحب الغرفة قبل ما يبدأ (فئة المسابقة وعدد الأسئلة...).
  Map<String, dynamic> options = {};

  /// الشات الخاص: أول ما التاني يوافق اللعبة تبدأ لوحدها.
  final bool autoStart;

  String get myId => link.myId;
  bool get isHost => host == myId;

  RoomPhase phase = RoomPhase.lobby;
  RoomEnd? end;
  List<String> players = [];
  final Map<String, String> names = {};

  /// آخر حالة وصلت (أو اتعملت عند صاحب الغرفة).
  Map<String, dynamic> view = const {};

  /// حاجتي السرية (دوري، الكلمة...).
  Map<String, dynamic> secret = const {};
  int n = 0;
  int _secretN = -1;

  /// رقم الماتش (بيزيد مع "ماتش تاني").
  int round = 0;

  /// عدد مرات الكسب لكل لاعب في الغرفة دي.
  Map<String, int> wins = {};

  /// حاجات محلية مبتتبعتش (لوح سفني، اختياري قبل ما أكشفه...).
  final Map<String, dynamic> local = {};

  /// كلام شات اللعبة (آخر 80).
  final List<GameSay> chat = [];

  /// تفاعلات سريعة ظاهرة دلوقتي.
  final List<GameReaction> reactions = [];

  /// آخر مرة سمعنا فيها من صاحب الغرفة.
  DateTime heard = DateTime.now();

  /// وقت الحالة الحالية (عشان العدّاد التنازلي يتحسب على ساعة الموبايل ده).
  DateTime viewAt = DateTime.now();

  bool get joined => players.contains(myId);
  bool get over => view['over'] == true;
  List<String> get winners => [for (final w in (view['win'] as List? ?? const [])) if (w is String) w];

  /// الوقت الفاضل (لو اللعبة فيها عدّاد).
  Duration? get timeLeft {
    final left = view['left'];
    if (left is! num) return null;
    final ms = left.toInt() - DateTime.now().difference(viewAt).inMilliseconds;
    return Duration(milliseconds: max(0, ms));
  }

  String nameOf(String id) => names[id] ?? '…';

  // ---------------- اللاعب ----------------

  int _c = 0;
  final Map<int, Map<String, dynamic>> _pending = {};
  DateTime _sentAt = DateTime.now();

  /// أدخل الغرفة (في الجروب) أو أوافق على العزومة (في الخاص).
  void join([String? name]) {
    if (phase != RoomPhase.lobby) return;
    final myName = name ?? link.myName;
    names[myId] = myName;
    if (isHost) {
      _hostJoin(myId, myName);
    } else {
      link.sendTo(host, {'g': id, 'y': 'join', 'nm': myName});
    }
  }

  /// أخرج من اللوبي (قبل ما تبدأ).
  void unjoin() {
    if (isHost || phase != RoomPhase.lobby) return;
    link.sendTo(host, {'g': id, 'y': 'unjoin'});
    players.remove(myId);
    notifyListeners();
  }

  /// أخرج من اللعبة خالص. صاحب الغرفة لو خرج الغرفة بتتقفل للكل.
  void quit() {
    if (phase == RoomPhase.closed) return;
    if (isHost) {
      close(RoomEnd.ended);
    } else {
      link.sendTo(host, {'g': id, 'y': 'quit'});
      _close(RoomEnd.ended);
    }
  }

  /// حركة. بتتبعت لصاحب الغرفة وبتتعاد لحد ما يأكد إنها وصلت.
  void act(Map<String, dynamic> a) {
    if (phase != RoomPhase.playing || !joined) return;
    final c = ++_c;
    if (isHost) {
      _hostAct(myId, c, a);
      return;
    }
    _pending[c] = a;
    _sentAt = DateTime.now();
    link.sendTo(host, {'g': id, 'y': 'act', 'c': c, 'a': a});
  }

  void react(String emoji) {
    if (!ChatReactions.valid(emoji)) return;
    _addReaction(myId, emoji);
    link.sendAll({'g': id, 'y': 'rx', 'e': emoji});
  }

  /// كلام في شات اللعبة. [secret]: للشات السري (بيروح لصاحب الغرفة يوزّعه).
  void say(String text, {bool secret = false}) {
    final t = text.trim();
    if (t.isEmpty || t.length > GameSay.maxLength || phase != RoomPhase.playing) return;
    if (secret) {
      act({'t': 'msay', 'x': t});
      return;
    }
    if (!_canSay(myId)) return;
    _addSay(myId, t, secret: false);
    link.sendAll({'g': id, 'y': 'say', 't': t});
  }

  // ---------------- الرسايل الواصلة ----------------

  /// رسالة من [from]. [private] = جت مقفولة ليّا أنا بس.
  void receive(String from, Map<String, dynamic> m, {required bool private}) {
    if (phase == RoomPhase.closed) return;
    final y = m['y'];
    if (from == host && !isHost) heard = DateTime.now();
    switch (y) {
      case 'lobby' when from == host && !isHost:
        _readPlayers(m);
        notifyListeners();
        link.changed(this);
      case 'view' when from == host && !isHost:
        final vn = GameEngine.intOf(m['n']);
        if (vn == null || vn < n) return;
        final v = m['v'];
        if (v is! Map<String, dynamic>) return;
        n = vn;
        _readPlayers(m);
        view = v;
        viewAt = DateTime.now();
        round = GameEngine.intOf(m['r']) ?? round;
        final w = m['w'];
        if (w is Map) {
          wins = {
            for (final e in w.entries)
              if (e.key is String && e.value is num) e.key as String: (e.value as num).toInt(),
          };
        }
        phase = RoomPhase.playing;
        // الحركات اللي صاحب الغرفة أكد إنها وصلته
        final ac = m['ac'];
        if (ac is Map) {
          final mine = GameEngine.intOf(ac[myId]);
          if (mine != null) _pending.removeWhere((c, _) => c <= mine);
        }
        if (_secretN > n) _secretN = -1;
        notifyListeners();
        link.changed(this);
      case 'pv' when from == host && !isHost && private:
        final vn = GameEngine.intOf(m['n']);
        final v = m['v'];
        if (vn == null || v is! Map<String, dynamic> || vn < _secretN) return;
        _secretN = vn;
        secret = v;
        notifyListeners();
      case 'bye' when from == host && !isHost:
        _close(m['why'] == 'left' ? RoomEnd.hostLeft : (m['why'] == 'cancel' ? RoomEnd.canceled : RoomEnd.ended));
      case 'rx':
        final e = m['e'];
        if (e is String && ChatReactions.valid(e) && (players.contains(from) || from == host)) _addReaction(from, e);
      case 'say':
        final t = m['t'];
        if (t is! String || t.isEmpty || t.length > GameSay.maxLength || !players.contains(from)) return;
        if (!_canSay(from)) return;
        _addSay(from, t, secret: false);
      case 'psay' when from == host && private:
        final t = m['t'], f = m['f'];
        if (t is! String || f is! String || t.isEmpty || t.length > GameSay.maxLength) return;
        _addSay(f, t, secret: true);
      // ---- عند صاحب الغرفة ----
      case 'join' when isHost:
        final nm = m['nm'];
        _hostJoin(from, nm is String ? _cleanName(nm) : '…');
      case 'unjoin' when isHost:
        if (phase == RoomPhase.lobby && players.remove(from)) _broadcastLobby();
      case 'quit' when isHost:
        _hostLeave(from);
      case 'sync' when isHost:
        _sendState(to: from);
      case 'act' when isHost:
        final c = GameEngine.intOf(m['c']);
        final a = m['a'];
        if (c == null || a is! Map<String, dynamic>) return;
        _hostAct(from, c, a);
    }
  }

  /// شات اللعبة مقفول على حد (الميتين في المافيا) — صاحب الغرفة بيقول في الحالة.
  bool _canSay(String id) {
    final muted = view['mute'];
    return muted is! List || !muted.contains(id);
  }

  void _readPlayers(Map<String, dynamic> m) {
    final p = m['p'];
    if (p is List) {
      players = [
        for (final x in p.take(kind.maxPlayers))
          if (x is String && MeshRouter.isId(x)) x,
      ];
    }
    final nm = m['nm'];
    if (nm is Map) {
      for (final e in nm.entries) {
        if (e.key is String && e.value is String) names[e.key as String] = _cleanName(e.value as String);
      }
    }
  }

  static String _cleanName(String s) {
    final t = s.replaceAll(RegExp(r'[\u0000-\u001f]'), '').trim();
    if (t.isEmpty) return '…';
    return t.length > 24 ? t.substring(0, 24) : t;
  }

  void _addReaction(String who, String e) {
    final r = GameReaction(who, e);
    reactions.add(r);
    if (reactions.length > 12) reactions.removeAt(0);
    notifyListeners();
    Timer(const Duration(milliseconds: 2600), () {
      if (reactions.remove(r)) notifyListeners();
    });
  }

  void _addSay(String who, String t, {required bool secret}) {
    chat.add(GameSay(who, t, secret: secret));
    if (chat.length > 80) chat.removeAt(0);
    notifyListeners();
  }

  /// بيتنادى كل ثانية من الـ [GameCenter].
  void pulse(DateTime now) {
    if (phase == RoomPhase.closed) return;
    if (isHost) {
      _hostPulse(now);
      return;
    }
    // صاحب الغرفة ساكت بقاله كتير: خرج أو بعد
    if (now.difference(heard) > hostSilence) {
      _close(RoomEnd.hostLeft);
      return;
    }
    if (_pending.isNotEmpty && now.difference(_sentAt) > const Duration(seconds: 3)) {
      _sentAt = now;
      for (final e in _pending.entries) {
        link.sendTo(host, {'g': id, 'y': 'act', 'c': e.key, 'a': e.value});
      }
    }
  }

  static Duration hostSilence = const Duration(seconds: 25);
  static Duration heartbeat = const Duration(seconds: 5);

  void _close(RoomEnd why) {
    if (phase == RoomPhase.closed) return;
    phase = RoomPhase.closed;
    end = why;
    _pending.clear();
    notifyListeners();
    link.changed(this);
  }

  // ---------------- صاحب الغرفة ----------------

  GameEngine? engine;
  final Map<String, int> _acked = {};
  final Set<String> _again = {};
  DateTime _lastBeat = DateTime.now();

  /// صاحب الغرفة: يفتح اللوبي ويعزم الناس.
  void openLobby(String myName) {
    names[myId] = myName;
    players = [myId];
    link.sendAll({'g': id, 'y': 'inv', 'kind': kind.id, 'hn': myName});
    _broadcastLobby();
  }

  bool get canStart => isHost && phase == RoomPhase.lobby && players.length >= kind.minPlayers;

  void _hostJoin(String who, String name) {
    if (phase != RoomPhase.lobby) {
      // دخل بعد ما بدأت: نبعتله الحالة يتفرج
      _sendState(to: who);
      return;
    }
    names[who] = name;
    if (!players.contains(who)) {
      if (players.length >= kind.maxPlayers) return;
      players.add(who);
    }
    _broadcastLobby();
    // الخاص: أول ما التاني يوافق نبدأ على طول
    if (autoStart && players.length == 2) start();
  }

  void _broadcastLobby() {
    link.sendAll({'g': id, 'y': 'lobby', 'p': players, 'nm': {for (final p in players) p: nameOf(p)}});
    notifyListeners();
    link.changed(this);
  }

  /// يبدأ (أو يعيد) الماتش.
  void start() {
    if (!isHost || players.length < kind.minPlayers) return;
    final factory = engineFactory;
    if (factory == null) return;
    // كل ماتش جديد اللي بيبدأ بيتغيّر
    final order = List<String>.of(players);
    if (round > 0 && order.length > 1) {
      final shift = round % order.length;
      order.setAll(0, [...order.sublist(shift), ...order.sublist(0, shift)]);
    }
    engine = factory(kind, order, rng, options)..host = host;
    phase = RoomPhase.playing;
    _again.clear();
    _publish();
  }

  void _hostAct(String from, int c, Map<String, dynamic> a) {
    if (phase != RoomPhase.playing || !players.contains(from)) return;
    final last = _acked[from] ?? 0;
    if (c <= last && from != myId) {
      _sendState(to: from); // اتعادت: يمكن الحالة موصلتلوش
      return;
    }
    _acked[from] = max(last, c);
    final e = engine;
    if (e == null) return;
    if (a['t'] == 'again') {
      if (!e.over) return;
      _again.add(from);
      // في الخاص الاتنين لازم يوافقوا، في الجروب صاحب الغرفة بيقرر
      if (from == host || _again.containsAll(players)) {
        round++;
        start();
      } else {
        _publish();
      }
      return;
    }
    if (a['t'] == 'msay') {
      _relaySecretSay(from, a['x']);
      return;
    }
    final wasOver = e.over;
    final changed = e.act(from, a);
    if (!wasOver && e.over) _countWin(e);
    if (changed) {
      _publish();
    } else {
      _sendState(to: from);
    }
  }

  /// شات سري: صاحب الغرفة بيسأل القواعد مين يشوفه (المافيا ببعض بالليل).
  void _relaySecretSay(String from, Object? x) {
    final e = engine;
    if (x is! String || x.isEmpty || x.length > GameSay.maxLength || e is! SecretChat) return;
    final to = (e as SecretChat).secretChatOf(from);
    if (!to.contains(from)) return;
    if (to.isEmpty) return;
    for (final p in to) {
      if (p == myId) {
        _addSay(from, x, secret: true);
      } else {
        link.sendTo(p, {'g': id, 'y': 'psay', 'f': from, 't': x});
      }
    }
  }

  void _countWin(GameEngine e) {
    for (final w in e.winners) {
      wins[w] = (wins[w] ?? 0) + 1;
    }
  }

  void _hostLeave(String who) {
    if (phase == RoomPhase.lobby) {
      if (players.remove(who)) _broadcastLobby();
      return;
    }
    final e = engine;
    if (e == null || !players.contains(who)) return;
    final wasOver = e.over;
    e.leave(who);
    players.remove(who);
    if (!wasOver && e.over) _countWin(e);
    if (players.length < 2) {
      _publish();
      close(RoomEnd.ended);
      return;
    }
    _publish();
  }

  /// صاحب الغرفة قفل الغرفة.
  void close(RoomEnd why) {
    if (!isHost || phase == RoomPhase.closed) return;
    link.sendAll({'g': id, 'y': 'bye', 'why': why == RoomEnd.canceled ? 'cancel' : 'end'});
    _close(why);
  }

  void _hostPulse(DateTime now) {
    final e = engine;
    if (phase == RoomPhase.playing && e != null) {
      final wasOver = e.over;
      if (e.tick(now)) {
        if (!wasOver && e.over) _countWin(e);
        _publish();
        return;
      }
    }
    if (now.difference(_lastBeat) >= heartbeat) {
      if (phase == RoomPhase.lobby) {
        _lastBeat = now;
        _broadcastLobby();
      } else if (phase == RoomPhase.playing) {
        _sendState(); // نبضة: نفس الحالة تاني (اللي فاته حاجة يلحقها)
      }
    }
  }

  Map<String, dynamic> _stateMessage() => {
        'g': id,
        'y': 'view',
        'n': n,
        'r': round,
        'p': players,
        'nm': {for (final p in players) p: nameOf(p)},
        'w': wins,
        'ac': _acked,
        'v': view,
      };

  /// حالة جديدة: رقم جديد وتتبعت للكل + الأسرار لأصحابها.
  void _publish() {
    final e = engine;
    if (e == null) return;
    n++;
    view = {...e.view(), if (_again.isNotEmpty) 'again': _again.toList()};
    viewAt = DateTime.now();
    final mine = e.viewFor(myId);
    if (mine != null) secret = mine;
    _sendState();
    notifyListeners();
    link.changed(this);
  }

  void _sendState({String? to}) {
    if (phase != RoomPhase.playing) {
      if (phase == RoomPhase.lobby && to != null) {
        link.sendTo(to, {'g': id, 'y': 'lobby', 'p': players, 'nm': {for (final p in players) p: nameOf(p)}});
      }
      return;
    }
    _lastBeat = DateTime.now();
    final msg = _stateMessage();
    final e = engine;
    if (to == null) {
      link.sendAll(msg);
      if (e != null) {
        for (final p in players) {
          if (p == myId) continue;
          final s = e.viewFor(p);
          if (s != null) link.sendTo(p, {'g': id, 'y': 'pv', 'n': n, 'v': s});
        }
      }
    } else {
      link.sendTo(to, msg);
      final s = e?.viewFor(to);
      if (s != null) link.sendTo(to, {'g': id, 'y': 'pv', 'n': n, 'v': s});
    }
  }
}

/// قواعد فيها شات سري لمجموعة (المافيا بالليل).
abstract interface class SecretChat {
  /// مين يشوف كلام [from] في الشات السري دلوقتي (فاضية = مفيش شات سري).
  List<String> secretChatOf(String from);
}

class GameSay {
  GameSay(this.who, this.text, {this.secret = false}) : at = DateTime.now();
  static const maxLength = 300;
  final String who;
  final String text;
  final bool secret;
  final DateTime at;
}

class GameReaction {
  GameReaction(this.who, this.emoji);
  final String who;
  final String emoji;
}

/// التفاعلات السريعة المسموحة في الألعاب.
class ChatReactions {
  ChatReactions._();
  static const all = ['😂', '😤', '👏', '🔥', '😱', '🤝'];
  static bool valid(String e) => all.contains(e);
}
