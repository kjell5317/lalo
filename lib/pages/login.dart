import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:lalo/services/globals.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      headerBuilder: (context, _, __) {
        return const Center(
            child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Leave a Light on',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
                fontSize: 45,
              )),
        ));
      },
      actions: [
        AuthStateChangeAction<SignedIn>((context, value) {
          Navigator.of(context).pushReplacementNamed('/home');
          analytics!.logLogin();
        })
      ],
      providerConfigs: const [
        EmailProviderConfiguration(),
        GoogleProviderConfiguration(
          clientId:
              '996256225333-pf7pkq5ru9i6v85qdog3fl5vgub99l6a.apps.googleusercontent.com',
        ),
      ],
    );
  }
}
