import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  analytics = FirebaseAnalytics.instance;

  if (!kIsWeb) {
    initialLink = await FirebaseDynamicLinks.instance
        .getInitialLink()
        .then((dynamicLink) {
      var link = dynamicLink?.link.queryParameters['id'];
      Fluttertoast.showToast(msg: link ?? '??');
      return link;
    });
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
      var link = dynamicLink.link.queryParameters['id'];
      Fluttertoast.showToast(msg: link ?? '??');
      if (link != initialLink) {
        initialLink = link;
      }
    });

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    MobileAds.instance.initialize();
  } else if (Uri.base.queryParameters['id'] != null) {
    initialLink = Uri.base.queryParameters['id'];
  }
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  static const List<LaloPage> _pages = [HomePage(), MorePage()];

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  BannerAd? _ad;

  int _i = 0;
  void _onItemTapped(int index) {
    setState(() {
      _i = index;
    });
  }

  void setInitialData() {
    analytics!.logSignUp(signUpMethod: user!.providerData[0].providerId);
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
    super.dispose();
    _ad?.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
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
            builder:
                (BuildContext context, AsyncSnapshot<Object?> snapshotAuth) {
              if (snapshotAuth.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              if (!snapshotAuth.hasData) {
                return const LoginPage();
              }
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
                      setInitialData();
                      return const LoadingScreen();
                    }
                    if (user?.displayName == null) {
                      return const NamePage();
                    }
                    return Scaffold(
                      appBar: LaloAppBar(
                        name: App._pages[_i].name,
                      ),
                      body: Column(children: [
                        Builder(builder: (context) {
                          if (!kIsWeb && _ad != null) {
                            return Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Container(
                                  alignment: Alignment.center,
                                  width: _ad!.size.width.toDouble(),
                                  height: _ad!.size.height.toDouble(),
                                  child: AdWidget(ad: _ad!),
                                ));
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                        Expanded(
                          child: IndexedStack(index: _i, children: [
                            for (int j = 0; j < App._pages.length; j++) ...[
                              App._pages[j]
                            ]
                          ]),
                        ),
                      ]),
                      bottomNavigationBar: BottomNavigationBar(
                        items: <BottomNavigationBarItem>[
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.home),
                            label: App._pages[0].name,
                          ),
                          BottomNavigationBarItem(
                              icon: const Icon(Icons.settings),
                              label: App._pages[1].name),
                        ],
                        currentIndex: _i,
                        onTap: _onItemTapped,
                      ),
                    );
                  });
            }));
  }
}
