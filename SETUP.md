# SETUP — everything you need to run & release Leave a Light on

This guide covers the full setup to get the **web app**, the **Android app** and the
**release pipeline** working again, including the new deep-link feature that replaces
the discontinued Firebase Dynamic Links.

---

## 1. Local toolchain

| Tool | Version | Notes |
| --- | --- | --- |
| Flutter | ≥ 3.44 (stable) | required by firebase_ui_auth 3.x — run `flutter upgrade` |
| Node.js | 22 | matches `functions/package.json` `engines` |
| Firebase CLI | ≥ 14 | `npm i -g firebase-tools`, then `firebase login` |
| Ruby + Bundler | 3.3 | only for fastlane releases: `bundle install` |
| Android Studio / SDK | AGP 8.7, Java 17 | for Android builds |

```bash
flutter pub get
cd functions && npm install
```

## 2. Firebase project (`lalo-2605`)

The project id is configured in [.firebaserc](.firebaserc). If you recreate the project
from scratch:

1. **Create the project** in the [Firebase console](https://console.firebase.google.com),
   enable **Blaze** plan (required for Cloud Functions making outbound requests to the
   Hue API).
2. **Apps**: register
   - an **Android app** with package `de.kjellhanken.lalo` → download
     `google-services.json` into `android/app/`,
   - a **Web app** → run `flutterfire configure` to regenerate
     [lib/firebase_options.dart](lib/firebase_options.dart).
3. **Authentication** → enable the **Email/Password** and **Google** sign-in providers.
   - Copy the **Web client id** (Google provider → Web SDK configuration) into
     `googleClientId` in [lib/services/globals.dart](lib/services/globals.dart) and into
     `web/index.html` if you use the Google Sign-In meta tag.
   - Add the Android app's **SHA-1 and SHA-256** fingerprints (debug + Play App Signing,
     see §6) under *Project settings → Your apps → Android* — Google sign-in on Android
     won't work without them.
4. **Firestore**: create the database, then deploy rules & indexes:
   `firebase deploy --only firestore`.
5. **Hosting**: the hosting target `app` maps to the site `lalo-2605`
   (see [.firebaserc](.firebaserc)). Connect the custom domain **app.lalo.lighting**
   under *Hosting → Add custom domain* (DNS: A/AAAA records as shown in the console).

## 3. Cloud Functions & the Philips Hue Remote API

The functions in [functions/src/index.ts](functions/src/index.ts) talk to the Hue
Remote API. You need a (free) account on the
[Hue developer portal](https://developers.meethue.com/) with a **Remote API app**:

- **Callback URL** of the Hue app must be the deployed `callback` function URL, e.g.
  `https://us-central1-lalo-2605.cloudfunctions.net/callback`.
- The **ClientId** is public and lives in `HUE_CLIENT_ID`
  ([functions/src/index.ts](functions/src/index.ts)) and `hueClientId`
  ([lib/services/globals.dart](lib/services/globals.dart)).
- The **ClientSecret** is now a managed secret (no longer hardcoded). Set it once:

```bash
firebase functions:secrets:set HUE_CLIENT_SECRET
# paste the secret from the Hue developer portal when prompted
firebase deploy --only functions
```

> ⚠️ The old secret was committed to git history. Rotate it in the Hue developer
> portal ("regenerate client secret") and set the *new* value as the secret.

## 4. Deep links (replaces Firebase Dynamic Links)

Firebase Dynamic Links was shut down on 2025-08-25. Invites are now plain HTTPS links
of the form `https://app.lalo.lighting/?id=<linkId>` handled via **Android App Links**:

1. **Web**: nothing to do — the web app reads `?id=` from the URL.
2. **Android**: the `autoVerify` intent filter already exists in
   [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml). For verification to
   succeed, **`https://app.lalo.lighting/.well-known/assetlinks.json` must be live** and
   contain your signing certificate fingerprints.
3. Edit [web/.well-known/assetlinks.json](web/.well-known/assetlinks.json) and replace
   the placeholders with real SHA-256 fingerprints:
   - **Play App Signing key** (the one Google signs releases with):
     Play Console → *Test and release → Setup → App signing* → "App signing key
     certificate" → SHA-256.
   - **Upload/debug key** (so local builds also open links):
     `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep SHA256`
4. Deploy hosting: `firebase deploy --only hosting` (the file is copied into
   `build/web/` by `flutter build web`).
5. Verify: `adb shell pm verify-app-links --re-verify de.kjellhanken.lalo` and
   <https://developers.google.com/digital-asset-links/tools/generator>.

## 5. AdMob

- The app id in [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
  (`ca-app-pub-1021570699948608~…`) must match your AdMob app.
- `bannerAdUnitId` in [lib/services/globals.dart](lib/services/globals.dart) is
  currently **Google's test banner id** — replace it with your real ad unit id before a
  production release, and keep the test id for development.

## 6. Android release & Play Store

1. **Keystore**: `android/key.properties` (not committed) must point to your upload
   keystore:

   ```properties
   storeFile=/absolute/path/upload-keystore.jks
   storePassword=…
   keyAlias=…
   keyPassword=…
   ```

   If you lost it, create a new one
   (`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`)
   and request an **upload key reset** in the Play Console.
2. **Build**: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
3. **Play Console** requirements:
   - Target API level: Flutter's current `targetSdkVersion` (set automatically) meets
     the Play policy.
   - **Privacy policy URL**: `https://lalo.lighting/datenschutz.html` (served from
     [docs/](docs/)).
   - **Data safety form**: declare Firebase Auth (email), Firestore (names, friend
     lists), Crashlytics, Analytics and AdMob (ads, AD_ID permission is declared in the
     manifest).
   - Upload the AAB to a release track (internal → production).
4. **App Links**: after the first Play release, copy the *App signing key* SHA-256 into
   `assetlinks.json` (§4) and redeploy hosting — otherwise invite links open the
   browser instead of the app.

## 7. CI / fastlane (automatic distribution)

Pushing to `main` runs [.github/workflows/distribute.yml](.github/workflows/distribute.yml):
bumps the build number (cider), runs `firebase deploy` (hosting + functions + rules) and
uploads the AAB to **Firebase App Distribution**.

Required GitHub repository **secrets**:

| Secret | Value |
| --- | --- |
| `FIREBASE_TOKEN` | `firebase login:ci` token (or migrate to a service-account JSON) |
| `FIREBASE_APP_ID` | Android app id from Firebase project settings (`1:996…:android:…`) |

Note: CI builds are **unsigned for Play** unless you also provide the keystore there;
the current pipeline targets App Distribution for testers. For Play releases, build and
upload locally (§6) or extend fastlane with `upload_to_play_store` and a Play service
account.

## 8. Landing page (GitHub Pages)

[docs/](docs/) is a plain static site (no Jekyll — `.nojekyll` is present):

- `index.html` — marketing page, `datenschutz.html` — privacy policy
  (renders `datenschutz.md`), `404.html`.
- GitHub repo settings → Pages → deploy from branch, folder `/docs`.
- The custom domain `lalo.lighting` is configured via [docs/CNAME](docs/CNAME); keep the
  DNS `A`/`CNAME` records pointing at GitHub Pages.

## 9. Smoke test checklist

- [ ] `flutter analyze` — clean
- [ ] `cd functions && npm run lint && npm run build` — clean
- [ ] `flutter build web` and `flutter build appbundle --release` succeed
- [ ] Sign in (email + Google) on web and Android
- [ ] Connect Philips Hue → lights appear → select light
- [ ] Share invite link from device A, open on device B (app opens via App Link),
      accept → blink works both ways
- [ ] `https://app.lalo.lighting/.well-known/assetlinks.json` returns your fingerprints
