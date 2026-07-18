import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:lalo/services/globals.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      headerBuilder: (context, constraints, shrinkOffset) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 35.0),
            child: Icon(
              Icons.lightbulb_outline,
              size: 100,
              color: Colors.orange,
            ),
          ),
        );
      },
      actions: [
        // Only record the event here. The auth-state StreamBuilder in [App]
        // swaps this screen for the home page automatically once sign-in
        // completes — navigating as well raced that rebuild and crashed on a
        // deactivated context.
        AuthStateChangeAction<SignedIn>((context, value) {
          analytics!.logLogin();
        }),
      ],
    );
  }
}
