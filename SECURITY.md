**English** | [العربية](SECURITY.ar.md)

# Security

## Reporting a vulnerability

**Please don't open a public issue.** Use GitHub's private reporting: the repository's **Security** tab →
**Report a vulnerability**. Include what the problem is, how to reproduce it and its impact. We'll reply as soon as
we can and, if you like, credit you in the release notes.

## What Wasl protects against

| Threat | Protection |
|---|---|
| Someone listening on Bluetooth / Wi-Fi | Private chats use AES-256-GCM with X25519 keys generated per connection |
| Phones relaying in the mesh | They forward frames only; they can't read or alter private chats |
| Impersonating someone's id | A node id is the hash of its identity key, and the handshake proves possession of the private key |
| An identity key stolen later | Ephemeral keys per connection: past messages can't be decrypted (forward secrecy) |
| Replaying an old message | Strictly increasing counters in every message, and in group admin commands |
| A lost phone (locked) | Saved chats are AES-256-GCM encrypted with a key wrapped by Android Keystore; saving is opt-in and off by default |
| Forging an admin command in a group | Admin commands are sealed per member with a key shared between sender and recipient identities |
| Backups | Disabled (`allowBackup=false` and data-extraction rules) |

## Known limitations — please read

These are known and documented so nobody relies on something that isn't there:

1. **Names and avatars are not authenticated.** Presence proves that an id is the hash of the advertised key, but
   the name, avatar and group list are not signed. A malicious device in the mesh can show a wrong name for someone
   else's id. Private chats themselves are unaffected (keys are bound to the id) — when it matters,
   **compare safety codes**.
2. **Inside a group, members are not authenticated to each other.** Group messages are encrypted with one key shared
   by all members. The app rejects a message whose claimed sender differs from its mesh source, but a member with a
   modified client can forge the source too — so a malicious member can post as another member. (Admin commands are
   not affected; they are authenticated.)
3. **Open groups are not secret.** Their key is derived from the group id, so anyone nearby can read them. That is
   what "open" means.
4. **Removing a member** re-keys **join-request** groups (a real removal). In **password** and **open** groups the
   removed person can still decrypt messages with a modified client; normal apps ignore their messages and remove them.
5. **No forward secrecy in groups.** Anyone who has the group key can decrypt any recorded message sent with it.
6. **Metadata is visible to devices nearby**: who is present (id and name), who is in which group, who talks to whom,
   and the size and timing of frames — not the content. Wasl is not an anonymity tool.
7. **Notifications** show the sender and text unless the app lock is enabled. The phone's lock screen only ever
   shows "new message". Enable the app lock if you don't want content in notifications.
8. **An unlocked or compromised phone.** If someone has your phone unlocked, or it runs malware with high privileges,
   no app can protect you.
9. **Flooding (DoS).** A nearby device can flood the mesh or drop links. Sizes and counts are bounded, but there is
   no complete protection.
10. **No external audit yet.** The code is open so anyone can review it.

## Games

Games have no server, so the phone that opens a game (the **room host**) is the referee:

- **Rock paper scissors and Battleships can't be cheated, not even by the host.** Each pick and each fleet is sent as a commitment
  (SHA-256 with a random salt) and revealed afterwards; the app checks the reveal and every "hit / miss" answer and
  names whoever lied.
- **In Mafia, Who's the spy and Quiz the host's phone knows the secrets** (roles, the word, everyone's answers) to run the game. The
  app never shows them to the host, and they travel sealed per player, so other phones relaying the mesh can't
  read them. A host running a **modified** app could peek or cheat, though. These are party games: don't play them
  with someone you wouldn't trust to deal the cards.
- **Memory:** the card layout comes from the host, so a modified host could know it.
- Game chat and reactions in groups are encrypted with the group key, like group messages (limitation 2 applies).
- **Public game state in groups can be forged by a malicious member.** The host broadcasts the board/state with the
  group key, and (limitation 2) a member with a modified app can fake the host as the source. Players' own moves,
  votes and answers can't be forged: they travel sealed to the host. The app ignores malformed states.
- **Quiz speed is measured on each player's phone**, so a modified app could claim to be faster.
- **Refusing to reveal is cheating too:** in Battleships and Rock paper scissors whoever doesn't reveal within 20 s
  of the end (or of the other player's reveal) loses.
- Invites are rate-limited (one new room per person every 8 s, one running room per host) and reactions / game chat
  are throttled, so nobody can flood a chat with games.

## Wasl network (hotspot)

When you start a **Wasl network**, your phone opens an Android Local-Only Hotspot (no internet) and puts its name
and password in the presence it broadcasts, so phones nearby can join it with one tap. That means **anyone in the
mesh running Wasl can see that password and join that Wi-Fi network**. It only gives them a local link — the same
thing Bluetooth already gives them: private chats stay end-to-end encrypted and groups stay as described above. Turn
the network off when you don't need it; it also closes when Wasl closes.

Joining one is always your choice (a tap, then Android's own prompt showing the network name). A nearby device could
advertise a network of its own; joining it only moves Wasl's local traffic there — private chats stay end-to-end
encrypted — and the offer is shown only for phones directly next to you.

## Cryptography

X25519 • HKDF-SHA256 • HMAC-SHA256 • AES-256-GCM • Argon2id (19 MiB, 2 passes) • SHA-256 — from the
[`cryptography`](https://pub.dev/packages/cryptography) package, with Android's own AES-GCM for large payloads. Details
in [docs/PROTOCOL.md](docs/PROTOCOL.md).
