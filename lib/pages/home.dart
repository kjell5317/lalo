import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Stream<DocumentSnapshot> _userStream = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

  Future<void> _blink(Map<String, dynamic> user) async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('blink');
    final resp = await callable.call(<String, String>{
      'userId': user['uid'],
      'userName': user['name'],
      'me': FirebaseAuth.instance.currentUser!.uid,
    });
    if (resp.data != null) {
      Fluttertoast.showToast(msg: resp.data, timeInSecForIosWeb: 3);
    }
  }

  Future<void> _createLink() async {
    DocumentReference ref =
        FirebaseFirestore.instance.collection('links').doc();
    var body = {
      'dynamicLinkInfo': {
        'domainUriPrefix': 'https://app-lalo.tk/link',
        'link': 'https://lalo-2605.web.app/?id=${ref.id}',
        'androidInfo': {'androidPackageName': 'de.kjellhanken.lalo'},
      },
      'suffix': {'option': 'UNGUESSABLE'}
    };
    var res = await http.post(
        Uri.parse(
            'https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyAUKHRQtdn_rxwt4wGRzzMHVqrDLJSKND0'),
        body: jsonEncode(body));
    if (res.statusCode == 200) {
      Share.share(jsonDecode(res.body)['shortLink']).then((_) => {
            ref.set({
              'senderId': FirebaseAuth.instance.currentUser!.uid,
              'senderName': FirebaseAuth.instance.currentUser!.displayName
            })
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
      if (senderId == null) return;
      FirebaseFirestore.instance
          .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
          .update({
        'permissions': FieldValue.arrayUnion([senderId])
      });
    });
    if (senderId == null) {
      Fluttertoast.showToast(msg: 'User not found', timeInSecForIosWeb: 3);
      return;
    }

    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('accept');
    final resp = await callable.call(<String, String>{
      'senderId': senderId!,
      'friendId': FirebaseAuth.instance.currentUser!.uid,
      'friendName': FirebaseAuth.instance.currentUser!.displayName ?? ''
    });
    FirebaseFirestore.instance.doc('links/$initialLink').delete();
    Fluttertoast.showToast(msg: resp.data, timeInSecForIosWeb: 3);
    initialLink = null;
  }

  void _deny() {
    FirebaseFirestore.instance.doc('links/$initialLink').delete();
    initialLink = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (initialLink != null && !waiting) {
        DocumentSnapshot<Map<String, dynamic>> link =
            await FirebaseFirestore.instance.doc('links/$initialLink').get();
        if (link.exists) {
          DocumentSnapshot<Map<String, dynamic>> perm = await FirebaseFirestore
              .instance
              .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
              .get();
          if (link['senderId'] == FirebaseAuth.instance.currentUser!.uid) {
            _deny();
            Fluttertoast.showToast(
                msg: 'You can\'t be friends with yourself',
                timeInSecForIosWeb: 3);
          } else if (perm['permissions'].contains(link['senderId'])) {
            _deny();
            Fluttertoast.showToast(
                msg: 'You are already friends', timeInSecForIosWeb: 3);
          } else if (perm['light']['name'] == 'Not selected') {
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
    });
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
                    _deny();
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
        stream: _userStream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            if (waiting &&
                initialLink != null &&
                snapshot.data['light']['name'] != 'Not selected') {
              _modal();
              waiting = false;
            }
            List<Widget> tiles = snapshot.data['friends']
                .map((i) {
                  // TODO: Animation
                  // AnimationController(vsync: this),
                  return InkWell(
                      onTap: () {
                        _blink(i);
                      },
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.orange,
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
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
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
  }
}
