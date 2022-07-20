import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:lalo/pages/login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return ProfileScreen(actions: [
        SignedOutAction((context) {
          Navigator.pop(context);
        }),
      ], providerConfigs: const [
        EmailProviderConfiguration(),
        GoogleProviderConfiguration(
          clientId:
              '996256225333-pf7pkq5ru9i6v85qdog3fl5vgub99l6a.apps.googleusercontent.com',
        ),
      ]);
    } else {
      return const LoginPage();
    }
  }
}
