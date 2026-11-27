import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/feedback.dart';
import '../../../widgets/identity.dart';
import '../../../widgets/ui.dart';
import '../../hub/chat_hub.dart';
import '../core/game_kind.dart';
import '../core/game_room.dart';
import '../core/view_read.dart';
import '../data/quiz_bank.dart';
import 'boards_classic.dart';
import 'boards_party.dart';
import 'boards_secret.dart';
import 'game_help.dart';
import 'game_look.dart';

/// شاشة اللعبة: اللوبي ← اللوح ← النتيجة. الخروج منها مش بيوقف اللعبة.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.room, this.title});

  final GameRoom room;

  /// اسم المحادثة (للشريط اللي فوق).
  final String? title;

  static Future<void> open(BuildContext context, Conversation c, GameRoom room) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GameScreen(room: room, title: c.title),
    ),
  );

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameRoom get room => widget.room;
  int _celebrated = -1;
  bool _wasOver = false;

  @override
  void initState() {
    super.initState();
    room.addListener(_onRoom);
    _wasOver = room.over;
  }

  @override
  void dispose() {
    room.removeListener(_onRoom);
    super.dispose();
  }

  void _onRoom() {
    if (!mounted) return;
    // الماتش لسه خالص: احتفال لو كسبت
    if (room.over && !_wasOver && _celebrated != room.round) {
      _celebrated = room.round;
      if (room.winners.contains(room.myId)) {
        HapticFeedback.mediumImpact();
        celebrate(context);
      }
    }
    _wasOver = room.over;
  }

  Future<void> _leave() async {
    final l = context.l10n;
    if (room.phase == RoomPhase.closed) {
      Navigator.maybePop(context);
      return;
    }
    final ok = await confirmDialog(
      context,
      title: room.isHost ? l.gameEndQ : l.gameQuitQ,
      message: room.isHost ? l.gameEndBody : (room.players.length <= 2 ? l.gameQuitBody2 : l.gameQuitBody),
      confirm: l.gameLeave,
      destructive: true,
    );
    if (!ok || !mounted) return;
    room.quit();
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: ListenableBuilder(
        listenable: room,
        builder: (context, _) => Stack(
          children: [
            Column(
              children: [
                _TopBar(room: room, onLeave: _leave),
                Expanded(child: _body()),
                if (room.phase == RoomPhase.playing && room.over) ResultBar(room: room),
                if (room.phase == RoomPhase.playing && room.joined && !room.over) ReactionBar(room: room),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(child: FloatingReactions(room: room)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (room.phase) {
      case RoomPhase.lobby:
        return GameLobby(room: room);
      case RoomPhase.closed:
        return _Closed(room: room);
      case RoomPhase.playing:
        // مفيش حالة لسه، أو حالة شكلها بايظ (طبقة تانية ورا الفحص اللي في GameRoom)
        if (room.view.isEmpty || !ViewGuard.valid(room.kind, room.view)) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (room.kind) {
          GameKind.xo => XoBoard(room: room),
          GameKind.connect4 => Connect4Board(room: room),
          GameKind.dots => DotsBoard(room: room),
          GameKind.memory => MemoryBoard(room: room),
          GameKind.rps => RpsBoard(room: room),
          GameKind.battleship => BattleshipBoard(room: room),
          GameKind.spy => SpyBoard(room: room),
          GameKind.quiz => QuizBoard(room: room),
          GameKind.mafia => MafiaBoard(room: room),
        };
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.room, required this.onLeave});

  final GameRoom room;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final color = GameLook.color(room.kind);
    final sub = room.phase == RoomPhase.playing && room.round > 0
        ? l.gameRound('${room.round + 1}')
        : GameLook.tag(room.kind, l);
    return Padding(
      padding: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top + 4, start: 4, end: 10, bottom: 4),
      child: Row(
        children: [
          IconButton(tooltip: l.back, onPressed: () => Navigator.maybePop(context), icon: const BackButtonIcon()),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
            child: Icon(GameLook.icon(room.kind), color: Palette.onColor(color), size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GameLook.name(room.kind, l),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textMuted, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          HelpButton(onPressed: () => GameHelpPage.open(context, room.kind)),
          if (room.phase != RoomPhase.closed)
            IconButton(
              tooltip: l.gameLeave,
              onPressed: onLeave,
              icon: Icon(Icons.logout_rounded, color: p.textMuted),
            ),
        ],
      ),
    );
  }
}

// ---------------- اللوبي ----------------

class GameLobby extends StatelessWidget {
  const GameLobby({super.key, required this.room});

  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final k = room.kind;
    final direct = room.autoStart;
    final color = GameLook.color(k);
    final missing = k.minPlayers - room.players.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        StitchedBox(
          color: color,
          pattern: true,
          radius: 24,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            children: [
              Icon(GameLook.icon(k), size: 40, color: Palette.onColor(color)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      direct
                          ? (room.isHost
                                ? l.gameWaitingPeer(_other(room, l))
                                : l.gameInviteFrom(room.nameOf(room.host), GameLook.name(k, l)))
                          : l.gameSeats('${room.players.length}', '${k.maxPlayers}'),
                      style: TextStyle(
                        color: Palette.onColor(color),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    if (!direct)
                      Text(
                        missing > 0 ? l.gameNeedMore('$missing') : l.gameWaitingHost(room.nameOf(room.host)),
                        style: TextStyle(color: Palette.onColor(color).withValues(alpha: 0.85), fontSize: 13.5),
                      ),
                  ],
                ),
              ),
              if (direct && room.isHost)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Palette.onColor(color)),
                ),
            ],
          ),
        ),
        if (!direct) ...[
          SectionLabel(l.gamePlayers),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final id in room.players)
                  ListTile(
                    leading: PlayerAvatar(room: room, id: id, size: 40),
                    title: Text(room.nameOf(id), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: id == room.host
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              l.gameHost,
                              style: TextStyle(color: p.accentInk, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ],
        if (room.isHost && k == GameKind.quiz) QuizOptions(room: room),
        const SizedBox(height: 18),
        if (room.isHost && !direct)
          PrimaryButton(
            label: l.gameStart,
            icon: Icons.play_arrow_rounded,
            onPressed: room.canStart ? room.start : null,
          )
        else if (!room.isHost && !room.joined)
          PrimaryButton(
            label: direct ? l.gamePlay : l.gameJoin,
            icon: Icons.sports_esports_rounded,
            onPressed: room.join,
          )
        else if (!room.isHost && room.joined)
          SecondaryButton(label: l.gameLeave, icon: Icons.logout_rounded, onPressed: room.unjoin),
      ],
    );
  }

  static String _other(GameRoom room, AppLocalizations l) {
    final c = ChatHub.instance.directFor(room.host == room.myId ? '' : room.host);
    return c?.title ?? l.theOtherSide;
  }
}

/// اختيارات المسابقة (صاحب الغرفة قبل ما يبدأ).
class QuizOptions extends StatefulWidget {
  const QuizOptions({super.key, required this.room});
  final GameRoom room;

  @override
  State<QuizOptions> createState() => _QuizOptionsState();
}

class _QuizOptionsState extends State<QuizOptions> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final o = widget.room.options;
    final cat = o['cat'] as String?;
    final count = o['count'] as int? ?? 10;
    String label(String pair) {
      final i = pair.indexOf('|');
      return ar ? pair.substring(0, i) : pair.substring(i + 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.quizCategory),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l.quizMixed),
              selected: cat == null,
              onSelected: (_) => setState(() => o.remove('cat')),
            ),
            for (final c in QuizBank.categories)
              ChoiceChip(label: Text(label(c)), selected: cat == c, onSelected: (_) => setState(() => o['cat'] = c)),
          ],
        ),
        SectionLabel(l.quizCount),
        Wrap(
          spacing: 8,
          children: [
            for (final n in const [5, 10, 20])
              ChoiceChip(label: Text('$n'), selected: count == n, onSelected: (_) => setState(() => o['count'] = n)),
          ],
        ),
      ],
    );
  }
}

class _Closed extends StatelessWidget {
  const _Closed({required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EmptyState(
      icon: GameLook.icon(room.kind),
      title: switch (room.end) {
        RoomEnd.hostLeft => l.gameHostLeft,
        RoomEnd.canceled => l.gameCanceled,
        _ => l.gameEnded,
      },
      message: room.wins.isEmpty ? null : _winsLine(room),
      action: SizedBox(
        width: 220,
        child: PrimaryButton(
          label: l.gameBackToChat,
          icon: Icons.chat_rounded,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}

String _winsLine(GameRoom room) =>
    [for (final e in room.wins.entries) '${room.nameOf(e.key)} ${e.value}'].join('  •  ');

// ---------------- النتيجة ----------------

/// تحت اللوح لما الماتش يخلص: مين كسب + ماتش تاني.
class ResultBar extends StatelessWidget {
  const ResultBar({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final w = room.winners;
    final me = room.myId;
    final text = w.isEmpty
        ? l.gameDraw
        : w.contains(me)
        ? l.gameYouWon
        : room.joined && w.length == 1
        ? (room.players.length <= 2 ? l.gameYouLost : l.gameWinner(room.nameOf(w.single)))
        : l.gameWinner(w.map(room.nameOf).join('، '));
    final again = ViewRead.strs(room.view['again']);
    final iAsked = again.contains(me);
    final canAgain = room.joined && (room.autoStart || room.isHost);
    final asked = again.where((x) => x != me).toList();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (room.wins.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${l.gameWins}: ${_winsLine(room)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 12.5),
              ),
            ),
          if (asked.isNotEmpty && !iAsked)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.gameRematchAsked(room.nameOf(asked.first)),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l.gameBackToChat,
                  icon: Icons.chat_bubble_outline_rounded,
                  height: 48,
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              if (canAgain) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: iAsked ? l.gameRematchWaiting : l.gameRematch,
                    icon: Icons.replay_rounded,
                    height: 48,
                    onPressed: iAsked ? null : () => room.act({'t': 'again'}),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- التفاعلات ----------------

class ReactionBar extends StatelessWidget {
  const ReactionBar({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8 + MediaQuery.paddingOf(context).bottom),
      // بيصغر لو الخط كبير أو الشاشة ضيقة (مبيخرجش برا)
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in ChatReactions.all)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: p.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: p.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      room.react(e);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// التفاعلات بتطلع من تحت وتطير لفوق وتختفي.
class FloatingReactions extends StatelessWidget {
  const FloatingReactions({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          for (final r in room.reactions)
            TweenAnimationBuilder<double>(
              key: ObjectKey(r),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 2400),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                final x = (r.who.hashCode % 1000) / 1000 * (box.maxWidth - 120) + 20;
                return PositionedDirectional(
                  start: x,
                  bottom: 70 + t * box.maxHeight * 0.45,
                  child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 4),
                    Text(
                      room.nameOf(r.who),
                      style: TextStyle(fontSize: 11.5, color: p.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- رأس المواجهة (لاعبين اتنين) ----------------

/// أنا ضد التاني: الأفاتارات والنتيجة ومين عليه الدور.
class DuelHeader extends StatelessWidget {
  const DuelHeader({super.key, required this.room, this.scores, this.colors});

  final GameRoom room;

  /// نقط الماتش (لو null = مرات الكسب في الغرفة).
  final Map<String, int>? scores;

  /// لون كل لاعب على اللوح.
  final Map<String, Color>? colors;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final order = ViewRead.order(room.view, room.players);
    final me = room.myId;
    final mine = order.contains(me) ? me : order.first;
    final other = order.firstWhere((x) => x != mine, orElse: () => mine);
    final s = scores ?? room.wins;
    final turn = room.view['turn'];

    Widget side(String id, bool end) {
      final active = turn == id;
      return Expanded(
        child: Row(
          mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (end) Flexible(child: _name(id, active, p)),
            if (end) const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? (colors?[id] ?? p.accent) : Colors.transparent, width: 2.5),
              ),
              child: PlayerAvatar(room: room, id: id, size: 34),
            ),
            if (!end) const SizedBox(width: 8),
            if (!end) Flexible(child: _name(id, active, p)),
          ],
        ),
      );
    }

    final turnText = turn == null
        ? null
        : turn == me
        ? l.gameYourTurn
        : l.gameTheirTurn(room.nameOf('$turn'));
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              side(mine, false),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${s[mine] ?? 0}  –  ${s[other] ?? 0}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              side(other, true),
            ],
          ),
        ),
        if (turnText != null && !room.over)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: turn == me ? p.saffron : p.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              turnText,
              style: TextStyle(color: turn == me ? p.ink : p.textMuted, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _name(String id, bool active, Palette p) => Text(
    room.nameOf(id),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5),
  );
}

/// نقط أكتر من لاعبين (المربعات والذاكرة في الجروب).
class ScoreStrip extends StatelessWidget {
  const ScoreStrip({super.key, required this.room, required this.scores, required this.colors});

  final GameRoom room;
  final List<int> scores;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final order = ViewRead.order(room.view, room.players);
    final gone = ViewRead.strs(room.view['gone']);
    final turn = room.view['turn'];
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: order.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final id = order[i];
              final active = turn == id;
              return Container(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 12, 6),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: active ? colors[i % colors.length] : p.border, width: active ? 2.5 : 1),
                ),
                child: Row(
                  children: [
                    PlayerAvatar(room: room, id: id, size: 34, dim: gone.contains(id)),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.nameOf(id),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.2),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${i < scores.length ? scores[i] : 0}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (turn != null && !room.over)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: turn == room.myId ? p.saffron : p.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                turn == room.myId ? l.gameYourTurn : l.gameTheirTurn(room.nameOf('$turn')),
                style: TextStyle(
                  color: turn == room.myId ? p.ink : p.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- شات اللعبة ----------------

/// شات جوه اللعبة (التلميحات في الجاسوس، والنقاش في المافيا). [secret] = شات المافيا بالليل.
class GameChatPanel extends StatefulWidget {
  const GameChatPanel({super.key, required this.room, this.secret = false, this.enabled = true, this.height = 190});

  final GameRoom room;
  final bool secret;
  final bool enabled;
  final double height;

  @override
  State<GameChatPanel> createState() => _GameChatPanelState();
}

class _GameChatPanelState extends State<GameChatPanel> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.room.say(t, secret: widget.secret);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final room = widget.room;
    final lines = room.chat.where((x) => x.secret == widget.secret).toList().reversed.toList();
    return Container(
      height: widget.height,
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: widget.secret ? p.ink : p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.secret ? p.tentRed.withValues(alpha: 0.6) : p.border),
      ),
      child: Column(
        children: [
          if (widget.secret)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.mafiaSecretChat,
                style: TextStyle(color: p.saffron, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              itemCount: lines.length,
              itemBuilder: (_, i) {
                final s = lines[i];
                final fg = widget.secret ? Colors.white : p.text;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${room.nameOf(s.who)}: ',
                          style: TextStyle(fontWeight: FontWeight.w700, color: widget.secret ? p.saffron : p.accentInk),
                        ),
                        TextSpan(text: s.text),
                      ],
                    ),
                    style: TextStyle(color: fg, fontSize: 14, height: 1.45),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: widget.enabled,
                    maxLength: GameSay.maxLength,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    style: TextStyle(color: widget.secret ? Colors.white : p.text, fontSize: 14.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.enabled ? l.gameChatHint : l.gameChatMuted,
                      hintStyle: TextStyle(color: widget.secret ? Colors.white54 : p.textMuted),
                      fillColor: widget.secret ? Colors.white.withValues(alpha: 0.08) : p.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.enabled ? _send : null,
                  icon: Icon(Icons.send_rounded, color: widget.secret ? p.saffron : p.accentInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// عدّاد تنازلي صغير (بيتحدّث كل ثانية).
class CountdownChip extends StatefulWidget {
  const CountdownChip({super.key, required this.room});
  final GameRoom room;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> with SingleTickerProviderStateMixin {
  late final AnimationController _tick = AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat();

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        final left = widget.room.timeLeft;
        if (left == null) return const SizedBox.shrink();
        final s = (left.inMilliseconds / 1000).ceil();
        final urgent = s <= 10;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: urgent ? p.tentRed : p.surfaceAlt, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 15, color: urgent ? Colors.white : p.textMuted),
              const SizedBox(width: 4),
              Text(
                s >= 60 ? '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}' : '$s',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: urgent ? Colors.white : p.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
