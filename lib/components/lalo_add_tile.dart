import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/components/lalo_tile.dart';
import 'package:lalo/services/globals.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class LaloAddTile extends StatelessWidget {
  const LaloAddTile({Key? key}) : super(key: key);

  Future<void> _createLink() async {
    DocumentReference linkRef =
        FirebaseFirestore.instance.collection('links').doc();
    var body = {
      'dynamicLinkInfo': {
        'domainUriPrefix': 'https://link.$domain',
        'link': 'https://app.$domain/?id=${linkRef.id}',
        'androidInfo': {'androidPackageName': 'de.kjellhanken.lalo'},
      },
      'suffix': {'option': 'UNGUESSABLE'}
    };
    var res = await http.post(
        Uri.parse(
            'https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyAUKHRQtdn_rxwt4wGRzzMHVqrDLJSKND0'),
        body: jsonEncode(body));
    if (res.statusCode == 200) {
      Share.share(
              'Be my friend at Leave a Light on: ${jsonDecode(res.body)["shortLink"]}')
          .then((_) {
        linkRef.set({
          'senderId': user!.uid,
          'senderName': user!.displayName,
          'time': DateTime.now().toUtc().millisecondsSinceEpoch
        });
        analytics!.logShare(
            contentType: 'Friend Request', itemId: user!.uid, method: 'link');
      });
    } else {
      Fluttertoast.showToast(
          msg: '${res.statusCode}: Could not create link',
          timeInSecForIosWeb: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LaloTile(
        onTap: _createLink,
        color: Colors.grey[400]!,
        text: 'Add a friend',
        icon: Icons.add);
  }
}
