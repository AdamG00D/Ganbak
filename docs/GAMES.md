# Wasl games

Nine games played inside chats, with no server: the phone that opens a game (the **room host**) is the referee.
This page covers the rules as implemented, the architecture and how to add a game. The wire format is in
[PROTOCOL.md §8](PROTOCOL.md#8-games).

## The games

| Game | id | Where | Players | Notes |
|---|---|---|---|---|
| Tic-tac-toe | `xo` | direct | 2 | starter = ✕, alternates every match |
| Four in a row | `c4` | direct | 2 | 7 columns × 6 rows, pieces drop |
| Battleships | `bs` | direct | 2 | 8×8 sea, ships 4-3-3-2 that never touch; a hit shoots again; boards stay on their owner's phone (commitment), checked at the end |
| Rock paper scissors | `rps` | direct | 2 | first to 2 (option `bestOf: 5` → 3); commit → reveal, so nobody sees a pick early |
| Dots and boxes | `dots` | direct + group | 2–4 | 4×4 boxes for 2 players, 5×5 for more; closing a box plays again |
| Memory | `mem` | direct + group | 2–6 | 8 pairs (2 players) or 12 pairs; faces are the 24 cartoon avatars; a match plays again |
| Who's the spy? | `spy` | group | 3–12 | everyone gets the word except the spy (category only); hints in turn (two rounds with ≤ 4 players); 60 s vote; the caught player's phone proves their card; a caught spy guesses among the category's 15 words within 45 s; a tie or a wrong catch = spy wins. **Fair dealing**: roles and the word are dealt with `FairDeal` (below) — the host never knows the spy or the word |
| Quiz | `quiz` | group | 2–15 | host picks a category (or mixed) and 5 / 10 / 20 questions; 15 s each; 500 points for a right answer + up to 500 for speed, timed on the player's phone |
| Mafia | `mafia` | group | 5–15 | 1 mafia per ~4 players (1 for 5–7, 2 for 8–11, 3 for 12–15), one doctor, one detective; night 60 s → morning 8 s → discussion 3 min → vote 60 s → result 8 s; dead and voted-out roles are revealed; town wins when no mafia is left, mafia when they equal the rest |

Rules decided with the owner (don't change without asking): mafia discussion happens in the game screen (dead players
can't write, mafia get a secret chat at night); anyone in a group can start a game; ties in mafia votes eliminate
nobody; the doctor can't protect the same person two nights running.

## Architecture

```
lib/features/games/
  core/game_kind.dart     GameKind: ids on the wire, player counts, direct / group
  core/game_engine.dart   GameEngine (rules, host side) + TurnEngine + commit()
  core/game_room.dart     GameRoom: one room, same class for host and players; message list in its doc comment
  core/game_center.dart   GameCenter: the rooms of one conversation, their cards in the chat, a 1 s pulse
  engines/*.dart          the rules of every game, createEngine(), autoMoves()
  data/                   spy words, quiz bank (bilingual "عربي|English"; quiz: right answer first)
  ui/                     picker, chat card, game screen, boards, help page, per-game look
```

- **Host-authoritative.** Players send `act` messages; the host's engine validates them, then the host broadcasts
  the new public state (`view`) and each player's secret (`pv`). The UI only renders `view` + `secret` (+ `local`).
- **Secrets.** In group games every `act`, `pv` and secret chat line is sealed for one recipient with
  `Box.pairKey(me, them, 'wasl/game')`. The host's UI never shows other players' secrets, but a modified app on the
  host could read them (see SECURITY.md).
- **Fair dealing (spy, 1.6)** — `core/fair_deal.dart`, mental poker on Curve25519 (commutative scalar
  multiplication on u-coordinates, arbitrary scalars). Phases `give → mix → strip`: every player sends a column
  `[e·B, e·K₁ … e·Kₙ₋₁]` (one blank, n-1 distinct share points), the blank's hash, "boxes" `tag(K) → ω ⊕ H(K)` and its
  public key `e·G`; then each player in turn adds its layer and shuffles the rows (`mix`), then each removes its layer
  from every row but its own (`strip`). Row r belongs to `players[r]`; its owner decrypts it: all blanks = spy, else it
  opens the boxes and the word = `H(ω₁‖…‖ωₙ) mod 15`. Nobody picked the word and the host can't tell rows apart (all
  n² values differ). The caught player proves their card by revealing `e` (checked against `e·G`); at the end everyone
  reveals its secrets and `DealCheck.verify` (on the host and in every phone) checks exactly one blank row and every
  share used once; a missing / wrong reveal is flagged as cheating. The steps run automatically in `spyMoves`.
- **Role commitment (mafia, 1.6)** — the view carries `rc = commit(roles, salt)` from the first state; at the end
  `roles` + `rs` (salt) are revealed and every phone checks them against the first `rc` and its own role
  (`mafiaCheck`). The host still deals mafia roles and resolves the night (a modified host app could read them), but it
  can't change roles mid-game unnoticed.
- **Commitments.** Rock-paper-scissors picks and battleship boards stay in `room.local` on the owner's phone; only
  `commit(value, salt)` (SHA-256) is sent until the reveal. `autoMoves()` reveals and answers shots automatically,
  even when the game screen is closed. The engine marks whoever reveals something that doesn't match as `cheat`, and
  also whoever doesn't reveal within 20 s (the honest app reveals at once).
- **Hardening.** In groups the host accepts player messages (`join`, `act`, …) only sealed (a forged group packet
  can't move for someone else). Players drop malformed states (`ViewGuard`) and the screens read state through
  `ViewRead` (wrong types become empty). One new room per person every 8 s, one running room per host; reactions
  and game chat are throttled per person.
- **Reliability.** The host re-sends the state every 5 s; players re-send unacknowledged acts every 3 s (the state
  carries `ac`, the last act number seen per player); 25 s without the host closes the room for everyone.
- **Cards.** Each room has a card in the conversation (`ChatMessage.game`), saved with the chat if the chat is saved.
  It shows the invite, the lobby, "open game" and finally the wins.
- **Timers** run on the host (`engine.tick`); `view.left` is the remaining time in ms when the state was sent, and
  every phone counts down from when it received it.

## Adding a game

1. Add a value to `GameKind` (new short `id`, player counts, direct / group).
2. Write the rules in `engines/` (extend `TurnEngine` for turn-based games), add it to `createEngine`.
3. Add a board in `ui/`, wire it in `GameScreen._body`, add colour / icon / texts in `game_look.dart` and
   `GameColors`.
4. Add the name, tagline and help texts to `tool/l10n_games.py`, run it and `flutter gen-l10n`.
5. Tests in `test/games_test.dart` (rules + a room on the fake net), screenshots in `tool/shots/` (normal and big).

Old app versions ignore unknown `kind`s, so adding a game is backwards compatible.
