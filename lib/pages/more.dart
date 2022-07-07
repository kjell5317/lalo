import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/pages/loading.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final Stream<DocumentSnapshot> _userStream = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

  final String _url =
      'https://api.meethue.com//v2/oauth2/authorize?client_id=wq9lMKlb0LypJeExHayCZgXLVQGPuInF&response_type=code&state=' +
          FirebaseAuth.instance.currentUser!.uid;

  var _serviceCaption = 'Enable Philips Hue';

  void _launchURL() async {
    if (_serviceCaption == 'Enable Philips Hue') {
      if (!await launch(_url)) throw 'Could not launch $_url';
      Navigator.pop(context);
    } else if (_serviceCaption == 'Remove Philips Hue') {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'api': {
          'name': 'No services connected',
          'credentials': {},
          'lights': []
        },
        'light': {'name': 'Not selected', 'id': ''}
      }, SetOptions(merge: true));
      Fluttertoast.showToast(msg: 'Removed Philips Hue');
      _serviceCaption = 'Enable Philips Hue';
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
        stream: _userStream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data['light']['name'] == null) {
              snapshot.data['light']['name'] = 'Not selected';
            }
            if (snapshot.data?['api']['name'] == null) {
              snapshot.data['api']['name'] = 'No services connected';
            } else if (snapshot.data['api']['name'] == 'Philips Hue') {
              _serviceCaption = 'Remove Philips Hue';
            }

            return SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('My light'),
                  tiles: <SettingsTile>[
                    // Services
                    SettingsTile.navigation(
                        leading: const Icon(Icons.home),
                        title: const Text('Services'),
                        value: Text(snapshot.data['api']['name']),
                        onPressed: (context) {
                          // Service Modal
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
                                        style: ElevatedButton.styleFrom(
                                            fixedSize: const Size(200, 30)),
                                        child: Text(_serviceCaption),
                                        onPressed: () => _launchURL(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                    // Light
                    SettingsTile.navigation(
                      leading: const Icon(Icons.lightbulb),
                      title: const Text('Light'),
                      value: Text(snapshot.data['light']['name']),
                      onPressed: (context) {
                        // Light Modal
                        if (snapshot.data['api']['name'] !=
                            'No services connected') {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                child: Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      mainAxisSize: MainAxisSize.min,
                                      children: snapshot.data['api']['lights']
                                          .map((i) => ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  fixedSize:
                                                      const Size(200, 30)),
                                              child: Text(i['name']),
                                              onPressed: () => {
                                                    Navigator.pop(context),
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(FirebaseAuth
                                                            .instance
                                                            .currentUser!
                                                            .uid)
                                                        .set({
                                                      'light': i
                                                    }, SetOptions(merge: true))
                                                  }))
                                          .toList()
                                          .cast<Widget>()
                                      // TODO: Add heading Text Widget
                                      // .insert(0, const Text('Choose a Light')),
                                      ),
                                ),
                              );
                            },
                          );
                        } else {
                          Fluttertoast.showToast(msg: 'No services connected');
                        }
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
