import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lalo/components/lalo_app_bar.dart';
import 'package:lalo/pages/lalo_page.dart';
import 'package:lalo/pages/subpages/name.dart';

import 'package:lalo/services/services.dart';

import 'package:lalo/pages/subpages/login.dart';
import 'package:lalo/pages/home.dart';
import 'package:lalo/pages/more.dart';
import 'package:lalo/pages/subpages/loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  analytics = FirebaseAnalytics.instance;
  FirebaseUIAuth.configureProviders([
    GoogleProvider(clientId: googleClientId),
    EmailAuthProvider(),
  ]);

  await initDeepLinks();
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    MobileAds.instance.initialize();
  }
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  static const List<LaloPage> _pages = [HomePage(), MorePage()];

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  BannerAd? _ad;
  bool _initializedData = false;

  // Created once. Switching tabs rebuilds this widget; handing the
  // StreamBuilders a fresh stream each build reset them to ConnectionState
  // .waiting for a frame — flashing the LoadingScreen (the flicker) and
  // remounting the tab pages. Stable streams keep the last snapshot instead.
  final Stream<User?> _authState = FirebaseAuth.instance.authStateChanges();
  Stream<DocumentSnapshot>? _userDoc;
  String? _userDocUid;

  Stream<DocumentSnapshot> _userDocStream(String uid) {
    if (_userDocUid != uid) {
      _userDocUid = uid;
      _userDoc = FirebaseFirestore.instance.doc('users/$uid').snapshots();
    }
    return _userDoc!;
  }

  int _i = 0;
  void _onItemTapped(int index) {
    setState(() {
      _i = index;
    });
  }

  void setInitialData() {
    analytics!.logSignUp(
      signUpMethod: user!.providerData.isNotEmpty
          ? user!.providerData[0].providerId
          : 'unknown',
    );
    userRef?.set({
      'light': {'name': 'Not selected', 'id': '', 'last': 0, 'color': false},
      'api': {'name': 'No services connected'},
      'friends': [],
      'permissions': [],
      'dnd': false,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _ad = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
          },
        ),
      ).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave a Light on',
      scaffoldMessengerKey: scaffoldMessengerKey,
      routes: routes,
      theme: themeLight,
      darkTheme: themeDark.copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: StreamBuilder(
        stream: _authState,
        builder: (BuildContext context, AsyncSnapshot<Object?> snapshotAuth) {
          if (snapshotAuth.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (!snapshotAuth.hasData) {
            return const LoginPage();
          }
          user = FirebaseAuth.instance.currentUser;
          userRef = FirebaseFirestore.instance.doc('users/${user!.uid}');
          return StreamBuilder(
            stream: _userDocStream(user!.uid),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshotDb,
                ) {
                  if (!snapshotDb.hasData) {
                    return const LoadingScreen();
                  }
                  if (!snapshotDb.data!.exists) {
                    // Guard against build() firing repeatedly while the doc
                    // is being created — otherwise logSignUp/set run each time.
                    if (!_initializedData) {
                      _initializedData = true;
                      setInitialData();
                    }
                    return const LoadingScreen();
                  }
                  if (user?.displayName == null) {
                    return const NamePage();
                  }
                  return Scaffold(
                    appBar: LaloAppBar(name: App._pages[_i].name),
                    body: Column(
                      children: [
                        if (!kIsWeb && _ad != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Container(
                              alignment: Alignment.center,
                              width: _ad!.size.width.toDouble(),
                              height: _ad!.size.height.toDouble(),
                              child: AdWidget(ad: _ad!),
                            ),
                          ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: IndexedStack(
                                index: _i,
                                children: App._pages,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    bottomNavigationBar: NavigationBar(
                      destinations: <NavigationDestination>[
                        NavigationDestination(
                          icon: const Icon(Icons.home),
                          label: App._pages[0].name,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.settings),
                          label: App._pages[1].name,
                        ),
                      ],
                      selectedIndex: _i,
                      onDestinationSelected: _onItemTapped,
                    ),
                  );
                },
          );
        },
      ),
    );
  }
}
