import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/pages/loading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  Future<void> _blink(String uid) async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('blink');
    final resp = await callable.call(<String, String>{
      'uid': uid,
      'me': FirebaseAuth.instance.currentUser!.uid,
    });
<<<<<<< HEAD
    if (resp.data == 'Success!') {
=======
    if (resp.data == 'ok') {
>>>>>>> 28cbac9384f5c235d943a6f705f6a519ee310d6a
      setState(() {
        _containerColor = Colors.grey[600] ?? const Color(0xFFFFFFFF);
      });
    }
    Fluttertoast.showToast(msg: resp.data);
  }

  Future<void> _createLink() async {
<<<<<<< HEAD
    DocumentReference ref =
        FirebaseFirestore.instance.collection('links').doc();
    var body = {
      'dynamicLinkInfo': {
        'domainUriPrefix': 'https://app-lalo.tk/link',
        'link': 'https://lalo-2605.web.app/${ref.id}',
        'androidInfo': {'androidPackageName': 'de.kjellhanken.lalo'},
        'suffix': {'option': 'UNGUESSABLE'}
      }
    };
    var res = await http.post(
        Uri.parse(
            'https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=${dotenv.env["WEB_API_KEY"]}'),
        body: body);
    if (res.statusCode == 200) {
      Share.share(res.body).then((_) => {
            ref.set({
              'senderId': FirebaseAuth.instance.currentUser!.uid,
              'senderName': FirebaseAuth.instance.currentUser!.displayName
            })
          });
    } else {
      Fluttertoast.showToast(
          msg: res.statusCode.toString() + ': Could not create link');
    }
=======
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse('https://lalo-2605.web.app/' +
          FirebaseAuth.instance.currentUser!.uid),
      uriPrefix: 'https://app-lalo.tk/link',
      androidParameters:
          const AndroidParameters(packageName: 'de.kjellhanken.lalo'),
    );
    final link = await FirebaseDynamicLinks.instance.buildShortLink(
        dynamicLinkParams,
        shortLinkType: ShortDynamicLinkType.unguessable);
    ShareResult result = await Share.shareWithResult(link.toString());
    Fluttertoast.showToast(msg: result.toString());
>>>>>>> 28cbac9384f5c235d943a6f705f6a519ee310d6a
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
        stream: _userStream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data['friends'].length < 1) {
              return GridView.count(
                  primary: false,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                  children: <Widget>[
                    // TODO: add visual feedback
                    GestureDetector(
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
                                    'Add your first friend',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white),
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
                        ))
                  ]);
            } else {
              return GridView.count(
                  primary: false,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                  children: snapshot.data['friends']
                      .map((i) => GestureDetector(
                          onTap: () => {_blink(i['uid'])},
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
                      .cast<Widget>());
            }
          }
          return const LoadingScreen();
        });
  }
}
