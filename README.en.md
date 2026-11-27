[العربية](README.md) | **English**

<p align="center">
  <img src="docs/images/banner.en.png" alt="Ganbak — encrypted chat with no internet and no server" width="100%">
</p>

<p align="center">
  <a href="https://github.com/AdamG00D/Ganbak/actions/workflows/ci.yml"><img src="https://github.com/AdamG00D/Ganbak/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="GPL-3.0"></a>
  <img src="https://img.shields.io/badge/Android-7%2B-3DDC84?logo=android&logoColor=white" alt="Android 7+">
  <img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter">
</p>

# Ganbak — جنبك

🌐 **Website:** [adamg00d.github.io/Ganbak](https://adamg00d.github.io/Ganbak/en/)

**Ganbak** ("connection" in Arabic) is a chat app for Android that works **with no internet and no server**. Phones
nearby talk directly over **Bluetooth** or the same **Wi-Fi / hotspot**, and relay messages for each other as a
**mesh**, so a message can reach someone well beyond your own phone's range. Private chats are end-to-end encrypted
automatically — no accounts, no phone numbers, no passwords.

Built for places where the network is down, overloaded or untrusted: festivals, stadiums, trips, campuses, power
cuts. The interface is in Arabic and English — it follows
the phone's language, and you can switch it in Settings.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/images/screenshots/en/chats.png" width="200" alt="Chats"><br><sub>Chats &amp; groups</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/group-chat.png" width="200" alt="Group chat"><br><sub>Group: reactions, replies, mentions</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/direct-chat-dark.png" width="200" alt="Private chat"><br><sub>Private chat (dark theme)</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/nearby.png" width="200" alt="Nearby"><br><sub>Nearby people &amp; groups</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/screenshots/en/games.png" width="200" alt="Games"><br><sub>Games inside chats 🎮</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/game-connect4.png" width="200" alt="Four in a row"><br><sub>Four in a row with a friend</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/game-mafia.png" width="200" alt="Mafia"><br><sub>Mafia with a group</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/guide.png" width="200" alt="Ganbak guide"><br><sub>Ganbak guide: connecting, drawn</sub></td>
  </tr>
</table>

<details>
<summary>More screenshots</summary>
<br>
<table>
  <tr>
    <td align="center"><img src="docs/images/screenshots/en/transport.png" width="200" alt="Choose Bluetooth, Wi-Fi or both"><br><sub>Bluetooth, Wi-Fi or both</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/group-info.png" width="200" alt="Group info"><br><sub>Group owner &amp; admins</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/member-sheet-dark.png" width="200" alt="Member actions"><br><sub>Tap a member</sub></td>
    <td align="center"><img src="docs/images/screenshots/en/profile.png" width="200" alt="Profile"><br><sub>Profile &amp; cartoon avatars</sub></td>
  </tr>
</table>
</details>

## Features

- **No internet, no server, no account** — a name and an avatar; your identity is a key generated on your phone.
- **Three ways to connect** — Bluetooth (no network at all), Wi-Fi / hotspot (faster, with video and calls), or
  **both at once**, which turns your phone into a bridge between a Wi-Fi network and people on Bluetooth.
- **Ganbak network** — no router? Your phone makes its own Wi-Fi network and people next to you join with one tap, no
  password typing. Networks link up over Bluetooth, so the network grows with no router at all.
- **Mesh** — messages hop through other phones (up to 6 hops); relays can't read private chats, and since 1.6 they can't
  tell who talks to whom either (rotating secret tags, fixed message sizes, hidden members in private groups).
- **Messages wait for their owner** — text for someone who isn't around is sealed for them and carried by phones
  nearby until they show up (up to 48 hours); carriers can't read it.
- **SOS** — ask everyone running Ganbak in the mesh for help with one tap.
- **Share Ganbak** — give the app to a phone that doesn't have it, with no internet: two QR codes (join my network,
  then download from my phone).
- **Private chats** — end-to-end encrypted automatically, with an optional safety code to verify each other.
- **Nobody can speak for you** — names and group messages are signed; everyone has a key fingerprint, and Ganbak warns
  you ("Not them?") when someone shows up with the name of a person you know but another key.
- **Groups** — open, password-protected, join-by-request or **secret** (invite-only, invisible), with an owner and admins
  who can remove members and delete messages, and invites with one tap.
- **Everything you'd expect from a chat app** — photos, files, voice notes, replies, edits, delete for everyone,
  emoji reactions, @mentions, forwarding, search, read receipts, "typing…", voice and video calls over Wi-Fi.
- **Games inside chats** 🎮 — tic-tac-toe, four in a row, battleships, rock paper scissors, dots and boxes and memory
  with a friend; who's the spy?, quiz and mafia with a group. Every game has a help page (the ? button), and nobody
  can cheat at rock paper scissors or battleships.
- **Ganbak guide** in the app — every way to connect explained with drawings, plus groups, games and safety.
- **Notifications** like a regular chat app, with quick reply; per-chat mute and pin.
- **Private by default** — chats are kept in memory only unless you choose to save them; saved chats are encrypted
  with a key held in Android Keystore. Optional PIN / fingerprint lock. No analytics, no ads, no network calls.

## Download

Get the APK from the [latest release](https://github.com/AdamG00D/Ganbak/releases/latest) (Android 7.0+):

| File | For |
|---|---|
| `Ganbak-<version>-arm64-v8a.apk` | **Most phones** (2017 and newer) — pick this if unsure |
| `Ganbak-<version>-armeabi-v7a.apk` | Older or low-end phones |
| `Ganbak-<version>-x86_64.apk` | Emulators and Chromebooks |
| `Ganbak-<version>-universal.apk` | Any device (larger download) |

All variants share one version code, so you can switch between them when updating. Check downloads with
`sha256sum -c SHA256SUMS.txt`.

> Ganbak is not on F-Droid: Bluetooth mode uses Google Nearby Connections, which is part of Google Play Services.

## How it works

```
 [phone A] ──Wi-Fi── [phone B] ──Bluetooth── [phone C] ──Bluetooth── [phone D]
     └──────────── end-to-end encrypted: B and C relay but can't read ────────────┘
```

Each phone announces itself to its neighbours, learns who is reachable through whom, and forwards frames it
receives. Private chats run an authenticated X25519 handshake on top and encrypt every message with AES-256-GCM.
Groups share a group key; admin commands are authenticated individually. The full protocol is in
[docs/PROTOCOL.md](docs/PROTOCOL.md), and what is and isn't protected is in [SECURITY.md](SECURITY.md).

## Build from source

Requires [Flutter](https://docs.flutter.dev/get-started/install) (stable, Dart ≥ 3.9) and JDK 17+.

```bash
flutter pub get
flutter analyze        # must report: No issues found!
flutter test           # mesh, encryption, groups, admin, storage, UI — no devices needed
flutter run            # on an Android phone (Bluetooth doesn't work in the emulator)
```

Without the release signing key the project still builds, signed with the debug key. Official releases are built
with `./scripts/build_release.sh`. To try it for real you need two phones on the same Wi-Fi (or one sharing a
hotspot), or two phones with Bluetooth next to each other.

## Project layout

| Path | What's there |
|---|---|
| `lib/mesh/` | Links (Wi-Fi, Bluetooth, both) and the mesh router |
| `lib/features/chat/core/` | Encrypted channel, chat session, file transfer |
| `lib/features/groups/` | Groups: keys, sessions, admin commands |
| `lib/features/hub/chat_hub.dart` | Ties it together: network, conversations, storage, notifications, games |
| `lib/features/games/` | Games: rooms, rules, screens, help pages ([docs/GAMES.md](docs/GAMES.md)) |
| `lib/core/` | Crypto, profile, encrypted storage, settings, theme |
| `android/…/kotlin/` | Notifications, background service, Keystore, native crypto, media compression |
| `test/` | Tests on an in-memory network (no phones needed) |
| `tool/shots/` | Screenshots for design review (Arabic/English, light/dark, large text) |

## Contributing & security

- Contributions are welcome — read [CONTRIBUTING.md](CONTRIBUTING.md).
- Found a vulnerability? **Don't open a public issue** — see [SECURITY.md](SECURITY.md).
- Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Ganbak is free software under the **GNU General Public License v3.0 or later** — see [LICENSE](LICENSE).

Copyright © 2026 Adam Ghanem and Ganbak contributors.

Additional permission under GPLv3 section 7: you may link this program with the Google Play Services libraries
(which include Nearby Connections) and distribute the result without those libraries becoming subject to this
license.

The [IBM Plex Sans Arabic](https://github.com/IBM/plex) font is licensed under the SIL Open Font License 1.1.
