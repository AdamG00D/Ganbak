import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/identity.dart';
import '../../../widgets/ui.dart';
import '../core/game_room.dart';
import '../core/view_read.dart';
import '../data/spy_words.dart';
import 'game_look.dart';
import 'game_screen.dart';

List<String> _order(GameRoom room) => ViewRead.order(room.view, room.players);
List<String> _strings(Object? raw) => ViewRead.strs(raw);

/// "عربي|إنجليزي" ← النص بلغة التطبيق.
String _pick(BuildContext context, Object? pair) {
  if (pair is! String) return '';
  final i = pair.indexOf('|');
  if (i < 0) return pair;
  return Localizations.localeOf(context).languageCode == 'ar' ? pair.substring(0, i) : pair.substring(i + 1);
}

/// قايمة لاعبين تختار منهم (تصويت / ليل المافيا).
class _PickList extends StatelessWidget {
  const _PickList({required this.room, required this.ids, required this.selected, required this.onPick, this.extra});

  final GameRoom room;
  final List<String> ids;
  final String? selected;
  final ValueChanged<String>? onPick;

  /// اختيار زيادة في الآخر (زي "محدش").
  final (String id, String label)? extra;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final id in ids)
            ListTile(
              leading: PlayerAvatar(room: room, id: id, size: 38),
              title: Text(room.nameOf(id), style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: selected == id
                  ? Icon(Icons.check_circle_rounded, color: p.accentInk)
                  : Icon(Icons.radio_button_unchecked_rounded, color: p.border),
              onTap: onPick == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onPick!(id);
                    },
            ),
          if (extra != null)
            ListTile(
              leading: Icon(Icons.block_rounded, color: p.textMuted),
              title: Text(extra!.$2),
              trailing: selected == extra!.$1
                  ? Icon(Icons.check_circle_rounded, color: p.accentInk)
                  : Icon(Icons.radio_button_unchecked_rounded, color: p.border),
              onTap: onPick == null ? null : () => onPick!(extra!.$1),
            ),
        ],
      ),
    );
  }
}

/// كارت سري: بيتخبّى لحد ما تدوس عليه (عشان اللي جنبك ميشوفش).
class _SecretCard extends StatefulWidget {
  const _SecretCard({required this.color, required this.child, required this.label});
  final Color color;
  final Widget child;
  final String label;

  @override
  State<_SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<_SecretCard> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fg = Palette.onColor(widget.color);
    return StitchedBox(
      color: widget.color,
      pattern: true,
      radius: 22,
      onTap: () => setState(() => _shown = !_shown),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _shown
            ? Row(
                children: [
                  Expanded(child: widget.child),
                  Icon(Icons.visibility_off_rounded, color: fg.withValues(alpha: 0.7)),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: fg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(l.spyTapToShow, style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// =====================================================================
// مين الجاسوس
// =====================================================================

class SpyBoard extends StatelessWidget {
  const SpyBoard({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final v = room.view;
    final me = room.myId;
    // دوري اتعرف على موبايلي من التوزيع العادل (صاحب الغرفة مبيعرفوش)
    final role = room.local['role@${room.round}'];
    final words = SpyWords.categories[v['cat']] ?? const <String>[];
    final s = role is Map
        ? {
            'spy': role['spy'] == true,
            'cat': v['cat'],
            if (role['w'] is int && (role['w'] as int) < words.length) 'word': words[role['w'] as int],
          }
        : const <String, dynamic>{};
    final order = _order(room);
    final phase = v['phase'];
    final spy = s['spy'] == true;
    final voted = _strings(v['voted']);
    final turn = ViewRead.str(v['turn']);
    final children = <Widget>[];

    if (room.joined && s.isNotEmpty) {
      children.add(_SecretCard(
        color: spy ? GameColors.mafia : GameColors.spy,
        label: l.spyYourCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spy ? '🕵️ ${l.spyYouAreSpy}' : '${l.spyWordIs}: ${_pick(context, s['word'])}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20, height: 1.4),
            ),
            Text(l.spyCategory(_pick(context, s['cat'])), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ));
    }

    Widget waiting(String title, String? sub) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: StitchedBox(
            color: p.isDark ? const Color(0xFF2A3060) : p.ink,
            pattern: true,
            radius: 22,
            stitch: p.saffron.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, color: p.saffron)),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, height: 1.5)),
                if (sub != null) ...[
                  const SizedBox(height: 6),
                  Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
                ],
              ],
            ),
          ),
        );

    switch (phase) {
      case 'give' || 'mix' || 'strip':
        final step = switch (phase) {
          'give' => 0,
          'mix' => 1 + (ViewRead.integer(v['chain']) ?? 0),
          _ => 1 + order.length + (ViewRead.integer(v['chain']) ?? 0),
        };
        children.add(waiting(l.spyDealing('$step', '${2 * order.length + 1}'), l.spyDealingSub));
      case 'prove':
        final caught = ViewRead.str(v['caught']);
        children.add(waiting(l.spyProving(room.nameOf(caught ?? '')), null));
      case 'open':
        children.add(waiting(l.spyChecking, null));
      case 'clue':
        children.addAll([
          const SizedBox(height: 14),
          Text(
            turn == me ? l.spyYourClue : l.spyClueTurn(room.nameOf(turn ?? '')),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            l.spyClues('${(ViewRead.integer(v['clue']) ?? 0) + 1}', '${ViewRead.integer(v['clues']) ?? 0}'),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          _TurnRow(room: room, order: order, turn: turn),
          const SizedBox(height: 10),
          Row(
            children: [
              if (turn == me)
                Expanded(child: PrimaryButton(label: l.spyDone, icon: Icons.check_rounded, height: 48, onPressed: () => room.act({'t': 'done'}))),
              if (room.isHost && turn != me) ...[
                Expanded(child: SecondaryButton(label: l.spyPass, height: 48, onPressed: () => room.act({'t': 'done'}))),
              ],
              if (room.isHost) ...[
                const SizedBox(width: 8),
                Expanded(child: SecondaryButton(label: l.spyToVote, height: 48, onPressed: () => room.act({'t': 'skip'}))),
              ],
            ],
          ),
        ]);
      case 'vote':
        final iVoted = voted.contains(me);
        children.addAll([
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text(l.spyVoteTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              CountdownChip(room: room),
            ],
          ),
          Text(l.spyVoted('${voted.length}', '${order.length}'), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
          const SizedBox(height: 8),
          if (iVoted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.spyYourVote, textAlign: TextAlign.center, style: TextStyle(color: p.success, fontWeight: FontWeight.w700)),
            )
          else if (room.joined)
            _PickList(
              room: room,
              ids: order.where((x) => x != me).toList(),
              selected: null,
              onPick: (id) => room.act({'t': 'vote', 'for': id}),
            ),
        ]);
      case 'guess':
        final caught = ViewRead.str(v['caught']);
        final options = _strings(v['options']);
        children.addAll([
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  caught == me ? l.spyGuessNow : l.spyGuessing(room.nameOf(caught ?? '')),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.5),
                ),
              ),
              CountdownChip(room: room),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < options.length; i++)
                ActionChip(
                  label: Text(_pick(context, options[i])),
                  onPressed: caught == me ? () => room.act({'t': 'guess', 'i': i}) : null,
                ),
            ],
          ),
        ]);
      case 'done':
        final spyId = ViewRead.str(v['spy']);
        final caught = ViewRead.str(v['caught']);
        children.addAll([
          const SizedBox(height: 14),
          StitchedBox(
            color: p.surface,
            stitch: p.border,
            radius: 22,
            child: Column(
              children: [
                if (spyId != null) PlayerAvatar(room: room, id: spyId, size: 64),
                const SizedBox(height: 8),
                Text(l.spyWas(room.nameOf(spyId ?? '')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(l.spyWordWas(_pick(context, v['word'])), style: TextStyle(color: p.textMuted, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  caught == null
                      ? l.spyNotCaught
                      : caught != spyId
                          ? l.spyWrongCaught(room.nameOf(caught))
                          : v['guess'] != null
                              ? l.spyGuessed(_pick(context, v['guess']))
                              : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w600),
                ),
                if (_strings(v['cheat']).isNotEmpty || v['failed'] == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    _strings(v['cheat']).isEmpty
                        ? l.spyFailed
                        : l.spyCheat(_strings(v['cheat']).map(room.nameOf).join('، ')),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.danger, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ]);
    }

    return Column(
      children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 8), children: children)),
        if (phase == 'clue' || phase == 'vote') GameChatPanel(room: room, enabled: room.joined, height: 170),
      ],
    );
  }
}

/// دور مين (أفاتارات بالترتيب، اللي عليه الدور متعلّم).
class _TurnRow extends StatelessWidget {
  const _TurnRow({required this.room, required this.order, required this.turn});
  final GameRoom room;
  final List<String> order;
  final String? turn;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // ارتفاع الصف بيكبر مع حجم الخط (الاسم تحت الأفاتار)
    return SizedBox(
      height: 54 + MediaQuery.textScalerOf(context).scale(11) * 1.5,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: order.length,
        separatorBuilder: (_, _) => SizedBox(width: 14, child: Center(child: StitchLine(color: p.textMuted.withValues(alpha: 0.5)))),
        itemBuilder: (_, i) {
          final id = order[i];
          final active = id == turn;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? p.saffron : Colors.transparent, width: 2.5),
                ),
                child: PlayerAvatar(room: room, id: id, size: 38),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 56,
                child: Text(
                  room.nameOf(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// المسابقة
// =====================================================================

class QuizBoard extends StatelessWidget {
  const QuizBoard({super.key, required this.room});
  final GameRoom room;

  static const _optionColors = [GameColors.memory, GameColors.battleship, GameColors.connect4, GameColors.xo];
  static const _shapes = [Icons.change_history_rounded, Icons.circle_outlined, Icons.square_outlined, Icons.star_outline_rounded];

  /// السؤال ظهر عندي إمتى (الوقت بيتحسب على موبايلي).
  DateTime _shownAt(int index) {
    final key = 'q$index@${room.round}';
    return room.local.putIfAbsent(key, DateTime.now) as DateTime;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final v = room.view;
    final me = room.myId;
    final phase = v['phase'];
    final order = _order(room);
    final score = ViewRead.intMap(v['s']);
    final ranking = [...order]..sort((a, b) => (score[b] ?? 0).compareTo(score[a] ?? 0));

    if (phase == 'done') return _Podium(room: room, ranking: ranking, score: score);

    final index = ViewRead.integer(v['i']) ?? 0;
    final shown = _shownAt(index);
    final answered = _strings(v['answered']);
    final opts = _strings(v['opts']);
    final right = ViewRead.integer(v['right']);
    final picks = ViewRead.intMap(v['picks']);
    final gain = ViewRead.intMap(v['gain']);
    final myPick = picks[me] ?? (room.local['ans$index@${room.round}'] as int?);
    final iAnswered = answered.contains(me) || room.local.containsKey('ans$index@${room.round}');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: [
        Row(
          children: [
            // اسم الفئة ممكن يبقى طويل (أو جاي من صاحب الغرفة): بيتقص بدل ما يخرج برا الشاشة
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _pick(context, v['cat']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(l.quizQuestionOf('${index + 1}', '${v['count']}'), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
            const SizedBox(width: 8),
            const Spacer(),
            if (phase == 'q') CountdownChip(room: room),
          ],
        ),
        const SizedBox(height: 12),
        StitchedBox(
          color: GameColors.quiz,
          pattern: true,
          radius: 22,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          child: Text(
            _pick(context, v['q']),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, height: 1.5),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < opts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _QuizOption(
              text: _pick(context, opts[i]),
              color: _optionColors[i % 4],
              icon: _shapes[i % 4],
              state: right == null
                  ? (myPick == i ? _OptState.picked : (iAnswered ? _OptState.dim : _OptState.normal))
                  : (i == right ? _OptState.right : (myPick == i ? _OptState.wrong : _OptState.dim)),
              onTap: phase == 'q' && !iAnswered && room.joined
                  ? () {
                      HapticFeedback.selectionClick();
                      room.local['ans$index@${room.round}'] = i;
                      room.act({'t': 'ans', 'q': index, 'i': i, 'ms': DateTime.now().difference(shown).inMilliseconds});
                    }
                  : null,
            ),
          ),
        const SizedBox(height: 6),
        if (phase == 'q')
          Text(
            l.quizAnswered('${answered.length}', '${order.length}'),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted),
          )
        else ...[
          Text(
            right != null && myPick == right
                ? l.quizRight('${gain[me] ?? 0}')
                : myPick == null
                    ? l.quizTooLate
                    : l.quizWrong,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: right != null && myPick == right ? p.success : p.danger,
            ),
          ),
          const SizedBox(height: 10),
          SectionLabel(l.quizRanking),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var r = 0; r < ranking.length && r < 5; r++)
                  ListTile(
                    dense: true,
                    leading: PlayerAvatar(room: room, id: ranking[r], size: 32),
                    title: Text('${r + 1}. ${room.nameOf(ranking[r])}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(l.quizPoints('${score[ranking[r]] ?? 0}'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _OptState { normal, picked, dim, right, wrong }

class _QuizOption extends StatelessWidget {
  const _QuizOption({required this.text, required this.color, required this.icon, required this.state, this.onTap});
  final String text;
  final Color color;
  final IconData icon;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = switch (state) {
      _OptState.right => p.success,
      _OptState.wrong => p.danger,
      _ => color,
    };
    final fg = Palette.onColor(bg);
    return Opacity(
      opacity: state == _OptState.dim ? 0.45 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: state == _OptState.picked
                ? BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.text, width: 3))
                : null,
            child: Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15.5))),
                if (state == _OptState.right) Icon(Icons.check_circle_rounded, color: fg),
                if (state == _OptState.wrong) Icon(Icons.cancel_rounded, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.room, required this.ranking, required this.score});
  final GameRoom room;
  final List<String> ranking;
  final Map<String, int> score;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final top = ranking.take(3).toList();
    final heights = [120.0, 90.0, 70.0];
    final colors = [p.saffron, const Color(0xFFB8BCD6), const Color(0xFFD08A4E)];
    // الأول في النص، التاني يمين، التالت شمال
    final slots = [if (top.length > 1) 1, 0, if (top.length > 2) 2];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final s in slots)
              Expanded(
                child: Column(
                  children: [
                    PlayerAvatar(room: room, id: top[s], size: s == 0 ? 64 : 50),
                    const SizedBox(height: 4),
                    Text(room.nameOf(top[s]), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(l.quizPoints('${score[top[s]] ?? 0}'), style: TextStyle(color: p.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      height: heights[s],
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: colors[s], borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
                      alignment: Alignment.center,
                      child: Text('${s + 1}', style: TextStyle(color: p.ink, fontSize: 30, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (ranking.length > 3) ...[
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var r = 3; r < ranking.length; r++)
                  ListTile(
                    dense: true,
                    leading: PlayerAvatar(room: room, id: ranking[r], size: 30),
                    title: Text('${r + 1}. ${room.nameOf(ranking[r])}'),
                    trailing: Text(l.quizPoints('${score[ranking[r]] ?? 0}')),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// =====================================================================
// المافيا
// =====================================================================

class MafiaBoard extends StatelessWidget {
  const MafiaBoard({super.key, required this.room});
  final GameRoom room;

  static String roleName(String? role, AppLocalizations l) => switch (role) {
        'mafia' => l.mafiaRoleMafia,
        'doctor' => l.mafiaRoleDoctor,
        'detective' => l.mafiaRoleDetective,
        _ => l.mafiaRoleCitizen,
      };

  static String roleEmoji(String? role) => switch (role) {
        'mafia' => '🔪',
        'doctor' => '💉',
        'detective' => '🔍',
        _ => '👤',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final v = room.view;
    final s = room.secret;
    final me = room.myId;
    final order = _order(room);
    final alive = _strings(v['alive']);
    final phase = ViewRead.str(v['phase']);
    final role = ViewRead.str(s['role']);
    final iAmAlive = alive.contains(me);
    final roles = ViewRead.strMap(v['roles']);
    final night = phase == 'night';
    final children = <Widget>[];

    // دوري (مخفي لحد ما أدوس)
    if (role != null) {
      final team = _strings(s['team']).where((x) => x != me).toList();
      children.add(_SecretCard(
        color: role == 'mafia' ? GameColors.mafia : GameColors.spy,
        label: l.mafiaYourRole,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${roleEmoji(role)} ${roleName(role, l)}',
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, height: 1.4)),
            if (team.isNotEmpty)
              Text(l.mafiaTeam(team.map(room.nameOf).join('، ')), style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ));
      children.add(const SizedBox(height: 12));
    }

    // شريط المرحلة
    final phaseTitle = switch (phase) {
      'night' => l.mafiaNight('${v['day'] ?? 1}'),
      'morning' || 'out' => l.mafiaMorning,
      'talk' => l.mafiaTalk,
      'vote' => l.mafiaVote,
      _ => (v['side'] == 'mafia' ? l.mafiaMafiaWins : l.mafiaTownWins),
    };
    children.add(Row(
      children: [
        Expanded(child: Text(phaseTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        if (phase != 'done') CountdownChip(room: room),
        if (room.isHost && (phase == 'talk' || phase == 'morning' || phase == 'out'))
          TextButton(onPressed: () => room.act({'t': 'skip'}), child: Text(l.mafiaSkip)),
      ],
    ));
    children.add(Text(l.mafiaAlive('${alive.length}'), style: TextStyle(color: p.textMuted, fontSize: 12.5)));
    children.add(const SizedBox(height: 10));

    if (!iAmAlive && room.joined && phase != 'done') {
      children.add(_Banner(icon: Icons.visibility_rounded, text: l.mafiaYouDied, color: p.textMuted));
    }
    // في الآخر: الأدوار اللي اتكشفت هي هي اللي اتوزعت؟ (البصمة المقفولة من الأول)
    if (phase == 'done') {
      final ok = room.local['rolesOk@${room.round}'];
      if (ok == false) {
        children.add(_Banner(icon: Icons.gpp_bad_rounded, text: l.mafiaRolesChanged, color: p.danger));
      } else if (ok == true) {
        children.add(_Banner(icon: Icons.verified_rounded, text: l.mafiaRolesChecked, color: p.success));
      }
    }

    switch (phase) {
      case 'night':
        final targets = alive.where((x) => x != me).toList();
        if (!iAmAlive || role == null || role == 'citizen') {
          children.add(_Banner(icon: Icons.nightlight_round, text: l.mafiaNightWait, color: p.accentInk));
        } else if (role == 'mafia') {
          final kills = ViewRead.strMap(s['kills']);
          final team = _strings(s['team']);
          children.addAll([
            Text(l.mafiaPickKill, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _PickList(
              room: room,
              ids: targets.where((x) => !team.contains(x)).toList(),
              selected: kills[me],
              onPick: (id) => room.act({'t': 'kill', 'for': id}),
            ),
            for (final e in kills.entries)
              if (e.key != me)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${room.nameOf(e.key)} → ${room.nameOf(e.value)}', style: TextStyle(color: p.textMuted, fontSize: 12.5)),
                ),
          ]);
        } else if (role == 'doctor') {
          final saved = ViewRead.str(s['saved']);
          final noSave = ViewRead.str(s['noSave']);
          children.addAll([
            Text(l.mafiaPickSave, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (noSave != null) Text(l.mafiaNoSameTwice, style: TextStyle(color: p.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            saved != null
                ? _Banner(icon: Icons.check_circle_rounded, text: l.mafiaPicked(room.nameOf(saved)), color: p.success)
                : _PickList(
                    room: room,
                    ids: alive.where((x) => x != noSave).toList(),
                    selected: saved,
                    onPick: (id) => room.act({'t': 'save', 'for': id}),
                  ),
          ]);
        } else if (role == 'detective') {
          final checked = ViewRead.str(s['checked']);
          children.addAll([
            Text(l.mafiaPickCheck, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (checked == null)
              _PickList(room: room, ids: targets, selected: null, onPick: (id) => room.act({'t': 'check', 'for': id})),
          ]);
        }
        if (role == 'detective') {
          for (final c in (s['checks'] is List ? s['checks'] as List : const []).reversed) {
            if (c is! List || c.length < 2 || c[0] is! String) continue;
            final who = c[0] as String;
            final bad = c[1] == true;
            children.add(_Banner(
              icon: bad ? Icons.warning_rounded : Icons.verified_rounded,
              text: bad ? l.mafiaIsMafia(room.nameOf(who)) : l.mafiaNotMafia(room.nameOf(who)),
              color: bad ? p.danger : p.success,
            ));
          }
        }
      case 'morning' || 'talk':
        final died = ViewRead.str(v['died']);
        children.add(_Banner(
          icon: died != null ? Icons.sentiment_very_dissatisfied_rounded : Icons.wb_sunny_rounded,
          text: died != null
              ? l.mafiaKilled(room.nameOf(died))
              : v['rescued'] == true
                  ? l.mafiaRescued
                  : l.mafiaQuietNight,
          color: died != null ? p.danger : p.success,
        ));
      case 'vote':
        final voted = _strings(v['voted']);
        children.add(Text(l.mafiaVotedCount('${voted.length}', '${alive.length}'), style: TextStyle(color: p.textMuted)));
        if (iAmAlive) {
          final mine = ViewRead.str(s['myVote']);
          children.add(const SizedBox(height: 6));
          children.add(_PickList(
            room: room,
            ids: alive.where((x) => x != me).toList(),
            selected: mine,
            extra: ('none', l.mafiaVoteNone),
            onPick: mine != null ? null : (id) => room.act({'t': 'vote', 'for': id}),
          ));
        }
      case 'out':
        final out = ViewRead.str(v['out']);
        children.add(_Banner(
          icon: out != null ? Icons.how_to_vote_rounded : Icons.balance_rounded,
          text: out != null ? l.mafiaOut(room.nameOf(out), roleName(roles[out], l)) : l.mafiaNoOut,
          color: out != null ? p.accentInk : p.textMuted,
        ));
    }

    // كل اللاعبين: عايش ولا لأ، واللي مات دوره ظاهر
    children.add(const SizedBox(height: 12));
    children.add(Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final id in order)
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PlayerAvatar(room: room, id: id, size: 46, dim: !alive.contains(id)),
                    if (roles[id] != null)
                      PositionedDirectional(
                        bottom: -6,
                        end: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, border: Border.all(color: p.border)),
                          child: Text(roleEmoji(roles[id]), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  room.nameOf(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    decoration: alive.contains(id) ? null : TextDecoration.lineThrough,
                    color: alive.contains(id) ? p.text : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    ));

    final mafiaChat = night && role == 'mafia' && iAmAlive;
    final dayChat = phase == 'talk' || phase == 'vote' || phase == 'morning' || phase == 'out';
    return Column(
      children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 8), children: children)),
        if (mafiaChat) GameChatPanel(room: room, secret: true, height: 160),
        if (dayChat && room.joined) GameChatPanel(room: room, enabled: iAmAlive, height: 160),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: p.text, fontWeight: FontWeight.w600, height: 1.5))),
        ],
      ),
    );
  }
}
