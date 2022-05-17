import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lalo/pages/loading.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final Stream<DocumentSnapshot> _userStream = FirebaseFirestore.instance
      .collection('user')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

  final String _url =
      "https://api.meethue.com//v2/oauth2/authorize?client_id=wq9lMKlb0LypJeExHayCZgXLVQGPuInF&response_type=code&state=" +
          FirebaseAuth.instance.currentUser!.uid;

  void _launchURL() async {
    if (!await launch(_url)) throw 'Could not launch $_url';
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
        stream: _userStream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data['light'] == null) {
              snapshot.data['light'] = "Nicht ausgewählt";
            }
            if (snapshot.data['api'] == null) {
              snapshot.data['api']['name'] = "Kein Dienst verknüpft";
            }

            return SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Mein Licht'),
                  tiles: <SettingsTile>[
                    // Dienste
                    SettingsTile.navigation(
                        leading: const Icon(Icons.home),
                        title: const Text('Verküpfte Dienste'),
                        value: Text('${snapshot.data['api']['name']}'),
                        onPressed: (context) {
                          // Dienst Modal
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      ElevatedButton(
                                        child: const Text('Phillips Hue'),
                                        onPressed: () => _launchURL(),
                                      ),
                                      ElevatedButton(
                                        child: const Text('Close'),
                                        onPressed: () => Navigator.pop(context),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                    // Lampe
                    SettingsTile.navigation(
                      leading: const Icon(Icons.lightbulb),
                      title: const Text('Lampe'),
                      value: Text('${snapshot.data['light']}'),
                      onPressed: (context) {
                        // Lampe Modal
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text('Modal BottomSheet'),
                                    ElevatedButton(
                                      child: const Text('Close BottomSheet'),
                                      onPressed: () => Navigator.pop(context),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          }
          return const LoadingScreen();
        });
  }
}
