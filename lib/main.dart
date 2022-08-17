import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:lalo/services/services.dart';

import 'package:lalo/pages/login.dart';
import 'package:lalo/pages/name.dart';
import 'package:lalo/pages/home.dart';
import 'package:lalo/pages/more.dart';
import 'package:lalo/pages/loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  analytics = FirebaseAnalytics.instance;
  if (!kIsWeb) {
    initialLink = await FirebaseDynamicLinks.instance
        .getInitialLink()
        .then((value) => value?.link.queryParameters['id']);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    MobileAds.instance.initialize();
  } else if (Uri.base.queryParameters['id'] != null) {
    initialLink = Uri.base.queryParameters['id'];
  }

  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  static const List _pages = [
    ['Home', 'Settings'],
    [HomePage(), MorePage()]
  ];

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  BannerAd? _ad;
  StreamSubscription? _stream;

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _ad?.dispose();
    _stream?.cancel();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _stream = FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
        var link = dynamicLink.link.queryParameters['id'];
        if (link != initialLink) {
          initialLink = link;
        }
      });

      BannerAd(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(onAdLoaded: (ad) {
          setState(() {
            _ad = ad as BannerAd;
          });
        }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        }),
      ).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave a Light on',
      routes: routes,
      theme: themeLight,
      darkTheme: themeDark.copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              )),
      home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (BuildContext context, AsyncSnapshot<Object?> snapshotAuth) {
            if (snapshotAuth.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }
            if (snapshotAuth.hasData) {
              user = FirebaseAuth.instance.currentUser;
              userRef = FirebaseFirestore.instance.doc('users/${user!.uid}');
              return StreamBuilder(
                  stream: userRef?.snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshotDb) {
                    if (!snapshotDb.hasData) {
                      return const LoadingScreen();
                    }
                    if (!snapshotDb.data!.exists) {
                      analytics!.logSignUp(
                          signUpMethod: user!.providerData[0].providerId);
                      userRef?.set({
                        'light': {
                          'name': 'Not selected',
                          'id': '',
                          'last': 0,
                          'color': false
                        },
                        'api': {'name': 'No services connected'},
                        'friends': [],
                        'permissions': [],
                        'dnd': false,
                      }, SetOptions(merge: true));
                      return const LoadingScreen();
                    } else {
                      if (user?.displayName == null) {
                        return const NamePage();
                      }
                      return Scaffold(
                        appBar: AppBar(
                          title: Text(App._pages[0][_selectedIndex]),
                          actions: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/profile'),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey[400],
                                  child: Text(
                                    user!.displayName
                                            ?.substring(0, 2)
                                            .toUpperCase() ??
                                        'HI',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        body: Column(
                          children: [
                            Builder(builder: (context) {
                              if (!kIsWeb && _ad != null) {
                                return Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: AdWidget(ad: _ad!),
                                      width: _ad!.size.width.toDouble(),
                                      height: _ad!.size.height.toDouble(),
                                    ));
                              } else {
                                return const SizedBox.shrink();
                              }
                            }),
                            Expanded(
                              child: IndexedStack(
                                index: _selectedIndex,
                                children: App._pages[1],
                              ),
                            ),
                          ],
                        ),
                        bottomNavigationBar: BottomNavigationBar(
                          items: const <BottomNavigationBarItem>[
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home),
                              label: 'Home',
                            ),
                            BottomNavigationBarItem(
                                icon: Icon(Icons.settings), label: 'Settings'),
                          ],
                          currentIndex: _selectedIndex,
                          onTap: _onItemTapped,
                        ),
                      );
                    }
                  });
            } else {
              return const LoginPage();
            }
          }),
    );
  }
}
