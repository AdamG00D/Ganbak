# Jisr (جسر) — plan for our own Bluetooth library

**Status: approved by the owner (2026-11-27), postponed to a later session.** Nothing is built yet. This file keeps
everything decided so far so no detail is lost. Read it together with `docs/FDROID.md` (why we need it).

## Why

Bluetooth in Wasl goes through Google Nearby Connections (`play-services-nearby`), which is proprietary:

- the main F-Droid repository refuses it;
- phones without Google Play Services (Huawei, de-Googled phones) can't use Bluetooth in Wasl at all;
- there is **no maintained open-source library** that does what Nearby does without Play Services (checked
  2026-11-27) — an empty niche, good for discoverability.

## Decisions

| Topic | Decision |
|---|---|
| Name | **Jisr** (جسر, "bridge") — free on pub.dev and GitHub (checked) |
| Repo | `AdamG00D/jisr`, created by Claude with `gh` when the work starts (owner said "do it") |
| License | Apache-2.0 (usable by anyone; compatible with Wasl's GPL-3.0) |
| Description (SEO) | "Open-source alternative to Google Nearby Connections — offline peer-to-peer for Android over Bluetooth LE and Wi-Fi, no Google Play Services" + topics (bluetooth-le, ble, p2p, offline, mesh, android, flutter, nearby-connections, wifi-direct, wifi-aware, l2cap) |
| Shape | monorepo: `android/` Kotlin library (AAR), `flutter/` plugin package `jisr`, `sample/` Flutter test app, `docs/` (RESEARCH.md, PROTOCOL.md, DEVICES.md compatibility table, SECURITY.md), CI (build + unit tests), CHANGELOG, CONTRIBUTING |
| API | close to Nearby so apps can switch easily: `startAdvertising(serviceId, info)`, `startDiscovery(serviceId)`, `requestConnection` / `acceptConnection` (+ auto-connect "cluster" mode like `P2P_CLUSTER`), `sendPayload` (bytes / stream / file), callbacks `onEndpointFound/Lost`, `onConnectionResult`, `onDisconnected`, `onPayload`, `onTransferUpdate` |
| Wasl integration | a new `JisrLink` implementing `MeshLink` next to `NearbyLink`; GitHub build keeps Nearby until Jisr is proven, an F-Droid flavour uses Jisr only; later maybe Jisr everywhere |
| Test phones | owner has several Samsung phones + one old Realme (ask the Android versions: Settings → About phone) |

## Phases

| # | Work | Who |
|---|---|---|
| 0. Research | Read Google's open-source Nearby core (C++, `github.com/google/nearby`: BLE medium, bandwidth upgrade design), bitchat-android (BLE mesh, uses the Nordic BLE library — learn ideas, don't copy GPL code), Briar's Bluetooth plugin, Nordic Android-BLE-Library, Punch Through's Android BLE guide, AOSP docs. Write `docs/RESEARCH.md`: every known pitfall + our fix. | Claude |
| 1. BLE | Discovery: advertise a service UUID + short endpoint id in service data; scan with filters; duty-cycle scans (Android throttles > 5 starts / 30 s and downgrades scans after 30 min). Connection: **L2CAP CoC** on Android 10+ (insecure channel; PSM shared in the advertisement or a GATT characteristic; request a big MTU so Android uses 251-byte data length), **GATT fallback** for Android 7–9 or when L2CAP fails (MTU 517, write-without-response with flow control, notifications). Framing, chunking, acks, keepalive, reconnection, several links at once (≈ 5–7), central + peripheral at the same time, permissions helper (Android 12+ `BLUETOOTH_SCAN/ADVERTISE/CONNECT` with `neverForLocation`; ≤ 11 location), works with the host app's foreground service. | Claude |
| Test 1 | Sample app on two phones: do they find each other, talk, speed, walk away and come back. | **Owner** |
| 2. Wi-Fi upgrade | Negotiated over BLE, then data moves to the fastest path: same Wi-Fi (LAN, IP:port), Wi-Fi Direct (group owner with name/passphrase), Wi-Fi Aware where supported, Local-Only Hotspot (like Wasl network). Falls back to BLE if Wi-Fi drops. | Claude |
| Test 2 | Same as test 1, checking the upgrade and speed. | **Owner** |
| 3. Link encryption | Authenticated encryption of the link (Noise pattern with X25519 + AES-GCM/ChaCha20), with a hook so apps can bind their own identities. Wasl's end-to-end encryption stays on top. | Claude |
| 4. Wasl | `JisrLink` in Wasl, F-Droid flavour without `nearby_connections`, F-Droid recipe (`fdroiddata`, Flutter as srclib). | Claude |
| Test 3 | Wasl over Jisr on the owner's phones, ideally one phone without Google services (Huawei). | **Owner** |
| 5. Publish | JitPack first (no account needed), then Maven Central (owner: Sonatype account) and pub.dev (owner: Google account as publisher); docs site on GitHub Pages; announce (Reddit r/androiddev, r/FlutterDev, r/fossdroid). | Claude + **owner** (accounts) |

Rough size: phase 1 ≈ 2–3 sessions, phase 2 about the same, the rest less. Real time depends on phone testing —
every phase is tested before the next.

## Known pitfalls to handle (from the 2026-11-27 research)

- **GATT error 133**: stop scanning before connecting, wait ≈ 500 ms, connect with `TRANSPORT_LE`, `autoConnect = false`,
  retry with backoff; Huawei / Asus are worse at connecting during a scan.
- **Leaked GATT clients** ("max gatt client reached: 32"): always `close()` — otherwise every BLE operation fails.
- **Scan throttling / downgrade**: max 5 scan starts per 30 s; scans longer than 30 min become opportunistic —
  duty-cycle; background scans need filters.
- **L2CAP throughput**: Android only uses the 251-byte data length when a big ATT MTU is requested; PHY may drop
  from 2M to 1M.
- **Random BLE addresses** rotate (~15 min): identity must come from the advertised data, never the MAC.
- **Advertising payload** is 31 bytes (legacy): 128-bit UUID + a few bytes of service data — use short ids; check
  `isMultipleAdvertisementSupported` (some old phones can't advertise).
- **Vendors killing background apps** (Xiaomi, Huawei, Realme/Oppo): rely on the foreground service and explain
  battery-optimisation exemptions (dontkillmyapp.com).
- **Bluetooth / Wi-Fi coexistence** on 2.4 GHz slows both; prefer 5 GHz for the Wi-Fi upgrade where possible.
- **Android 14+**: foreground service type `connectedDevice` required; stricter background starts.
- Google's Play Services has privileges a normal app doesn't — get close, not identical; be honest about it in the
  README.

## Open items for the owner (when we start)

1. Android versions of the Samsung phones and the Realme.
2. OK to create `AdamG00D/jisr` (already given) — Claude creates it at the start.
3. At publish time only: pub.dev publisher account; optional Sonatype account for Maven Central.
