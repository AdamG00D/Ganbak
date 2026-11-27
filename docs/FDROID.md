# Publishing on F-Droid / IzzyOnDroid

The store texts and images live in `fastlane/metadata/android/<locale>/` (`en-US`, `ar`): title, short and full
description, icon (512²), feature graphic (1024×500, from the README banner), phone screenshots (from
`docs/images/screenshots`) and `changelogs/<versionCode>.txt` (≤ 500 characters, one per release). Both F-Droid and
IzzyOnDroid read this folder straight from the repository.

## The blocker: Google Nearby

Bluetooth goes through `nearby_connections`, which pulls in **`com.google.android.gms:play-services-nearby`**, a
proprietary library. The **main F-Droid repository does not accept it**, so the app as it is today can't be built
there. Options, for the owner to decide:

| Option | What it means | Cost |
|---|---|---|
| **A. IzzyOnDroid** (recommended first) | A third-party F-Droid repository that ships the APKs from GitHub releases. Users add the repo in the F-Droid client. | Ask for inclusion (issue / form on IzzyOnDroid). Their scanner will flag the Google library; check their current policy before applying. No code change. |
| **B. A `foss` build flavour** | A second build without `nearby_connections`: Wi-Fi / hotspot / Wasl network only, no Bluetooth. Submitted to F-Droid's `fdroiddata` with the Flutter SDK as a submodule (srclib). | Real code work (split `NearbyLink` behind a flavour, hide Bluetooth in the UI), a second APK to test, and the F-Droid recipe. |
| **C. Own Bluetooth transport** | Replace Nearby with plain Bluetooth (RFCOMM / BLE) written in Kotlin. | Large: discovery, connection limits, background rules on every Android version. |

Whatever the choice, the release APKs must stay **reproducible enough** for the store (same Flutter version, no
build-time timestamps) and signed with the same key (see `../Signing_Key/`, never in the repo).

## Checklist for a release

1. Add `fastlane/metadata/android/{en-US,ar}/changelogs/<versionCode>.txt` (the versionCode from `pubspec.yaml`).
2. Refresh screenshots when screens change (`flutter test tool/shots/readme_test.dart && python3 tool/shots/readme.py`,
   then copy into `phoneScreenshots/`).
3. Tag the release (`v<X.Y>`) — IzzyOnDroid and F-Droid pick up tags.
