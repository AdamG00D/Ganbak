# Ganbak (جنبك) — guide for AI coding agents

Ganbak is an offline chat app for Android (Flutter, Arabic + English UI, RTL / LTR): people nearby talk over **Bluetooth** (Google
Nearby Connections) or **Wi-Fi / hotspot** (UDP discovery + TCP) — or both at once, which turns the phone into a
bridge between the two — with no internet and no server. Devices form a **mesh** (messages hop through other
phones), private chats are end-to-end encrypted automatically (no passwords), and there are groups (open /
password / join-request) with an owner and admins. Package `com.adam.ganbak`. Open source, **GPL-3.0-or-later**
(`LICENSE`); human-facing docs come in English + Arabic pairs, keep both in sync: `README.md` is **Arabic** (the
main one) with `README.en.md`; `CONTRIBUTING`, `SECURITY` (threat model + known limits) and `CODE_OF_CONDUCT`
(Contributor Covenant 2.1) are English `X.md` with Arabic `X.ar.md`.
`docs/PROTOCOL.md` (wire protocol, English only — keep it in sync with the code), `docs/GAMES.md` (games: rules,
architecture, how to add one), `docs/DESIGN.md` (the "Khayamiya" look). **`PROGRESS.md` (repo root) is the work log:
read it first, keep it current, and don't re-open the decisions recorded there.** README images live in
`docs/images/` (banners `banner.en.png` / `banner.ar.png`, screenshots in `screenshots/`). It started from the chat part of the
owner's older app ILN (`~/Downloads/ILN_App/iln_flutter`) — chat session, file transfer, voice, calls and the Kotlin
helpers come from there.

## Working with the owner

- The owner writes in **Egyptian Arabic**. Reply in Egyptian Arabic.
- **Explain the plan first and wait for approval** before implementing anything non-trivial.
- **Don't build the APK after each step — and never build without the owner's explicit OK.** Finish every change, run
  `flutter analyze` + `flutter test` + the screenshot tool, then ask before building.
- **One commit per step**, and update `PROGRESS.md` in the same commit.
- **Security review after every new feature** (owner's standing rule): hostile input, replay, spoofed sources,
  unbounded lists / memory, what nearby devices learn, logging. Fix, add tests, note accepted limits in SECURITY (en/ar).
- **Check the design visually** after every UI change (screenshot tool above): RTL and LTR, light and dark, large text.
- **Never add AI attribution** (`Co-Authored-By`, "Generated with…") to commits or anything else.
- When a request is ambiguous, ask instead of guessing.

## Commands

```bash
flutter analyze          # must say "No issues found!"
flutter test             # mesh_test (routing, private chat, groups, group admin, storage, games over the mesh),
                         # games_test (rules + rooms), bridge_test, ui_test
flutter test tool/shots/shots_test.dart && python3 tool/shots/sheet.py
                         # screenshots of real screens → build/shots (ar/en × light/dark + 1.3× text) — look at them
python3 tool/l10n_games.py && flutter gen-l10n   # game + guide strings (both ARB files)
python3 tool/generate_icon.py   # regenerate launcher icon (needs Pillow)
python3 tool/site.py            # rebuild the website in site/ (GitHub Pages, published by .github/workflows/pages.yml)
./scripts/build_release.sh      # signed + obfuscated → Releases/<ver>v/ (uses JDK 21 from ~/Downloads/Files/toolchains)
                                # ONLY after the owner explicitly says to build
```

New version: bump `version` in `pubspec.yaml` **and** `appVersion` in `lib/core/config.dart`, and write
`release_notes/<X.Y>v.txt` (Arabic) + `release_notes/<X.Y>v.en.md` (English, with the download table). The build
script refuses to run without both. It builds arm64-v8a / armeabi-v7a / x86_64 / universal APKs with one shared
versionCode, `SHA256SUMS.txt` and `github_release.md`, and prints the `gh release create` command.

Folder layout on disk: `Wasl/Wasl_App/` (this repo; the folder names kept the old name) and `Wasl/Signing_Key/` (keystore + passwords — outside the repo
on purpose, never commit or print them). Without the key Gradle signs with the debug key (so contributors and CI can
build); only `build_release.sh` insists on it.

## Layout

```
lib/
  main.dart                 start: lock gate → profile editor (first run) → TransportScreen
  l10n/                     app_ar.arb (template) + app_en.arb → generated AppLocalizations; l10n.dart (context.l10n,
                            tr, L10n.resolve / pick)
  core/
    config.dart             ports, service id, version, repo URL
    nav.dart                rootNavigatorKey
    crypto/                 kdf.dart (Argon2id/HKDF/SHA-256), box.dart (AES-GCM box, native for big payloads, pairKey),
                            sign.dart (Ed25519)
    profile/profile.dart    Profile (name, color, avatar hash, static X25519 identity; id = sha256(pub)[0..8]),
                            ProfileStore, Avatars (small JPEGs stored by hash)
    settings/app_settings.dart   theme, accent, language, saveChats (default false), PIN lock
    storage/vault.dart      master key wrapped by Android Keystore; encrypted JSON files
    storage/chat_store.dart saved chats index + messages + joined groups + blocked ids + per-chat prefs (pin / mute)
    platform/               system_bridge.dart (channel wasl/system), secure_clipboard.dart
    theme/app_theme.dart    Palette tokens (context.palette: accent / accentInk / ink / saffron / tentRed / teal…),
                            AccentTheme presets ('wasl' = default), avatarColors, GameColors
  mesh/
    mesh_link.dart          MeshLink: neighbour links carrying string frames
    lan_link.dart           Wi-Fi: UDP beacons + one TCP connection per neighbour (smaller id dials)
    nearby_link.dart        Bluetooth: Nearby P2P_CLUSTER, auto-accept, ≤ 5 links
    dual_link.dart          both at once (link ids `w:` / `b:`); Wi-Fi outranks Bluetooth for the same peer
    mesh_router.dart        presence, flooding with dedupe + neighbour suppression, learned unicast routes,
                            link-level fragmentation of oversized frames; GroupMode / GroupAd / MeshNode
    peer_link.dart          binds a ChatSession to a peer over the mesh (session ids, simultaneous-dial tie-break)
  features/
    hub/chat_hub.dart       ChatHub singleton: link + router + DirectChat/GroupChat objects, persistence,
                            notifications (open / reply / mark read), mute + pin, calls, join requests, avatars,
                            group administration (kick / admins / rename / moderator delete / state sync)
    chat/
      chat_page.dart        the conversation screen (direct + group)
      core/                 secure_channel.dart, chat_session.dart (messages + file transfer), frame_transport.dart,
                            chat_link.dart (session + supportsVideo for the input widgets), chat_errors, nearby_requirements
      call/, voice/, widgets/   WebRTC calls, voice notes, bubbles / input bar / media (from ILN)
    games/                  core/ (GameKind, GameEngine, GameRoom, GameCenter), engines/ (rules of the 9 games,
                            createEngine, autoMoves), data/ (spy words, quiz bank), ui/ (picker, chat card, game
                            screen, boards, help page) — see docs/GAMES.md
    net/                    "Ganbak network": wasl_network.dart (WaslNetwork: host a Local-Only Hotspot / join one;
                            the offer rides in presence as `w`), wasl_net_ui.dart (card in Nearby, offer banner)
    mailbox/mailbox.dart    offline messages: sealed envelopes, carry box, MailService (PROTOCOL §9)
    sos/sos_ui.dart         SOS banner / card / sheet (signal rides in presence)
    share/                  "Share Ganbak": share_server.dart (local HTTP: page + installed APK, only while the screen
                            is open), share_page.dart (the download page), share_screen.dart (two QR codes)
    guide/guide_screen.dart "Ganbak guide" (settings + ؟ on the transport screen): connecting with drawings, groups,
                            games, safety
    groups/                 group.dart (GroupInfo: keys, roles, admin state + GroupOps: sealed admin commands),
                            group_session.dart (GroupSession extends ChatSession),
                            group_ui.dart (create sheet, join flow, info screen, member sheet)
    home/                   transport_screen.dart (Bluetooth / Wi-Fi / both), home_screen.dart (swipeable pages:
                            chats incl. joined groups • groups • nearby people + groups)
    onboarding/profile_editor.dart, settings/settings_screen.dart, lock/app_lock.dart
  widgets/                  identity.dart (stitch line/border, khayamiya pattern, bunting + celebrate(), HelpButton),
                            ui.dart (Avatar, AppCard, buttons, EmptyState…), feedback.dart (showToast, dialogs,
                            showActionSheet), focus_guard.dart,
                            cartoon_avatar.dart (24 avatars painted in code), avatar_render.dart (avatar → PNG for notifications)
android/app/src/main/kotlin/com/adam/ganbak/
  MainActivity.kt    channels: wasl/system (bluetooth/wifi/notify/service/files/language/openUrl) + wasl/vault
                     (keystore wrap, biometric)
  AppLanguage.kt     language of native strings (follows the app's choice, not the phone's)
  KeyVault.kt        Keystore AES key + BiometricGate
  ChatService.kt     foreground service + Notifications (MessagingStyle per chat, reply / mark-read receiver);
                     onTaskRemoved kills the process
  WaslNet.kt         wasl/net: Local-Only Hotspot (host) + WifiNetworkSpecifier join + bindProcessToNetwork
  ChatFiles.kt, NativeCrypto.kt (wasl/crypto), VoiceRecorder.kt (wasl/voice), VideoCompressor.kt (wasl/video), ImageCompressor.kt
```

## Conventions

- **UI text is localized**: every user-visible string goes in **both** `lib/l10n/app_ar.arb` (template, Egyptian
  Arabic, short and friendly) and `lib/l10n/app_en.arb`. Use `context.l10n.key` in widgets (rebuilds on language
  change) and `tr.key` (from `lib/l10n/l10n.dart`) where there's no context — hub, sessions, system messages, errors.
  `flutter gen-l10n` (or `pub get`) regenerates `app_localizations*.dart`. Native text (notifications, biometric) is in
  `res/values/strings.xml` (English) + `res/values-ar/`, picked through `AppLanguage` with the language Flutter sends.
- Language: `AppSettings.language` = null (follow the phone: Arabic if the phone is Arabic, otherwise English) / 'ar' /
  'en'. Code comments stay in Egyptian Arabic.
- Layout flips RTL (Arabic) / LTR (English) — always `EdgeInsetsDirectional` / `AlignmentDirectional` /
  `PositionedDirectional`, never fixed left / right.
- Colors only through `context.palette`; no hard-coded theme colors in screens. Brand-coloured **text/icons use
  `accentInk`**, filled things use `accent` (saffron text on white is unreadable). Identity elements (stitch, pattern,
  bunting) are used sparingly — see docs/DESIGN.md. Font: IBM Plex Sans Arabic (`Plex`), weights 400–700 only.
- Game boards are always laid out LTR (both players must see the same board whatever their language).
- Messages to the user: `showToast(context, ...)` (never `SnackBar`). Dialogs: `confirmDialog` / `infoDialog`.
  Bottom-sheet menus: `showActionSheet` (scrolls when the options don't fit — never a bare `Column` in
  `showModalBottomSheet`).
- Closing the keyboard: **always `hideKeyboard()`**, never `FocusScope.of(context).unfocus()`.
- Never log message contents.
- Notifications show sender + text **only when the app lock is off**; with the lock on use the generic
  `SystemBridge.notify`. The phone's lock screen always gets the generic public version. Muted chats don't notify,
  except when the user is mentioned.
- Line width 120. Don't run a formatter over files you aren't otherwise changing.
- Treat everything from the network as hostile: bound lengths and counts, validate ids with `MeshRouter.isId`, and
  never trust a claimed sender without proof (see `SECURITY.md` for what is and isn't authenticated).

## Protocol invariants (covered by tests — keep them green)

- **Mesh frame**: `kind|src|dst|pid|ttl|body`. Kinds: `P` presence, `X` leaving, `G` group broadcast (dst = group id),
  `D` private-chat data, `U` control JSON, `H|id` neighbour hello (never routed). Max 6 hops. Dedupe by `src+pid`.
  A relay doesn't forward a broadcast to neighbours that are also neighbours of whoever handed it the packet.
  Unicast follows the neighbour the destination's last packet came through, else floods.
- **Fragments**: a frame longer than `link.frameLimit(linkId)` goes out as `F|fid|i|n|part` (≤ 64 parts, in order,
  never routed) and is reassembled by the neighbour (≤ 256 KiB). Duplicate links to one node: higher `link.rank` wins.
- **Identity (v2, 1.5)**: X25519 + Ed25519 keys from one seed; node id = first 8 bytes of
  SHA-256("wasl/id/v2" ‖ X25519 ‖ Ed25519), hex. Presence is signed (`{d, sg}`, `t` never goes back) and dropped if the
  keys don't hash to the id or the signature fails. Group packets carry `xk`/`ek` + an Ed25519 signature (`fc`/`typ`
  excepted). Names may repeat — compare ids; the UI shows a fingerprint (`widgets/fingerprint.dart`), a "Not them?"
  warning (`ChatHub.impostorOf`, `core/profile/names.dart`) and nicknames (`ChatPrefs.nickname`).
- **Private chat** (`secure_channel.dart`, protocol v1): hello carries an ephemeral key + the static identity key;
  keys = HKDF(ee ‖ ss). Both sides confirm with HMAC. AES-256-GCM with sequence numbers, heartbeat 5 s / lost after
  15 s. **Changing the wire format requires bumping `protocolVersion`.**
- **PeerLink**: every frame is `sid|frame`; a hello with a new sid replaces the session; simultaneous dials → the
  smaller node id's sid wins. If the first frame can't leave the device the session reports `'lost'` at once.
- **File transfer** (direct): `file-start` → `file-chunk`s → `file-end` (SHA-256), receiver acks every `ackEvery`,
  sender keeps ≤ `window` chunks in flight, resumes after reconnect. Groups: `fs`/`fc`/`fe` broadcast in order, no acks,
  size-limited (`MeshLink.groupFileLimit`).
- **Groups**: body = base64(AES-GCM(groupKey, json), aad `wasl/group/v1|<id>`). open key = SHA-256 of the id (public by
  design); password key = Argon2id(password, salt from id); ask key = random, handed over sealed with
  `Box.pairKey(owner, member)`. `check` = HKDF of the key, used to validate passwords/grants. A packet whose `s`
  differs from the mesh source, or whose sender was removed, is dropped. Extra kinds: `typ`, `rd`, `rx`.
- **Group admin** (`GroupOps`): commands never travel as group packets — each is sealed per recipient with
  `Box.pairKey(sender, recipient, 'wasl/group-admin')`, carries an increasing `n` and `rev`, and is applied by
  `GroupInfo.apply`. Owner: everything, and nobody can act on the owner. Admins: kick non-admins, unban, rename,
  delete others' messages. Ask-mode groups rotate the key on kick. State converges via the ad `digest`; the owner's
  state always wins.
- **Additive changes only**: new packet kinds / fields that old versions ignore are fine (`react`, `fw`, `mn`, `h`,
  `e`). Anything else on the direct channel needs a `protocolVersion` bump.
- **Games** (`docs/PROTOCOL.md` §8): direct = `game` packets on the SecureChannel; group = `gm` group packets (public)
  + `U {t: gm}` sealed per recipient with `Box.pairKey(..., 'wasl/game')` (acts, secrets, secret chat). The host runs
  the engine; `view`/`pv`/`bye`/`psay` only from the host; acts are numbered and re-sent until acknowledged (`ac`);
  25 s of host silence closes the room. RPS picks and battleship boards are commitments, revealed later.
- **Privacy (1.6)**: nodes with `pr: 1` get `D`/`U` frames addressed by rotating route tags (`mesh/route_tags.dart`,
  10-min epochs, per-pair key `wasl/route/v1`) instead of ids; payloads padded (`SizePad`); private-group members
  announce `gt` tags (`groups/group_tags.dart`), only owner/admins advertise the ad; offline-message envelopes (v2) have
  no sender/recipient in clear; group invites `U {t: gi}` sealed per recipient. Keep tests in `privacy_test.dart` green.
- **Ganbak network**: presence `w {s, p, x}` only while hosting; offered to direct neighbours only; `LanLink` re-reads
  its addresses every 3 s and reopens the beacon socket when they change (needed after hosting / joining).
- **Saving**: default off. A conversation is written to disk only if `saveOverride ?? AppSettings.saveChats`; media of
  saved chats moves to `vault/media/<id>/`. Unsaved chats live in memory until the hub stops.

## Don't touch / never commit

- `../Signing_Key/` (keystore + passwords).
- Generated: `res/drawable-*/ic_launcher_*`, `res/mipmap-*/ic_launcher.png` (from `tool/generate_icon.py`).
