**English** | [العربية](SECURITY.ar.md)

# Security

## Reporting a vulnerability

**Please don't open a public issue.** Use GitHub's private reporting: the repository's **Security** tab →
**Report a vulnerability**. Include what the problem is, how to reproduce it and its impact. We'll reply as soon as
we can and, if you like, credit you in the release notes.

## What Ganbak protects against

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

1. **Names are not unique.** Since 1.5 a name, avatar and everything else someone announces is signed with their key,
   so nobody can change it on the way. But anyone can *choose* any name — there is no server to reserve names. Ganbak
   compares keys, not names: it shows a small fingerprint next to two people with the same name and warns ("Not
   them?") when someone shows the name of a person you talked to before with another key. The sure way is still to
   **compare safety codes** face to face.
2. **Group members can't post as each other** (since 1.5): every group message is signed by its sender, so having the
   group key isn't enough to speak for someone else. File chunks and "typing…" aren't signed (the whole file is
   checked against a signed fingerprint at the end). A member can still re-send an old message that someone really
   wrote (it shows with its original time to whoever didn't have it); an old edit can't undo a newer one.
3. **Open groups are not secret.** Their key is derived from the group id, so anyone nearby can read them. That is
   what "open" means.
4. **Removing a member** re-keys **join-request** groups (a real removal). In **password** and **open** groups the
   removed person can still decrypt messages with a modified client; normal apps ignore their messages and remove them.
5. **No forward secrecy in groups.** Anyone who has the group key can decrypt any recorded message sent with it.
6. **Some metadata is still visible nearby.** Who is present (name, picture) is public — that's how people find each
   other. Since 1.6 private chats and control messages travel with rotating secret tags instead of ids, sizes are
   padded, members of private groups are hidden (only owner and admins advertise a group), and offline messages carry
   no sender or recipient — so relays can't tell **who talks to whom**. What remains: the phone right next to you sees
   that *your* phone sent something (not to whom), and timing; phones on 1.5 still use plain ids. Ganbak is not a full
   anonymity tool.
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
- **Who's the spy can't be cheated, not even by the host** (1.6): all phones deal the roles and the word together
  (mental poker on Curve25519), so nobody — the host included — knows who the spy is or picked the word; the caught
  player proves their card, and at the end every phone reveals its secrets and checks the whole deal.
- **In Mafia and Quiz the host's phone knows the secrets** (roles, everyone's answers) to run the game. The app never
  shows them to the host and they travel sealed per player. In Mafia the roles are also committed (a sealed
  fingerprint) at the start and checked by every phone at the end, so a host can't **change** roles mid-game unnoticed
  — but a host running a **modified** app could still peek. These are party games: don't play them with someone you
  wouldn't trust to deal the cards.
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

## Ganbak network (hotspot)

When you start a **Ganbak network**, your phone opens an Android Local-Only Hotspot (no internet) and puts its name
and password in the presence it broadcasts, so phones nearby can join it with one tap. That means **anyone in the
mesh running Ganbak can see that password and join that Wi-Fi network**. It only gives them a local link — the same
thing Bluetooth already gives them: private chats stay end-to-end encrypted and groups stay as described above. Turn
the network off when you don't need it; it also closes when Ganbak closes.

Joining one is always your choice (a tap, then Android's own prompt showing the network name). A nearby device could
advertise a network of its own; joining it only moves Ganbak's local traffic there — private chats stay end-to-end
encrypted — and the offer is shown only for phones directly next to you.

## Secret groups

A **secret** group (1.6) is never advertised: nobody nearby sees its name, and its members — owner and admins
included — announce it only as secret tags that change every 10 minutes. The only way in is an invite from the owner
or an admin, which carries the group key sealed for the invitee. Like any group, a member with a modified app could
still leak the key; removing someone changes the key.

## Messages that wait (offline messages)

Text you write to someone who isn't around is sealed for that person alone and carried by phones near you for up to
48 hours. Since 1.6 the envelope shows **neither who wrote it nor who it's for** — carriers see a random id and a
padded size, and pass it to the neighbours they meet; only the recipient can tell it's theirs. By default you only
accept such messages from people you've talked to before (Settings → Privacy). Delivery isn't guaranteed: carriers
may drop messages, run out of room or never meet the recipient. "Delivered" appears only when a receipt sealed by the
recipient comes back. Only text, and only to people whose key your phone already knows.

## Sharing the app ("Share Ganbak")

Settings → Share Ganbak runs a tiny web server inside the app **only while that screen is open**. It answers two paths
(`/` — the download page, and `/wasl.apk` — the installed copy of the app) on the local network and nothing else;
at most 4 downloads at a time. The page is plain HTTP (there's no internet to get a certificate), so someone on the
same Wi-Fi could in theory tamper with the download: the page and the sender's screen show the file's SHA-256
fingerprint to compare, and Android refuses to install a modified copy over a genuine Ganbak (different signature).

## Cryptography

X25519 • HKDF-SHA256 • HMAC-SHA256 • AES-256-GCM • Argon2id (19 MiB, 2 passes) • SHA-256 — from the
[`cryptography`](https://pub.dev/packages/cryptography) package, with Android's own AES-GCM for large payloads. Details
in [docs/PROTOCOL.md](docs/PROTOCOL.md).
