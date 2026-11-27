# Wasl — progress log

Read this first when you pick the project up. It says what is done, what is in progress and what comes next, plus
the decisions already taken with the owner (don't re-open them). Keep it current: update it at the end of every step
and commit it together with the step. `AGENTS.md` has the codebase guide; this file has the plan and the state.

Owner preferences that matter for every step: reply in Egyptian Arabic, explain the plan and wait for "تمام",
one commit per step (plain message, no AI attribution), **never build the APK without the owner's explicit OK**
(ask first, even at the very end), and **check the design visually**
(see "Screenshots" below) — the owner cares a lot that nothing looks broken.

## Current release: 1.3 — games, visual identity, guide and Wasl network (one release; not built yet)

| # | Step | State |
|---|------|-------|
| 1 | Screenshot tool (`tool/shots/`) + this file | done |
| 2 | Visual identity "Khayamiya" (palette, stitch line, pattern, bunting, launcher icon) — see docs/DESIGN.md | done |
| 3 | Game framework: invites, wire protocol, room host, picker sheet, game screen shell, help pages | done |
| 4 | Two-player games: tic-tac-toe, connect four, battleship, rock-paper-scissors, dots & boxes, memory | done (dice/coin dropped for now) |
| 5 | Group games: memory & dots (group), spy (مين الجاسوس), quiz, mafia | done |
| 6 | "Wasl guide" (دليل وصل) in settings + "؟" on the transport screen | done (`lib/features/guide/`) |
| 7 | Docs (GAMES.md, DESIGN.md, PROTOCOL.md, SECURITY, READMEs, AGENTS.md), version 1.3, release notes | done |
| 8 | Full check: analyze, tests, screenshots of every screen reviewed, release build | checks done; **build waits for the owner's OK**; owner tests on real phones |

### Still open for 1.3

- **Build:** not done — ask the owner first (`./scripts/build_release.sh`).
- **Real-phone test by the owner — postponed by the owner (2026-11-27), do it before releasing** (I can't run
  Bluetooth / Wi-Fi here): a direct game over Bluetooth and over Wi-Fi,
  a group game with 3+ phones (spy or mafia), leaving mid-game, the app in background during a game, and Arabic on one
  phone / English on the other.
- README images: **done** — `flutter test tool/shots/readme_test.dart && python3 tool/shots/readme.py` renders the
  README screenshots (Arabic in `docs/images/screenshots/`, English in `screenshots/en/`) and both banners from the
  real screens, on an in-memory network of real peers (`tool/shots/sample_world.dart`, via `ChatHub.start(testLink:)`).
  The GitHub social preview (`../wasl_social_preview*.png`, outside the repo, uploaded by hand) is still the old look.
- Dice / coin in chat was dropped from this release (not asked for again).

## "Wasl network" — part of 1.3 (owner: one release, 2026-11-27)

The app opens an Android Local-Only Hotspot (no internet) and puts `w {s, p, x}` in its presence; direct Bluetooth
neighbours on "Both" get an offer banner and join with one tap (`WifiNetworkSpecifier`, Android 10+, then
`bindProcessToNetwork`); Android 8–9 get the name/password to enter in Wi-Fi settings. Hosting needs Android 8+,
"Nearby devices" (13+) or location + location on (≤ 12). `LanLink` re-reads its addresses every 3 s and reopens the
beacon socket, so it follows the new network. UI: card in the Nearby tab (wifi / both), offer banner on the home
screen (join button only on "Both"; on Bluetooth it says to pick "Both"), "Start a Wasl network" on the no-network
card, a section with a drawing in the guide.

- Code: `android/.../WaslNet.kt` (channel `wasl/net`), `lib/features/net/`, presence parsing in `mesh_router.dart`
  (`WifiOffer`), hub wiring (`_describe`, `stop()` → `WaslNetwork.shutdown()`), tests in `test/net_test.dart`.
- **Not verified on devices and the Kotlin is not compiled yet** (the owner said not to build). First build: check it
  compiles; then test: host on Android 13+ and on 9, join from 10+, join from 9 (manual), two hotspots bridged by a
  phone on "Both", hotspot closing when Wasl closes, Samsung / Xiaomi quirks (STA drop while hosting).
- Not done (ideas): automatic hosting when many people are on Bluetooth only; QR code for phones without Wasl.

## Decisions taken with the owner

**Games (1.3)** — entry point is a 🎮 button in the chat input bar; it opens a sheet with the games that fit the chat
(direct = 2 players, group = group games). An invite card lands in the chat; in groups whoever wants to play taps
"join" and the creator taps "start". Result card + rematch at the end. Every game screen and every game tile has a
help button (`؟` in Arabic, `?` in English) that opens a detailed rules page.

- Direct: tic-tac-toe, connect four, battleship (board commitment so nobody can lie), rock-paper-scissors (commit →
  reveal), dots & boxes, memory, dice / coin (commit → reveal, fair).
- Group: memory (2–6), dots & boxes (2–4), spy "مين الجاسوس" (3–12; everyone gets the word except the spy, who gets
  the category; hints in turn, vote, a caught spy may guess the word among 8), quiz (2–15, 4 options, 15 s, points
  for correct + speed, time measured on each phone), mafia (5–15; mafia/doctor/detective/citizens; night → morning
  → 3-min discussion → vote; ties = nobody out; the role of whoever is voted out is revealed).
- Mafia discussion happens **inside the game screen** (dead players can't write; mafia get a private night chat).
- Anyone in a group can start a game.
- "Room host" = whoever started the game. In games with hidden information (mafia, spy, quiz) the host's phone is the
  referee: it deals roles sealed per player with `Box.pairKey` and counts votes. The host plays normally and the UI
  never shows them other players' roles. If the host leaves, the game ends for everyone. A modified app on the host
  could cheat — acceptable for party games; documented in SECURITY.md.
- Cards (كوتشينة) are out. Draw & guess is postponed.

**Identity (1.3)** — "Khayamiya" (the Cairo tent-makers' appliqué): saffron primary, night-ink text / dark background
(not black), tent red for games and alerts, faience teal for connection and safety. Signature elements: the dashed
"stitch" line for connections, a geometric khayamiya pattern used sparingly, Ramadan bunting when someone wins.
Font (IBM Plex Sans Arabic), layout and the 24 cartoon avatars stay. Other accent colours stay as options in settings;
the default becomes "wasl". Preview the owner approved: https://claude.ai/artifact/X2pPEhPXr5vdNNTt9qV4UJ

## Where the games live

- `lib/features/games/core/` — `GameKind` (ids on the wire), `GameEngine`/`TurnEngine` (rules base, commit helper),
  `GameRoom` (one room; host runs the engine, players send `act`s; message list in its doc comment),
  `GameCenter` (rooms of one conversation + their cards in the chat, 1 s pulse, `GameTransport`).
- `lib/features/games/engines/` — rules per game + `createEngine` + `autoMoves` (automatic reveal/answer moves).
- `lib/features/games/data/` — spy words and the quiz bank (bilingual `عربي|English`; quiz: right answer first).
- `lib/features/games/ui/` — picker sheet, chat card + running banner, game screen (lobby, result bar, reactions,
  game chat, countdown), boards (`boards_classic/secret/party.dart`), help page, per-game look (`game_look.dart`).
- Wiring: `ChatHub` gives every conversation a `GameCenter` (`_DirectGames` / `_GroupGames`); private group messages
  are control frames `{t: gm}` sealed with `Box.pairKey(..., 'wasl/game')`. Strings: `tool/l10n_games.py` writes them
  into both ARB files (`python3 tool/l10n_games.py && flutter gen-l10n`).
- Tests: `test/games_test.dart` (rules + rooms on a fake net), `test/mesh_test.dart` "الألعاب فوق الشبكة".
- Boards are always laid out LTR so both players see the same board whatever their language.

## Screenshots (design check)

`flutter test tool/shots/shots_test.dart` renders real screens with the real font into `build/shots/`
(`<name>.<ar|en>.<light|dark>.png`). Use `--name <part>` to render a subset, then `python3 tool/shots/sheet.py`
puts the four variants of each screen side by side in `build/shots/sheets/`. Sample people/chats: `tool/shots/sample.dart`. Look at the PNGs after every UI change:
RTL and LTR, light and dark, long names, small phones. It is not part of `flutter test` (it lives under `tool/`). The `big` group renders key screens with text at 1.3× (like
a phone's large-font setting): any text that spills out of its box fails the run — keep it green.

## Log

- 2026-11-27 — plan agreed with the owner; step 1 (screenshot tool) done.
- 2026-11-27 — step 2 (identity) done: `wasl` accent (default), `accentInk` for brand-coloured text, ink/saffron/
  tentRed/teal tokens, stitch/pattern/bunting/help widgets, khayamiya transport cards, "around you now" strip on the
  chats tab, stitched empty states, new launcher icon.
- 2026-11-27 — steps 3–5 (games) done: 9 games, picker, cards, help pages; screenshots reviewed (fixed: mirrored
  boards in Arabic, clipped grids, bidi of "{name}'s", narrow input field). Next: step 6 (Wasl guide in settings +
  `؟` on the transport screen), then step 7 (docs, version 1.3).
- 2026-11-27 — step 6 done: the old "how Wasl works" sheet became a full guide page (connection methods with
  drawings, mesh, groups, games linking to each help page, safety). Next: step 7 (docs + version 1.3).
- 2026-11-27 — large-text pass (1.3×) added to the screenshot tool; fixed every overflow it found.
- 2026-11-27 — step 7 done: docs/GAMES.md, PROTOCOL §8, SECURITY (en/ar) games section, READMEs, CONTRIBUTING,
  AGENTS.md, version 1.3.0+4, release notes. Waiting for the owner: real-phone test + OK to build.
- 2026-11-27 — owner: postpone the phone test, don't build, tidy the repo, then start 1.4. Repo: new README
  screenshots (ar + en) and banners in the new look, games/guide rows in the READMEs, CI runs the large-text check,
  PR/bug templates mention screenshots and games. Next: 1.4 (Wasl network).
- 2026-11-27 — Wasl network implemented (see its section): Kotlin + Dart + UI + guide + docs + tests; screenshots
  reviewed; the large-text check also caught an old overflow in the Nearby list (fixed). Release notes: added to 1.3
  because 1.3 was never published — ask the owner whether to ship one release or split 1.3 / 1.4.
- 2026-11-27 — owner: ship everything as one release, 1.3 (games + identity + guide + Wasl network). Version stays
  1.3.0+4; release notes already cover all of it. Next: owner's OK to build, then the real-phone test.
