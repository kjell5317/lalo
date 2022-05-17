import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:flutterfire_ui/i10n.dart';
import 'package:lalo/services/services.dart';
import 'package:lalo/services/routes.dart';
import 'package:lalo/services/theme.dart';

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
  // FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  static const List _pages = [
    ["Home", "Mehr"],
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
      localizationsDelegates: [
        FlutterFireUILocalizations.withDefaultOverrides(const LabelOverrides()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterFireUILocalizations.delegate,
      ],
      home: StreamBuilder(
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
                            FirebaseAuth.instance.currentUser?.displayName
                                    ?.substring(0, 2)
                                    .toUpperCase() ??
                                "HI",
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
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.menu), label: "Mehr"),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              );
            }
            return const LoginPage();
          }),
      theme: themeLight,
      darkTheme: themeDark,
    );
  }
}
