# CLAUDE.md

This file provides guidance to Claude Code (claude.com/claude-code) when working with this repository.

## What this app is

**Leave a Light on (lalo)** is a Flutter app (Android + Web) that lets you blink the smart
lights of friends or loved ones when you are thinking about them.

Flow: a user signs in (email or Google via Firebase Auth), connects a light service —
**Philips Hue** (OAuth handled by the `callback` Cloud Function) or **Home Assistant**
(URL + long-lived token validated by the `connectHomeAssistant` Cloud Function) — picks
one of their lights, and shares an invite link. A friend who opens the link in the
app/web app can accept the request; afterwards the friend can tap a tile on the home
screen to blink the user's light in a chosen color (the `blink` Cloud Function talks to
the Hue Remote API or the Home Assistant REST API).

Firebase project: `lalo-2605`. Web app is deployed to Firebase Hosting
(`app.lalo.lighting`), the marketing page lives in `docs/` (GitHub Pages, `lalo.lighting`),
and the Android app ships to Google Play as `de.kjellhanken.lalo`.

## Repository layout

- `lib/` — Flutter app
  - `main.dart` — entry point: Firebase init, auth gate, ads banner, bottom navigation
  - `pages/` — `home.dart` (friend tiles grid, friend-request handling), `more.dart`
    (settings: DND, Hue connection, light selection), `subpages/` (login, profile, name,
    feedback, friend management, loading)
  - `components/` — small reusable widgets (tiles, app bar)
  - `services/` — `globals.dart` (app-wide state/constants), `theme.dart`, `routes.dart`,
    `deep_links.dart` (invite-link handling), `services.dart` (barrel file)
- `functions/` — Firebase Cloud Functions (TypeScript): Hue OAuth `callback`,
  `connectHomeAssistant`, `blink`, `accept`, scheduled `refresh` (Hue token refresh +
  expired-link cleanup)
- `web/` — Flutter web shell; `web/.well-known/assetlinks.json` is required for Android
  App Links verification and is deployed via Hosting
- `docs/` — static marketing/landing page, served by GitHub Pages (custom domain in
  `docs/CNAME`); includes the privacy policy (`datenschutz.html`) required by Play Store
- `android/` — Android Gradle project (Kotlin DSL-free, classic Groovy)
- `fastlane/`, `.github/workflows/distribute.yml` — CI: on push to `main`, fastlane bumps
  the build number (cider), deploys Firebase (hosting + functions + rules) and uploads the
  AAB to Firebase App Distribution
- `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json` — Firebase config
- `SETUP.md` — everything needed to set up Firebase/Hue/AdMob/Play Store from scratch

## Data model (Firestore)

- `users/{uid}`: `light` (name/id/last/color), `api` (name + per-service fields:
  Hue `credentials`, Home Assistant `url`/`token`, plus `lights`),
  `friends` [{uid, name}], `permissions` [{uid, name, color}], `dnd` (bool)
  - `api.name` is the service discriminator: `'Philips Hue' | 'Home Assistant' | 'No services connected'`
  - `friends` = people whose lights *I* can blink; `permissions` = people allowed to blink *my* light
- `links/{id}`: pending friend request (`senderId`, `senderName`, `time`); deleted on
  accept/deny, expired ones cleaned up by the scheduled `refresh` function
- `feedback/{uid}`: map of timestamp → feedback text

## Deep links (invite flow)

Firebase Dynamic Links was shut down (Aug 2025); invites now use plain **HTTPS links +
Android App Links**: `https://app.lalo.lighting/?id=<linkDocId>`.

- Link creation: `lib/components/lalo_add_tile.dart` creates a `links/{id}` doc and shares the URL
- Handling: `lib/services/deep_links.dart` (`app_links` package on Android, `Uri.base` on
  web) exposes a `ValueNotifier<String?> pendingLink`; `home.dart` listens and shows the
  accept/deny modal
- Android verifies ownership via `web/.well-known/assetlinks.json` (must contain the Play
  App Signing SHA-256, see SETUP.md) and the `autoVerify` intent filter in
  `android/app/src/main/AndroidManifest.xml`

## Common commands

```bash
flutter pub get                 # install Dart deps
flutter analyze                 # lint/static analysis — keep this clean
flutter run -d chrome           # run web locally
flutter build web               # production web build (also hosting predeploy)
flutter build appbundle         # Play Store AAB (needs android/key.properties)

cd functions && npm install && npm run lint && npm run build   # Cloud Functions
firebase deploy                 # hosting + functions + firestore rules
firebase emulators:start --only functions   # local functions testing

bundle exec fastlane distribute # full release pipeline (CI does this on main)
```

There are no Dart unit tests; verification is `flutter analyze` + building.

## Conventions & gotchas

- Secrets: the Hue client secret is a Cloud Functions secret (`HUE_CLIENT_SECRET`,
  managed with `firebase functions:secrets:set`) — never hardcode it. The Hue client ID
  and Google web client ID are public identifiers and live in `lib/services/globals.dart`.
- `lib/services/globals.dart` holds mutable app-wide state (`user`, `userRef`,
  `analytics`) set by the auth gate in `main.dart` — most widgets assume `user != null`
  because they are only reachable behind the auth gate.
- The AdMob banner ID in `main.dart` is Google's **test** ad unit; swap for the real one
  in a production release (see SETUP.md).
- `functions/src/index.ts` uses the firebase-functions v2 API (`onCall` with
  `request.data`, `onSchedule`). Keep new functions on v2.
- Blink rate limiting lives server-side (`light.last`, 30 s) and is mirrored client-side
  with the tile color in `home.dart`.
- Version bumps happen via `cider bump build` in fastlane; app version lives in
  `pubspec.yaml` (`version: x.y.z+build`).
