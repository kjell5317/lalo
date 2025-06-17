import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:lalo/pages/subpages/login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return ProfileScreen(
          appBar: AppBar(title: const Text('Profile')),
          actions: [
            SignedOutAction((context) {
              Navigator.pushReplacementNamed(context, '/home');
            }),
          ]);
    } else {
      return const LoginPage();
    }
  }
}
