import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/pages/loading.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lalo/services/services.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BannerAd? _ad;
  final Map<String, Color> _color = {};

  Future<void> _blink(Map<String, dynamic> _user) async {
    var resp = await FirebaseFunctions.instance
        .httpsCallable('blink')
        .call(<String, String>{
      'userId': _user['uid'],
      'userName': _user['name'],
      'me': user!.uid,
    });
    if (resp.data != null) {
      Fluttertoast.showToast(msg: resp.data, timeInSecForIosWeb: 3);
      setState(() {
        _color[_user['uid']] = Colors.orange;
      });
    }
  }

  Future<void> _createLink() async {
    DocumentReference linkRef =
        FirebaseFirestore.instance.collection('links').doc();
    var body = {
      'dynamicLinkInfo': {
        'domainUriPrefix': 'https://app-lalo.tk/link',
        'link': 'https://app-lalo.tk/?id=${linkRef.id}',
        'androidInfo': {'androidPackageName': 'de.kjellhanken.lalo'},
      },
      'suffix': {'option': 'UNGUESSABLE'}
    };
    var res = await http.post(
        Uri.parse(
            'https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyAUKHRQtdn_rxwt4wGRzzMHVqrDLJSKND0'),
        body: jsonEncode(body));
    if (res.statusCode == 200) {
      Share.share(jsonDecode(res.body)['shortLink']).then((_) {
        linkRef.set({'senderId': user!.uid, 'senderName': user!.displayName});
        analytics!.logShare(
            contentType: 'Friend Request', itemId: user!.uid, method: 'link');
      });
    } else {
      Fluttertoast.showToast(
          msg: res.statusCode.toString() + ': Could not create link',
          timeInSecForIosWeb: 3);
    }
  }

  Future<void> _accept() async {
    Navigator.pop(context);
    String? senderId;
    await FirebaseFirestore.instance
        .doc('links/$initialLink')
        .get()
        .then((data) {
      senderId = data['senderId'];
      if (data['senderId'] == null) return;
      FirebaseFirestore.instance.doc('users/${user!.uid}').update({
        'permissions': FieldValue.arrayUnion([
          {'uid': senderId, 'name': data['senderName'], 'color': 'FFFFFF'}
        ])
      });
    });
    if (senderId == null) {
      Fluttertoast.showToast(msg: 'User not found', timeInSecForIosWeb: 3);
      return;
    }

    final resp = await FirebaseFunctions.instance
        .httpsCallable('accept')
        .call(<String, String>{
      'senderId': senderId!,
      'friendId': user!.uid,
      'friendName': user!.displayName ?? '',
    });
    FirebaseFirestore.instance.doc('links/$initialLink').delete();
    Fluttertoast.showToast(msg: resp.data, timeInSecForIosWeb: 3);
    initialLink = null;
  }

  void _modal() async {
    DocumentSnapshot<Map<String, dynamic>> link =
        await FirebaseFirestore.instance.doc('links/$initialLink').get();
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 15.0, bottom: 5.0),
                  child:
                      Icon(Icons.group_add, color: Colors.orange, size: 40.0),
                ),
                Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(children: [
                      Text(
                        'Friend Request',
                        style: Theme.of(context).textTheme.headline5,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'from ${link["senderName"]}',
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.center,
                      ),
                    ])),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        fixedSize: const Size(200, 40)),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Accept',
                            style: TextStyle(fontSize: 18),
                          ),
                          Icon(Icons.check)
                        ],
                      ),
                    ),
                    onPressed: () {
                      _accept();
                    },
                  ),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(fixedSize: const Size(200, 40)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Deny', style: TextStyle(fontSize: 18)),
                        Icon(Icons.close)
                      ],
                    ),
                  ),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .doc('links/$initialLink')
                        .delete();
                    initialLink = null;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeColor(String uid) async {
    setState(() {
      _color[uid] = Colors.lightBlueAccent;
    });
    await Future.delayed(const Duration(seconds: 30));
    setState(() {
      _color[uid] = Colors.orange;
    });
  }

  void _link() async {
    if (initialLink != null && !waiting) {
      DocumentSnapshot<Map<String, dynamic>> link =
          await FirebaseFirestore.instance.doc('links/$initialLink').get();
      if (link.exists) {
        DocumentSnapshot<Object?> data = await userRef!.get();
        if (link['senderId'] == user!.uid) {
          FirebaseFirestore.instance.doc('links/$initialLink').delete();
          initialLink = null;
          Fluttertoast.showToast(
              msg: 'You can\'t be friends with yourself',
              timeInSecForIosWeb: 3);
        } else if (data['permissions']
            .map((i) => i['uid'])
            .contains(link['senderId'])) {
          FirebaseFirestore.instance.doc('links/$initialLink').delete();
          initialLink = null;
          Fluttertoast.showToast(
              msg: 'You are already friends', timeInSecForIosWeb: 3);
        } else if (data['light']['name'] == 'Not selected') {
          Fluttertoast.showToast(
              msg: 'Select a light before you can accept the request',
              timeInSecForIosWeb: 3);
          waiting = true;
        } else {
          _modal();
        }
      } else {
        initialLink = null;
        Fluttertoast.showToast(msg: 'Invalid link', timeInSecForIosWeb: 3);
      }
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!kIsWeb) {
        FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
          initialLink = Uri.parse(dynamicLink.link.queryParameters['id'] ?? '');
          _link();
        });
      } else {
        _link();
      }
    });
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
          child: Builder(builder: (context) {
            return StreamBuilder<dynamic>(
                stream: userRef?.snapshots(),
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.hasData) {
                    if (waiting &&
                        initialLink != null &&
                        snapshot.data['light']['name'] != 'Not selected') {
                      _modal();
                      waiting = false;
                    }
                    List<Widget> tiles = snapshot.data['friends']
                        .map((i) {
                          if (!_color.containsKey(i['uid'])) {
                            _color[i['uid']] = Colors.orange;
                          }
                          if (snapshot.data['dnd']) {
                            for (var k in _color.keys) {
                              _color[k] = Colors.lightBlueAccent;
                            }
                          }
                          return InkWell(
                              onTap: () {
                                if (_color[i['uid']] == Colors.orange) {
                                  _changeColor(i['uid']);
                                  _blink(i);
                                } else {
                                  if (snapshot.data['dnd']) {
                                    Fluttertoast.showToast(
                                        msg: 'Switch off Do Not Disturb mode',
                                        timeInSecForIosWeb: 3);
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: 'Please wait at least 30 seconds',
                                        timeInSecForIosWeb: 3);
                                  }
                                }
                              },
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: _color[i['uid']],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(i['name'],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: Colors.white,
                                            )),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.lightbulb,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ));
                        })
                        .toList()
                        .cast<Widget>();
                    if (snapshot.data['friends'].length < 10) {
                      tiles.add(InkWell(
                          onTap: () {
                            _createLink();
                          },
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Add a friend',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 24, color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )));
                    }
                    return GridView.count(
                      primary: false,
                      padding: const EdgeInsets.all(20),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: 2,
                      children: tiles,
                    );
                  }
                  return const LoadingScreen();
                });
          }),
        ),
      ],
    );
  }
}
