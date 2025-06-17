import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lalo/services/globals.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      headerBuilder: (context, _, __) {
        return const Center(
            child: Padding(
          padding: EdgeInsets.only(top: 35.0),
          child: FaIcon(FontAwesomeIcons.lightbulb,
              size: 100, color: Colors.orange),
        ));
      },
      actions: [
        AuthStateChangeAction<SignedIn>((context, value) {
          Navigator.of(context).pushReplacementNamed('/home');
          analytics!.logLogin();
        })
      ],
    );
  }
}
