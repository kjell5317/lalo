import 'package:lalo/main.dart';
import 'package:lalo/pages/login.dart';
import 'package:lalo/pages/profile.dart';
import 'package:lalo/pages/name.dart';

var routes = {
  '/login': (context) => const LoginPage(),
  '/name': (context) => const NamePage(),
  '/home': (context) => const App(),
  '/profile': (context) => const ProfilePage()
};
