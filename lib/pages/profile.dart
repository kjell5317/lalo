import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(actions: [
      SignedOutAction((context) {
        Navigator.of(context).pushReplacementNamed('/login');
      }),
    ], providerConfigs: const [
      EmailProviderConfiguration(),
      GoogleProviderConfiguration(
        clientId:
            '996256225333-pf7pkq5ru9i6v85qdog3fl5vgub99l6a.apps.googleusercontent.com',
      ),
    ]);
  }
}
