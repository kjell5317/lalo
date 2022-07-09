import 'package:lalo/main.dart';
import 'package:lalo/pages/login.dart';
import 'package:lalo/pages/profile.dart';

var routes = {
  '/login': (context) => const LoginPage(),
  '/home': (context) => const App(),
  '/profile': (context) => const ProfilePage()
};
