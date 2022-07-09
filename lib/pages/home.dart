import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/pages/loading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lalo/services/services.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color _containerColor = Colors.orange;

  final Stream<DocumentSnapshot> _userStream = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

  Future<void> _blink(Map<String, dynamic> user) async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('blink');
    final resp = await callable.call(<String, dynamic>{
      'user': user,
      'me': FirebaseAuth.instance.currentUser!.uid,
    });
    if (resp.data == 'Success!') {
      setState(() {
        _containerColor = Colors.grey[600] ?? const Color(0xFFFFFFFF);
      });
    }
    Fluttertoast.showToast(msg: resp.data);
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
            'https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=${dotenv.env["WEB_API_KEY"]}'),
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
          msg: res.statusCode.toString() + ': Could not create link');
    }
  }

  Future<void> _accept() async {
    Navigator.pop(context);
    DocumentSnapshot<Map<String, dynamic>> sender =
        await FirebaseFirestore.instance.doc('links/$initialLink').get();
    FirebaseFirestore.instance
        .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
        .update({
      'permissions':
          FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
    });

    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('accept');
    final resp = await callable.call(<String, String>{
      'senderId': sender['senderId'],
      'friendId': FirebaseAuth.instance.currentUser!.uid,
      'friendName': FirebaseAuth.instance.currentUser!.displayName ?? ''
    });
    FirebaseFirestore.instance.doc('links/$initialLink').delete();
    Fluttertoast.showToast(msg: resp.data);
  }

  void _deny() {
    FirebaseFirestore.instance.doc('links/$initialLink').delete();
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (initialLink != null) {
        DocumentReference<Map<String, dynamic>> ref =
            FirebaseFirestore.instance.doc('links/$initialLink');
        DocumentSnapshot<Map<String, dynamic>> link = await ref.get();
        if (link['senderId'] == FirebaseAuth.instance.currentUser!.uid) {
          Fluttertoast.showToast(
              msg: 'You are can\'t be friends with yourself');
        }
        DocumentSnapshot<Map<String, dynamic>> perm = await FirebaseFirestore
            .instance
            .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
            .get();
        if (perm['permissions'].contains(link['senderId'])) {
          Fluttertoast.showToast(msg: 'You are already friends');
        } else {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('${link["senderName"]} want\'s to be your friend'),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 30)),
                        child: const Text('Accept'),
                        onPressed: () => {_accept()},
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(200, 30)),
                        child: const Text('Deny'),
                        onPressed: () => {_deny()},
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
        stream: _userStream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            List<Widget> tiles = snapshot.data['friends']
                .map((i) => GestureDetector(
                    onTap: () => {_blink(i)},
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(i['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: FaIcon(FontAwesomeIcons.lightbulb,
                                  color: Colors.white),
                            )
                          ],
                        ),
                      ),
                    )))
                .toList()
                .cast<Widget>();
            if (snapshot.data['friends'].length < 10) {
              tiles.add(GestureDetector(
                  onTap: () => {_createLink()},
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _containerColor,
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
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: FaIcon(FontAwesomeIcons.plus,
                                color: Colors.white),
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
