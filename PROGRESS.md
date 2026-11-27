# Wasl — progress log

Read this first when you pick the project up. It says what is done, what is in progress and what comes next, plus
the decisions already taken with the owner (don't re-open them). Keep it current: update it at the end of every step
and commit it together with the step. `AGENTS.md` has the codebase guide; this file has the plan and the state.

Owner preferences that matter for every step: reply in Egyptian Arabic, explain the plan and wait for "تمام",
one commit per step (plain message, no AI attribution), **never build the APK without the owner's explicit OK**
(ask first, even at the very end), and **check the design visually**
(see "Screenshots" below) — the owner cares a lot that nothing looks broken.

## Current release: 1.3 — games + visual identity (in progress)

| # | Step | State |
|---|------|-------|
| 1 | Screenshot tool (`tool/shots/`) + this file | done |
| 2 | Visual identity "Khayamiya" (palette, stitch line, pattern, bunting, launcher icon) — see docs/DESIGN.md | done |
| 3 | Game framework: invites, wire protocol, room host, picker sheet, game screen shell, help pages | todo |
| 4 | Two-player games: tic-tac-toe, connect four, battleship, rock-paper-scissors, dots & boxes, memory, dice/coin | todo |
| 5 | Group games: memory & dots (group), spy (مين الجاسوس), quiz, mafia | todo |
| 6 | "Wasl guide" (دليل وصل) in settings + "؟" on the transport screen | todo |
| 7 | Docs (GAMES.md, DESIGN.md, PROTOCOL.md, SECURITY, READMEs, AGENTS.md), version 1.3, release notes | todo |
| 8 | Full check: analyze, tests, screenshots of every screen reviewed, release build | todo |

## Next release: 1.4 — "Wasl network" (شبكة وصل)

The app opens a Local-Only Hotspot by itself and hands the SSID/password to nearby phones over Bluetooth; they join
with one tap (`WifiNetworkSpecifier`, Android 10+; QR / manual on 8–9). Hotspot owners keep Bluetooth on and bridge
hotspots together, so the network grows without any router. Needs real-device testing by the owner (Samsung, Xiaomi).
Also add its explanation to the in-app guide. Not started — do it after 1.3 ships.

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

## Screenshots (design check)

`flutter test tool/shots/shots_test.dart` renders real screens with the real font into `build/shots/`
(`<name>.<ar|en>.<light|dark>.png`). Use `--name <part>` to render a subset, then `python3 tool/shots/sheet.py`
puts the four variants of each screen side by side in `build/shots/sheets/`. Sample people/chats: `tool/shots/sample.dart`. Look at the PNGs after every UI change:
RTL and LTR, light and dark, long names, small phones. It is not part of `flutter test` (it lives under `tool/`).

## Log

- 2026-11-27 — plan agreed with the owner; step 1 (screenshot tool) done.
- 2026-11-27 — step 2 (identity) done: `wasl` accent (default), `accentInk` for brand-coloured text, ink/saffron/
  tentRed/teal tokens, stitch/pattern/bunting/help widgets, khayamiya transport cards, "around you now" strip on the
  chats tab, stitched empty states, new launcher icon. Next: step 3 (game framework).
