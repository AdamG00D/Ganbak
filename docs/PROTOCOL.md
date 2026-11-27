# Wasl protocol

This is the reference for everything that goes over the air. The tests in `test/` cover these rules — keep them
green, and update this file with any change.

Layers, bottom to top:

```
MeshLink      neighbour links carrying text frames      lib/mesh/{lan,nearby,dual}_link.dart
MeshRouter    presence, flooding, unicast routes        lib/mesh/mesh_router.dart
PeerLink      session ids for a direct chat             lib/mesh/peer_link.dart
SecureChannel end-to-end encrypted direct chat          lib/features/chat/core/secure_channel.dart
GroupSession  group-key encrypted broadcast             lib/features/groups/group_session.dart
GroupOps      authenticated group admin commands        lib/features/groups/group.dart
```

## 1. Identity (v2, since 1.5)

- Every profile has a random 32-byte seed. From it: a static **X25519** key pair (encryption, pair keys) and an
  **Ed25519** key pair for signatures, seeded with `HKDF(seed, "wasl/sign/v1")`.
- **Node id** = hex of the first 8 bytes of `SHA-256("wasl/id/v2" ‖ X25519 public ‖ Ed25519 public)` (16 hex chars).
  Ids from before 1.5 (hash of the X25519 key alone) are not accepted: 1.5 can't talk to older versions.
- Anything claiming an id must show both public keys that hash to it. The direct-chat handshake proves possession of
  the X25519 private key; signatures prove the Ed25519 one.
- Names are free text and may repeat; the app compares ids. The UI draws a "fingerprint" from the id (a 4×4 mirrored
  pattern, 8 bytes → colour + filled/outline per cell) and warns when someone shows the name of a known person
  (`NameMatch`: diacritics, tatweel, invisible / direction marks, alef / yeh / teh-marbuta forms and Latin look-alikes
  are folded) with another id.

## 2. Links

A link carries UTF-8 text frames between two neighbours.

| Link | Discovery | Transport | Frame limit |
|---|---|---|---|
| `LanLink` | UDP broadcast beacon `{"wasl":1,"id","port"}` every 1.5 s on port 47332 | one TCP connection per neighbour (port 47331), newline-delimited | 200 KiB |
| `NearbyLink` | Google Nearby Connections, `P2P_CLUSTER`, service id `com.adam.wasl.mesh` | BYTES payloads, auto-accept, ≤ 5 links | 30 000 chars |
| `DualLink` | both at once | link ids prefixed `w:` / `b:` | per link |

The node with the smaller id dials first; the other side tries after a delay. Connections are accepted
automatically — security is end-to-end, not at the link.

With `DualLink`, if the same node is reachable both ways the Wi-Fi link wins (`rank`) and the Bluetooth one is
dropped.

## 3. Mesh frames

```
kind|src|dst|pid|ttl|body
```

| kind | meaning | dst |
|---|---|---|
| `P` | presence (broadcast) | `*` |
| `X` | leaving (broadcast) | `*` |
| `G` | group packet (broadcast) | group id |
| `D` | direct-chat data (unicast) | node id |
| `U` | control JSON (unicast) | node id |

Link-local frames (never routed):

- `H|<id>` — hello; must arrive within 8 s of the link coming up.
- `F|<fid>|<i>|<n>|<part>` — fragment. A frame longer than the outgoing link's limit is split into `n ≤ 64` parts,
  sent in order, and reassembled by the neighbour (max 256 KiB). This is what lets a Wi-Fi-sized frame cross a
  Bluetooth hop.

Rules:

- `ttl` starts at 6 and is decremented by each relay; a frame with `ttl ≤ 1` is not forwarded.
- Dedupe by `src + pid`.
- **Broadcast**: forward once to every neighbour except the one it came from and except neighbours that are also
  neighbours of that sender (they already have it).
- **Unicast**: send on the direct link, else via the neighbour the destination's last packet arrived through, else
  flood.
- **Presence** body: `{d: "<json>", sg: Ed25519(signing key, "wasl/presence/v2|" + d)}` where `d` is
  `{n: name, c: colour, k: X25519 key, s: Ed25519 key, a?: avatar hash, e?: cartoon avatar number, g: [group ads],
  w?: Wasl network, sos?: SOS, nb: [neighbour ids], t: ms}`. Dropped unless `k`+`s` hash to `src`, the signature
  verifies, and `t` is not older than the last presence accepted from that node (`t` only grows on the sender, even if
  its clock goes back). The sender re-signs only when the content changes or every 5 minutes; receivers skip the
  signature check for a `d` they already verified. An `sos` is ignored when `t` is more than 30 minutes old (no
  replaying an SOS after it stopped). Sent every 3 s; a node silent for 11 s is gone.
- **Wasl network** (`w`, only while the node hosts one): `{s: SSID (≤ 32), p: passphrase (8–63, empty if open),
  x: security 0 open • 1 WPA2 • 2 WPA3 • 3 WPA3/WPA2}`. The node runs an Android Local-Only Hotspot (no internet);
  direct neighbours (hops = 1) are offered to join it, which moves their link to Wi-Fi (see §2). Invalid values
  drop the field, not the presence. Additive: older versions ignore it.
- **Group ad**: `{i: id, n: name, m: o|p|a, o: owner id, c?: key check, h?: admin-state digest}`.

**Route tags (1.6)** — a node that sets `pr: 1` in its presence understands tagged frames. For such a peer, `D` and
`U` frames carry, instead of ids, `src = tag(me)` and `dst = tag(peer)` where `tag(X, e)` = hex of the first 8 bytes of
`HMAC-SHA256(pairKey(me, peer, "wasl/route/v1"), "wasl/route/v1|" + X + "|" + e)` and `e` = 10-minute epoch. They look
like ids, so any relay forwards them; routes are learned for tags like for ids. A receiver precomputes tags for every
`pr` node for epochs e-1, e, e+1 and maps them back to the peer (src and dst must belong to the same peer). Peers
without `pr` (1.5) still get plain ids. Encrypted direct-chat payloads and group packets carry a `pd` filler so the
sealed size is 256, 1024 or a multiple of 4096 bytes.

**Hidden group membership (1.6)** — in secret groups every member, and in password / join-request groups a member
who isn't owner or admin, doesn't put
the group ad in `g`; it puts `gt: [{t, h}]` with `t = HMAC-SHA256(group key, "wasl/group-tag/v1|" + member id + "|" +
e)[0..8]` (different per member, rotating every 10 minutes) and `h` = the admin-state digest XOR
`HMAC-SHA256(group key, "wasl/group-digest/v1|" + t)`. Members recognise each other; outsiders see random tags. Owner and
admins keep advertising the group so newcomers can find it.

Control messages (`U`, JSON with `t`):

| `t` | purpose | authenticated by |
|---|---|---|
| `av?` / `av` | ask for / send an avatar JPEG by hash | content hash |
| `gj` | join request to a group owner (`by?`: the member who invited, shown if they're in the group) | — (owner decides) |
| `gk` | group key grant | AES-GCM with `pairKey(owner, member, "wasl/group-grant")`, aad `wasl/grant\|gid\|member` |
| `gr` | join request rejected | same pair key, aad `wasl/reject\|gid\|member` |
| `ga` | group admin command (§6) | pair key, see below |
| `gm` | game message to one player (§8) | pair key `"wasl/game"`, aad `wasl/game\|gid\|from\|to` |
| `gi` | group invite: `{g, d}` with `d` = AES-GCM(pair key `"wasl/group-invite"`, `{ad, k?, n}`, aad `wasl/group-invite\|gid\|from\|to`) — open groups: no key; password: the group key (checked against `c`); ask: from the owner the key (pre-approved; the owner adds the invitee to `members` first), from any other member no key — accepting sends `gj {g, by: inviter}` to the owner, who decides. Max 3 pending per sender, 20 in all; dropped if a nearby ad shows the same group with another owner | pair key |
| `mb` | sealed offline message, to its recipient or to a carrier (§9) | sealed to the recipient (see §9) |
| `mbd` | "delivered": drop your copy / sealed receipt for the sender / receipt received (§9) | receipt: pair key `"wasl/mailbox-receipt"` |

`pairKey(a, b, info)` = `HKDF(X25519(static a, static b), info)`. Because a node id is the hash of its static key,
a box that opens with the pair key of id *x* was made by the holder of *x*'s private key.

## 4. Direct chat (SecureChannel, protocol v1)

`PeerLink` prefixes every frame with a random session id: `sid|frame`. A hello with a new sid replaces the session;
on simultaneous dials the smaller node id's sid wins; frames with an old sid are dropped.

Handshake:

1. Each side sends `hello {v, name, pub: ephemeral X25519, id: static X25519, n: nonce}`.
2. `ikm = X25519(eph, eph) ‖ X25519(static, static)`; keys = `HKDF-SHA256(ikm, info, salt = transcript hash)` for
   `A->B`, `B->A`, `confirm-A`, `confirm-B`.
3. Each side sends an HMAC over the transcript (`confirm`). No confirm → no channel.
4. The hub also checks that the peer's static key hashes to the node id the chat is with.

Then every packet is `{"t":"e","d": base64(nonce ‖ AES-256-GCM(json) ‖ tag)}`, aad `wasl/chat/v1`, with a strictly
increasing `seq` (replays dropped). Heartbeat every 5 s; no traffic for 15 s → `lost`.

Packet kinds (`k`): `msg` (`id, text, ts, rp?, fw?`), `ack`, `typing`, `read {ids}`, `del {id}`, `edit {id, text}`,
`react {id, e, by}`, `file-start / file-chunk / file-end / file-ack / file-cancel`, `call` (WebRTC signalling),
`game` (a game message, §8), `ping`, `bye`.

- Unknown kinds are ignored, so new kinds are backwards compatible. **Changing the meaning or shape of an existing
  one requires bumping `protocolVersion`.**
- Safety code: 6 digits from a hash of both static keys — the same on both phones, stable across sessions.

File transfer: `file-start {id, mk, size, ext, name?, cs, n, ae, …}` → `file-chunk {id, i, d}` … →
`file-end {id, sha}`. The receiver acks every `ae` chunks (`file-ack {id, got, need?}`); the sender keeps at most
`window` chunks unacknowledged and resumes from `got` after a reconnect (up to 90 s).

## 5. Groups

Body of a `G` frame = `base64(AES-256-GCM(groupKey, json))`, aad `wasl/group/v1|<group id>`.

| Mode | Key |
|---|---|
| open (`o`) | `SHA-256("wasl-open-group\|" + id)` — public by design |
| password (`p`) | `Argon2id(password, salt = SHA-256("wasl-group-salt\|" + id)[0..16])` |
| join request (`a`) | random 32 bytes, handed over with `gk` |
| secret (`s`, 1.6) | random 32 bytes, handed over only inside an invite (`gi`) from the owner or an admin. Never advertised: every member, owner and admins included, announces it only as a hidden `gt` tag. Rotates on kick like `a`. |

`check` = `HKDF(key, "wasl/group/check", 8 bytes)` hex; used to validate a password or a granted key.

Inside the box: `{p: "<packet json>", sg: Ed25519(sender, "wasl/group/v2|<group id>|" + p)}`. Packet:
`{k, s: sender id, n: sender name, xk: sender X25519 key, ek: sender Ed25519 key, at: send time ms (never goes back
on the sender), …}`. An `edit` older (`at`) than the last edit applied to that message is ignored. **A packet is dropped unless
`s` equals the mesh `src`, `xk`+`ek` hash to `s`, and `sg` verifies** — so a member who has the group key still can't
post as someone else — and the sender is not in the group's removed list. `fc` (file chunks) and `typ` are not signed:
a file is checked at the end against the SHA-256 in the signed `fe`, and a fake "typing" does no harm.

| `k` | fields |
|---|---|
| `msg` | `id, text, ts, rp?, mn? {id: name}, fw?` |
| `edit` / `del` | `id` (+ `text`) — own messages only |
| `fs` / `fc` / `fe` / `fx` | file start / chunk / end (SHA-256) / cancel — broadcast in order, no acks, size-limited |
| `typ` | typing now |
| `rd` | `ids` — "I read these" |
| `rx` | `id, e, o` — reaction on message `id` whose author is `o` (`e` empty = remove) |
| `join` / `leave` | — |
| `gm` | `d` — a public game message (§8) |

## 6. Group administration (GroupOps)

Group packets are sealed with a key every member has, so they cannot carry authority. Admin commands are sent as
`U` control messages, one per recipient:

```
{"t":"ga","g": group id,"d": base64(AES-256-GCM(pairKey(sender, recipient, "wasl/group-admin"), json))}
aad = "wasl/ga|<group id>|<sender id>|<recipient id>"
```

The command JSON has `op`, a strictly increasing `n` per sender (replay protection) and `rev`.

| `op` | who | effect |
|---|---|---|
| `kick {id}` | owner; admin (not on owner/admins) | add to removed list, drop from admins/members |
| `unban {id}` | owner, admin | remove from removed list |
| `admin {id, on}` | owner only | appoint / dismiss an admin |
| `name {name}` | owner, admin | rename |
| `del {mid, sid}` | owner; admin (not on the owner's messages) | delete message `mid` of author `sid` for everyone |
| `key {key, kr}` | owner, admin | new group key (join-request groups, after a removal) |
| `state {rev, name, admins, banned, members, kr, key?}` | owner, admin | full snapshot |

- The owner can never be removed, demoted or overridden.
- Join-request groups rotate the key on `kick` and send `key` to the remaining members only.
- State converges through `digest` (`h` in the group ad): an admin who sees a member advertising a different
  digest sends `state`. From the owner, `state` with `rev ≥` mine replaces mine. From an admin, only a newer `rev`
  does (ties: plain members follow the admin; between admins the smaller id wins). The owner takes only removals
  from an admin's `state` and then bumps `rev`, so the owner's view always wins.
- A fresh member trusts only the owner until the owner's `state` tells it who the admins are.

## 7. Storage

- A random storage key encrypts every file (AES-256-GCM); the storage key is wrapped by an AES key inside Android
  Keystore.
- A conversation is written only if `saveOverride ?? AppSettings.saveChats` (default off). Media of saved chats
  lives in `vault/media/<id>/`; everything else is in temp folders wiped when the hub stops.
- Mute/pin choices for unsaved chats are dropped when the hub stops.

## 8. Games

Rules and architecture: [GAMES.md](GAMES.md). The phone that opens a game is the room **host** and runs the rules.

Transport:

- **Direct chat:** every game message is a `game` packet on the SecureChannel (the whole map, plus `k`/`seq`).
- **Group, public:** a group packet `{k: "gm", d: message}` (group key, sender must equal the mesh source).
- **Group, to one player:** a `U` control message, sealed per recipient:

```
{"t":"gm","g": group id,"d": base64(AES-256-GCM(pairKey(sender, recipient, "wasl/game"), json))}
aad = "wasl/game|<group id>|<sender id>|<recipient id>"
```

Every message has `g` (room id, 8–32 hex chars) and `y` (type). `kind` (a `GameKind` id) rides along with
`inv`, `lobby` and `view` so a phone that missed the invite can still join.

| `y` | from → to | fields |
|---|---|---|
| `inv` | host → all | `kind, hn` (host name) |
| `lobby` | host → all | `p` (players in order), `nm {id: name}` |
| `join` / `unjoin` | player → host (private) | `nm` |
| `view` | host → all | `n` (state number, increasing), `r` (match number), `p`, `nm`, `w {id: wins}`, `ac {id: last act}`, `v` (public state) |
| `pv` | host → player (private) | `n`, `v` (that player's secret: role, word, …) |
| `act` | player → host (private) | `c` (act number, increasing per player), `a` (the move; `{t: "again"}` = rematch, `{t: "msay"}` = secret chat) |
| `sync` | player → host | — (send me the state) |
| `quit` | player → host | — |
| `bye` | host → all | `why`: `end` / `cancel` |
| `rx` | anyone → all | `e` — quick reaction (one of a fixed set) |
| `say` | anyone → all | `t` — game chat (≤ 300 chars; ignored from players the state mutes) |
| `psay` | host → player (private) | `f, t` — secret chat line (mafia at night), relayed by the host |

Rules:

- A `view`, `lobby`, `pv`, `bye` or `psay` is accepted only from the room's host; `pv`/`psay` only if private.
- In groups, `join`/`unjoin`/`quit`/`sync`/`act` are accepted by the host only when private (sealed). A `view` whose
  shape is wrong for its game is dropped. A phone accepts at most one new room per sender every 8 s.
- The host re-sends `view` every 5 s; players re-send acts the host hasn't acknowledged (`ac`) every 3 s; the host
  drops an act whose `c` it has already applied. No message from the host for 25 s → the room closes.
- Hidden choices (rock-paper-scissors picks, battleship boards) are sent as `commit = hex(SHA-256("wasl/game/commit|"
  + value + "|" + salt))` and revealed later; the engine checks them and flags the cheater.
- Additive only: old versions ignore `game` / `gm` packets and unknown `kind`s. Changing the meaning of an existing
  field needs a new game id.

## 9. Offline messages (mailbox, v2 since 1.6)

Text for a person who isn't reachable waits on the sender's phone and is handed, sealed, to direct neighbours who
carry it and offer it to the neighbours they meet. **Neither the sender nor the recipient appears in the clear.**
Only people whose identity keys we already know can be written to. Code: `lib/features/mailbox/mailbox.dart`.

**Envelope** (`U {t: mb, v: 2, m, e, h, c, hp}`): `m` random id (16 hex), `e` ephemeral X25519 key, `h` header box,
`c` body box (≤ 12 KB), `hp` hand-overs so far (≤ 3).

- Sealing (one-way, like Noise X; S = sender, R = recipient):
  `k1 = HKDF(X25519(e,R), "wasl/mailbox/v2/hdr", salt e‖R)`, `h = AES-GCM(k1, {f: sender id, sk: X25519, ek: Ed25519},
  aad "wasl/mailbox/v2/hdr|m")`; `k2 = HKDF(X25519(e,R) ‖ X25519(S,R), "wasl/mailbox/v2", salt e‖S‖R)`,
  `c = AES-GCM(k2, padded {t: text ≤ 4000, ts: ms, n: name, to: recipient id}, aad "wasl/mailbox/v2|f|to|m")`.
- Only R can open `h`; the S×R part proves the sender holds S. The recipient drops an envelope whose keys don't hash to
  `f`, whose `to` isn't it, that doesn't open, or whose `ts` is missing or more than 3 days old (no replays).
- **Carrying**: a phone tries to open every envelope it's offered (≤ 60 tries per neighbour per minute, failures
  remembered); one that isn't its own is carried only if it came from a direct neighbour (hops = 1) and `hp` ≤ 3.
  Limits per phone: 300 envelopes, 30 from the same neighbour, 2 MiB, 48 h. A carrier offers each envelope once to
  every direct neighbour it meets (not back to who gave it, at most 12 offers, `hp` + 1). The sender sends straight
  to the recipient every 20 s while reachable, else hands each envelope to up to 8 neighbours.
- **Accepting**: by default only from people you know (talked to before / saved / verified / nicknamed); the setting
  "waiting messages from anyone" turns that off. Blocked senders are dropped. Rejected envelopes get no receipt.
- **Receipts** (`U {t: mbd, m, d}` recipient → sender, sent while the sender is reachable; `{m, ok: true}` back):
  `d = base64(AES-GCM(pairKey(R, S, "wasl/mailbox-receipt"), m, aad "wasl/mailbox-receipt|R|S|m"))`. Only a receipt
  that opens marks the message delivered. Control messages travel with route tags (§3), so they don't name the pair.
- The carry box lives in memory only. The sender's waiting envelopes are written to disk only for saved chats.
- 1.5 envelopes (v1, with ids in the clear) are no longer read.
