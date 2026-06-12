import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Domain of the marketing page; the web app lives at `app.<domain>`.
const String domain = 'lalo.lighting';

/// Base URL of invite links handled by [initDeepLinks].
const String appUrl = 'https://app.$domain';

/// Public OAuth client id of the Philips Hue Remote API app (see SETUP.md).
const String hueClientId = 'wq9lMKlb0LypJeExHayCZgXLVQGPuInF';

/// Public web client id used for Google sign-in.
const String googleClientId =
    '996256225333-pf7pkq5ru9i6v85qdog3fl5vgub99l6a.apps.googleusercontent.com';

/// AdMob banner unit. This is Google's test id — replace for production,
/// see SETUP.md.
const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

// Set by the auth gate in main.dart once a user is signed in. Widgets behind
// the gate may assume these are non-null.
User? user;
DocumentReference? userRef;
FirebaseAnalytics? analytics;
