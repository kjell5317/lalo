import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: create name form for new users
    return SignInScreen(
      actions: [
        AuthStateChangeAction<SignedIn>((context, value) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(value.user!.uid)
              .get()
              .then((doc) => {
                    if (!doc.exists)
                      {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(value.user!.uid)
                            .set({
                          'light': {'name': 'Not selected', 'id': ''},
                          'api': {'name': 'No services connected'},
                          'friends': [],
                          'permissions': [],
                        }, SetOptions(merge: true)).then((_) =>
                                Navigator.of(context)
                                    .pushReplacementNamed('/home'))
                      }
                    else
                      {Navigator.of(context).pushReplacementNamed('/home')}
                  });
        }),
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
