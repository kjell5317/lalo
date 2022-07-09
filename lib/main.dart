import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:lalo/services/services.dart';

import 'package:lalo/pages/login.dart';
import 'package:lalo/pages/home.dart';
import 'package:lalo/pages/more.dart';
import 'package:lalo/pages/loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  if (!kIsWeb) {
    initialLink = (await FirebaseDynamicLinks.instance.getInitialLink())?.link;
  } else if (Uri.base.queryParameters['id'] != null) {
    initialLink = Uri.parse(Uri.base.queryParameters['id']!);
  }
  await dotenv.load(fileName: 'web.env');

  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  static const List _pages = [
    ['Home', 'Menu'],
    [HomePage(), MorePage()]
  ];

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: routes,
      home: Builder(builder: (context) {
        return StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              if (snapshot.hasData) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(App._pages[0][_selectedIndex]),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey[400],
                            child: Text(
                              FirebaseAuth.instance.currentUser?.email
                                      ?.substring(0, 2)
                                      .split('@')[0]
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
                  body: IndexedStack(
                    index: _selectedIndex,
                    children: App._pages[1],
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.menu), label: 'Menu'),
                    ],
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                  ),
                );
              }
              return const LoginPage();
            });
      }),
      theme: themeLight,
      darkTheme: themeDark,
    );
  }
}
