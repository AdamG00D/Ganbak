import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/identity.dart';
import '../../../widgets/ui.dart';
import '../core/game_engine.dart';
import '../core/game_room.dart';
import '../engines/secret_games.dart';
import 'game_screen.dart';

List<String> _order(GameRoom room) => (room.view['o'] as List?)?.cast<String>() ?? room.players;

// =====================================================================
// حجر ورقة مقص
// =====================================================================

class RpsBoard extends StatelessWidget {
  const RpsBoard({super.key, required this.room});
  final GameRoom room;

  static const emoji = {'r': '✊', 'p': '✋', 's': '✌️'};

  static String label(String c, AppLocalizations l) => switch (c) {
    'r' => l.rpsRock,
    'p' => l.rpsPaper,
    _ => l.rpsScissors,
  };

  void _pick(String c) {
    final salt = GameEngine.newSalt();
    // الاختيار بيفضل عندي، وبيروح بصمته بس — الكشف بيحصل لوحده لما التاني يختار
    room.local['pick'] = {'c': c, 's': salt, 'k': room.view['k'], 'r': room.round};
    HapticFeedback.mediumImpact();
    room.act({'t': 'commit', 'h': GameEngine.commit(c, salt)});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final v = room.view;
    final order = _order(room);
    final me = room.myId;
    final other = order.firstWhere((x) => x != me, orElse: () => order.last);
    final ready = (v['ready'] as List?)?.cast<String>() ?? const [];
    final hist = (v['hist'] as List?)?.cast<Map>() ?? const [];
    final score = {for (final e in (v['s'] as Map? ?? const {}).entries) '${e.key}': (e.value as num).toInt()};
    final iPicked = ready.contains(me);
    final last = hist.isEmpty ? null : hist.last;
    final cheat = v['cheat'] as String?;
    return Column(
      children: [
        DuelHeader(room: room, scores: score),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.rpsFirstTo('${v['target'] ?? 2}'), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (last != null) _Throw(room: room, last: last, me: me, other: other),
                  if (cheat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        l.gameCheated(room.nameOf(cheat)),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.danger, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 22),
                  if (!room.over && room.joined) ...[
                    Text(
                      iPicked
                          ? l.rpsPicked(room.nameOf(other))
                          : ready.contains(other)
                          ? '${l.rpsTheyPicked(room.nameOf(other))} — ${l.rpsPick}'
                          : l.rpsPick,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final c in const ['r', 'p', 's'])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _Choice(
                              emoji: emoji[c]!,
                              label: label(c, l),
                              selected: iPicked && (room.local['pick'] as Map?)?['c'] == c,
                              onTap: iPicked ? null : () => _pick(c),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Throw extends StatelessWidget {
  const _Throw({required this.room, required this.last, required this.me, required this.other});
  final GameRoom room;
  final Map last;
  final String me, other;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final mine = last[me] as String?, theirs = last[other] as String?;
    final w = last['w'];
    Widget hand(String? c, bool won) => Column(
      children: [
        AnimatedScale(
          scale: won ? 1.15 : 0.9,
          duration: const Duration(milliseconds: 300),
          child: Text(RpsBoard.emoji[c] ?? '❔', style: const TextStyle(fontSize: 64)),
        ),
        Text(
          c == null ? '' : RpsBoard.label(c, l),
          style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              hand(mine, w == me),
              Text(
                'VS',
                style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700),
              ),
              hand(theirs, w == other),
            ],
          ),
          if (w == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.rpsTie,
                style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.emoji, required this.label, this.selected = false, this.onTap});
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Opacity(
      opacity: onTap == null && !selected ? 0.45 : 1,
      child: StitchedBox(
        color: selected ? p.saffron : GameColors.rps,
        radius: 22,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: selected ? p.ink : Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// حرب السفن
// =====================================================================

class BattleshipBoard extends StatefulWidget {
  const BattleshipBoard({super.key, required this.room});
  final GameRoom room;

  @override
  State<BattleshipBoard> createState() => _BattleshipBoardState();
}

class _BattleshipBoardState extends State<BattleshipBoard> {
  GameRoom get room => widget.room;
  final _rng = Random.secure();

  String get _board {
    // لوح الماتش ده (رصّة جديدة مع كل ماتش)
    if (room.local['draftRound'] != room.round || room.local['draft'] is! String) {
      room.local['draft'] = BattleshipEngine.randomBoard(_rng);
      room.local['draftRound'] = room.round;
    }
    return room.local['draft'] as String;
  }

  void _shuffle() {
    HapticFeedback.selectionClick();
    setState(() => room.local['draft'] = BattleshipEngine.randomBoard(_rng));
  }

  void _ready() {
    final board = _board;
    final salt = GameEngine.newSalt();
    room.local
      ..['board'] = board
      ..['salt'] = salt
      ..['boardRound'] = room.round;
    HapticFeedback.mediumImpact();
    room.act({'t': 'ready', 'h': GameEngine.commit(board, salt)});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final v = room.view;
    final order = _order(room);
    final me = room.myId;
    final other = order.firstWhere((x) => x != me, orElse: () => order.last);
    final ready = (v['ready'] as List?)?.cast<String>() ?? const [];
    final shots = v['shots'] as Map? ?? const {};
    final myShots = _shotMap(shots[me]);
    final theirShots = _shotMap(shots[other]);
    final placed = room.local['boardRound'] == room.round && room.local['board'] is String;
    final hits = {for (final id in order) id: _shotMap(shots[id]).values.where((x) => x > 0).length};

    if (v['phase'] == 'place') {
      final iReady = ready.contains(me);
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(
            iReady ? l.bsWaitingThem(room.nameOf(other)) : l.bsPlace,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _Sea(board: iReady ? room.local['board'] as String : _board, shots: const {}, showShips: true),
            ),
          ),
          const SizedBox(height: 16),
          if (!iReady && room.joined)
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: l.bsShuffle, icon: Icons.shuffle_rounded, onPressed: _shuffle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(label: l.bsReady, icon: Icons.check_rounded, onPressed: _ready),
                ),
              ],
            )
          else
            const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))),
        ],
      );
    }

    final myTurn = v['turn'] == me && v['pending'] == null && !room.over;
    final lastMine = _lastResult(myShots);
    final revealed = v['revealed'] as Map? ?? const {};
    final theirBoard = revealed[other] as String?;
    return Column(
      children: [
        DuelHeader(room: room, scores: hits),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l.bsTheirSea(room.nameOf(other)), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    l.bsLeft('${BattleshipEngine.shipCells - (hits[me] ?? 0)}'),
                    style: TextStyle(color: p.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _Sea(
                    board: theirBoard,
                    shots: myShots,
                    showShips: theirBoard != null,
                    onTap: myTurn
                        ? (i) {
                            if (myShots.containsKey(i)) return;
                            HapticFeedback.mediumImpact();
                            room.act({'t': 'shot', 'i': i});
                          }
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // بحري صغير جنب الحالة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.bsYourSea,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: p.textMuted),
                        ),
                        const SizedBox(height: 4),
                        _Sea(
                          board: placed ? room.local['board'] as String : null,
                          shots: theirShots,
                          showShips: true,
                          small: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastMine == 2
                                ? l.bsSunk
                                : lastMine == 1
                                ? l.bsHit
                                : myTurn
                                ? l.bsTapToFire
                                : lastMine == 0
                                ? l.bsMiss
                                : '',
                            style: TextStyle(
                              color: lastMine != null && lastMine > 0 ? p.tentRed : p.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          if (v['cheat'] != null)
                            Text(
                              l.gameCheated(room.nameOf(v['cheat'] as String)),
                              style: TextStyle(color: p.danger, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Map<int, int> _shotMap(Object? raw) => {
    if (raw is Map)
      for (final e in raw.entries)
        if (int.tryParse('${e.key}') != null && e.value is num) int.parse('${e.key}'): (e.value as num).toInt(),
  };

  /// آخر رد على ضرباتي (حسب ترتيب الإضافة).
  static int? _lastResult(Map<int, int> shots) => shots.isEmpty ? null : shots.values.last;
}

/// البحر 8×8: سفن (لو ظاهرة) + الضربات (○ مياه، ✕ إصابة، مليان = غرقت).
class _Sea extends StatelessWidget {
  const _Sea({required this.board, required this.shots, this.showShips = false, this.onTap, this.small = false});

  final String? board;
  final Map<int, int> shots;
  final bool showShips;
  final void Function(int cell)? onTap;
  final bool small;

  static const n = BattleshipEngine.size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sea = p.isDark ? const Color(0xFF0B5E60) : const Color(0xFFD6EFEE);
    final water = p.isDark ? const Color(0xFF0E7375) : const Color(0xFFBFE6E4);
    // البحر مبيتقلبش مع العربي (الاتنين يشوفوا نفس الخانات)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: sea,
            borderRadius: BorderRadius.circular(small ? 12 : 18),
            border: onTap != null ? Border.all(color: p.saffron, width: 2) : null,
          ),
          child: GridView.count(
            crossAxisCount: n,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: small ? 2 : 3,
            crossAxisSpacing: small ? 2 : 3,
            children: [for (var i = 0; i < n * n; i++) _cell(context, i, p, water)],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int i, Palette p, Color water) {
    final ship = showShips && board != null && board![i] != '.';
    final s = shots[i];
    final color = s == 2
        ? p.tentRed
        : ship
        ? (p.isDark ? const Color(0xFF2A3060) : p.ink)
        : water;
    Widget? mark;
    if (s == 0) {
      mark = Icon(Icons.circle_outlined, size: small ? 8 : 12, color: p.isDark ? Colors.white54 : p.textMuted);
    } else if (s == 1) {
      mark = Icon(Icons.close_rounded, size: small ? 14 : 22, color: p.tentRed);
    } else if (s == 2) {
      mark = Icon(Icons.close_rounded, size: small ? 14 : 22, color: Colors.white);
    } else if (s == -1) {
      mark = SizedBox(
        width: small ? 8 : 12,
        height: small ? 8 : 12,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(small ? 3 : 5),
      child: InkWell(
        onTap: onTap == null || s != null ? null : () => onTap!(i),
        borderRadius: BorderRadius.circular(small ? 3 : 5),
        child: Center(child: mark),
      ),
    );
  }
}
