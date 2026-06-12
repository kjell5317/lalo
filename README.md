# Leave a Light on

Blink the smart lights of friends or loved ones when you are thinking about them.

**Leave a Light on (lalo)** is a Flutter app for Android and the web. You sign in with
email or Google (Firebase Auth), connect your **Philips Hue** account or your
**Home Assistant** instance and pick a light. Then you share an invite link with
friends — once they accept, they can blink your light in their own color, and you can
blink theirs.

- 🌐 Web app: <https://app.lalo.lighting>
- 📱 Play Store: <https://play.google.com/store/apps/details?id=de.kjellhanken.lalo>
- 🏠 Landing page: <https://lalo.lighting> (served from [`docs/`](docs/))

## Tech stack

| Part | Tech |
| --- | --- |
| App | Flutter (Android + Web) |
| Auth | Firebase Auth + firebase_ui_auth (email, Google) |
| Data | Cloud Firestore |
| Backend | Cloud Functions (TypeScript, v2 API) talking to the Hue Remote API / Home Assistant REST API |
| Invites | HTTPS deep links + Android App Links (`app_links` package) |
| Hosting | Firebase Hosting (web app), GitHub Pages (landing page) |
| Release | fastlane + GitHub Actions → Firebase App Distribution / Play Store |

## Development

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                    # Android device/emulator

cd functions && npm install && npm run build   # Cloud Functions
```

See [CLAUDE.md](CLAUDE.md) for an architecture overview and
[SETUP.md](SETUP.md) for everything needed to set up Firebase, Philips Hue,
AdMob and the Play Store release from scratch.
