# Brief for an external security audit

Wasl is an offline mesh chat for Android (Flutter + Kotlin): no server, no accounts. This page tells an auditor what
to look at first. Threat model and known limits: [SECURITY.md](../SECURITY.md). Wire format: [PROTOCOL.md](PROTOCOL.md).

## Scope, by priority

1. **Direct-chat handshake and channel** — `lib/features/chat/core/secure_channel.dart`. X25519 static + ephemeral,
   HKDF(ee ‖ ss), HMAC key confirmation, AES-256-GCM with sequence numbers. Questions: key-compromise impersonation,
   replay / reordering, downgrade between protocol versions, nonce reuse across reconnects (`peer_link.dart` session
   ids and the simultaneous-dial tie-break).
2. **Identity binding** — node id = SHA-256(static key)[0..8] (`core/profile/profile.dart`, presence handling in
   `mesh/mesh_router.dart`). Is 64 bits enough against targeted second-preimage / collision attempts in this setting?
3. **Offline messages** — `lib/features/mailbox/mailbox.dart`: one-way sealing (ephemeral-static + static-static,
   Noise-X-like), receipts, carrier limits. Questions: sender authentication, replay after the 3-day seen window,
   metadata exposure, resource exhaustion of carriers.
4. **Groups and administration** — `features/groups/group.dart` (`GroupInfo.apply`, `GroupOps`), `group_session.dart`.
   Sealed per-recipient admin commands with counters and revisions; state convergence via digest. Questions: rollback
   of admin state, an admin escalating to owner, kicked members keeping access (documented for open / password groups).
5. **Parsing hostile input** — every frame from the network: mesh frames and fragments (`mesh_router.dart`), group
   packets, file transfer (`chat_session.dart`, path handling, size limits), game messages (`features/games/core/`,
   `ViewGuard`), Wasl network offers (`WifiOffer.fromWire`), SOS. Look for unbounded allocations, crashes, path
   traversal.
6. **Storage** — `core/storage/vault.dart` (master key wrapped by Android Keystore), `chat_store.dart`, the app lock
   (`features/lock/app_lock.dart`, `KeyVault.kt` biometric gate), media files and temp cleanup.
7. **Android side** — `android/app/src/main/kotlin/com/adam/wasl/`: exported components, notification reply
   receiver, `WaslNet.kt` (hotspot / `bindProcessToNetwork`), file sharing (`ChatFiles.kt`).

Out of scope: the documented limitations in SECURITY.md (unsigned names, group members not authenticated to each
other, open groups readable by design, metadata visible nearby) — unless the auditor finds them worse than described.

## How to run it

```bash
flutter pub get
flutter analyze && flutter test       # mesh, groups, games, mailbox, bridge, UI — all in-memory, no devices needed
./scripts/build_release.sh            # owner only (signing key); a debug build: flutter build apk --debug
```

The tests in `test/mesh_test.dart` and `test/mailbox_net_test.dart` run whole networks of phones in memory
(`test/support.dart`), which is the easiest way to try attacks without devices.

## Practical notes

- Crypto comes from the `cryptography` package (Dart) plus Android's AES-GCM for large payloads
  (`NativeCrypto.kt`). Argon2id: 19 MiB, 2 passes.
- Findings: private advisory on GitHub (Security → Report a vulnerability), as described in SECURITY.md.
