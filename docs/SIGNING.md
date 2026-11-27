# Design: signed names and authenticated group messages

**Status: implemented in 1.5 with option (a), a new id format (owner's choice, 2026-11-27).** The wire format is in
PROTOCOL.md §1, §3 and §5; this page keeps the reasoning. It addresses SECURITY.md limitations
1 (names and avatars aren't authenticated) and 2 (group members can post as each other).

## Problem

- Presence proves that the id hashes from the advertised X25519 key, but nothing proves that the **name, avatar,
  cartoon and group list** in it come from the key's owner — any relay could change them.
- In a group everyone shares one AES key. A member with a modified app can put another member's id in `s` and fake
  the mesh `src`, so the message looks like it came from someone else.

## Idea

Give every profile a second static key, **Ed25519 for signatures**, bound to the existing identity:

- The signing key must be bound to the id, otherwise a relay could swap it. X25519 keys can't sign, so either:
  - **(a) new id format (v2)**: `id = SHA-256(x25519Pub ‖ ed25519Pub)[0..8]`, presence carries both keys (`k`, `sk`);
    swapping `sk` changes the id. Old v1 ids keep working, shown as today (unsigned); or
  - **(b) XEdDSA**: sign with the existing X25519 key (the Signal construction) — ids stay the same, but it needs a
    careful implementation (no ready-made Dart package we trust today).
- **Presence**: `sig = Ed25519(sigKey, canonical(n, c, a, e, g, w, sos, t))` with a timestamp `t`; receivers verify and
  drop a presence whose signature fails *if* the id is a v2 id. Names from v2 ids are "signed".
- **Group packets**: the inner JSON gets `sg = Ed25519(sigKey, "wasl/group-msg/v1|" + gid + "|" + canonical(packet))`.
  A receiver that knows the sender's `sk` (from presence) rejects packets with a missing or wrong `sg` from v2 senders.
  Cost: 64 bytes + one signature per message; verification is fast.
- **Chat UI**: nothing changes for honest users; a "not verified" hint appears only for old (v1) senders in groups.

## Compatibility

- Additive fields (`sk`, `sig`, `sg`) — old versions ignore them.
- With (a), a v2 id is a **new identity** for everyone who knew the v1 id (saved chats, group roles, blocked lists):
  existing profiles keep v1 until the user chooses to upgrade, new profiles get v2. With (b) nothing migrates.

## Open questions for the owner

1. Accept that upgrading changes your id (saved chats and group roles must migrate), or implement XEdDSA to sign with
   the existing X25519 key and keep ids?
2. Reject unsigned group messages from v2 senders only, or warn only?
3. Do this before or after an external audit (docs/AUDIT.md)?
