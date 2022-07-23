import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lalo/pages/friend.dart';
import 'package:lalo/pages/loading.dart';
import 'package:lalo/services/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  BannerAd? _ad;
  String? version;
  String? buildNumber;
  final String _url =
      'https://api.meethue.com//v2/oauth2/authorize?client_id=wq9lMKlb0LypJeExHayCZgXLVQGPuInF&response_type=code&state=${user!.uid}';
  var _serviceCaption = 'Connect Philips Hue';

  void _launchURL() async {
    if (_serviceCaption == 'Connect Philips Hue') {
      if (!await launch(_url)) throw 'Could not launch Authentification Flow';
      Navigator.pop(context);
    } else if (_serviceCaption == 'Remove Philips Hue') {
      userRef?.set({
        'api': {
          'name': 'No services connected',
          'credentials': {},
          'lights': []
        },
        'light': {'name': 'Not selected', 'id': ''}
      }, SetOptions(merge: true));
      Fluttertoast.showToast(msg: 'Removed Philips Hue', timeInSecForIosWeb: 3);
      _serviceCaption = 'Connect Philips Hue';
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _ad?.dispose();
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then(
      (value) {
        version = value.version;
        buildNumber = value.buildNumber;
      },
    );
    if (!kIsWeb) {
      BannerAd(
        adUnitId: 'ca-app-pub-1021570699948608/9379851670',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(onAdLoaded: (ad) {
          setState(() {
            _ad = ad as BannerAd;
          });
        }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        }),
      ).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Builder(builder: (context) {
          if (!kIsWeb && _ad != null) {
            return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                  alignment: Alignment.center,
                  child: AdWidget(ad: _ad!),
                  width: _ad!.size.width.toDouble(),
                  height: _ad!.size.height.toDouble(),
                ));
          } else {
            return const SizedBox.shrink();
          }
        }),
        Expanded(
          child: StreamBuilder<dynamic>(
              stream: userRef?.snapshots(),
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
                    contentPadding: const EdgeInsets.all(10),
                    lightTheme: const SettingsThemeData(
                        settingsListBackground: Colors.white),
                    darkTheme: SettingsThemeData(
                        settingsListBackground: Colors.grey[900]),
                    sections: [
                      SettingsSection(
                        title: const Text('Light',
                            style: TextStyle(color: Colors.orange)),
                        tiles: <SettingsTile>[
                          SettingsTile.switchTile(
                              leading: const Icon(Icons.do_not_disturb),
                              initialValue: snapshot.data['dnd'],
                              activeSwitchColor: Colors.lightBlueAccent,
                              onToggle: (value) {
                                setState(() {
                                  userRef?.update({'dnd': value});
                                });
                              },
                              title: const Text('Do Not Disturb')),
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Padding(
                                              padding: EdgeInsets.all(15.0),
                                              child: Icon(Icons.lightbulb,
                                                  color: Colors.orange,
                                                  size: 40.0),
                                            ),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(15.0),
                                                child: Text(
                                                  'Connect a service to let your friends blink your light',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline5,
                                                  textAlign: TextAlign.center,
                                                )),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(15.0),
                                              child: ElevatedButton(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Text(_serviceCaption,
                                                      style: const TextStyle(
                                                          fontSize: 18)),
                                                ),
                                                onPressed: () => _launchURL(),
                                              ),
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
                                List<Widget> apis = snapshot.data['api']
                                        ['lights']
                                    .map((i) => ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            fixedSize: const Size(200, 35)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            i['name'],
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        onPressed: () => {
                                              Navigator.pop(context),
                                              userRef?.set({'light': i},
                                                  SetOptions(merge: true))
                                            }))
                                    .toList()
                                    .cast<Widget>();
                                apis.insert(
                                    0,
                                    Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Text('Choose a Light to blink',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5),
                                    ));
                                showModalBottomSheet<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return SizedBox(
                                      child: Center(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: apis,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                Fluttertoast.showToast(
                                    msg: 'No services connected',
                                    timeInSecForIosWeb: 3);
                              }
                            },
                          ),
                        ],
                      ),
                      SettingsSection(
                          title: const Text('Accepted Requests',
                              style: TextStyle(color: Colors.orange)),
                          tiles: [
                            // Feedback
                            SettingsTile.navigation(
                              title: const Text('You\'re a friend of...'),
                              leading: const Icon(Icons.supervisor_account),
                              value: Text(snapshot.data['permissions']!
                                  .map((i) => i['name'])
                                  .join(', ')),
                              onPressed: (context) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const FriendPage())),
                            )
                          ]),
                      SettingsSection(
                        title: const Text('App',
                            style: TextStyle(color: Colors.orange)),
                        tiles: [
                          // Feedback
                          SettingsTile.navigation(
                            title: const Text('Feedback'),
                            leading: const Icon(Icons.feedback),
                            value: const Text('Please provide your feedback'),
                            onPressed: (context) =>
                                Navigator.pushNamed(context, '/feedback'),
                          ),
                          // Info
                          SettingsTile.navigation(
                              title: const Text('Info'),
                              leading: const Icon(Icons.info),
                              value: Text('$version+$buildNumber'),
                              onPressed: (context) {})
                        ],
                      )
                    ],
                  );
                }
                return const LoadingScreen();
              }),
        ),
      ],
    );
  }
}
