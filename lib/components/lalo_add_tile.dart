import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lalo/components/lalo_tile.dart';
import 'package:lalo/services/globals.dart';
import 'package:share_plus/share_plus.dart';

class LaloAddTile extends StatelessWidget {
  const LaloAddTile({Key? key}) : super(key: key);

  Future<void> _createLink() async {
    DocumentReference linkRef =
        FirebaseFirestore.instance.collection('links').doc();
    Share.share(
            'Be my friend at Leave a Light on: https://app.lalo.lighting?id=${linkRef.id}')
        .then((_) {
      linkRef.set({
        'senderId': user!.uid,
        'senderName': user!.displayName,
        'time': DateTime.now().toUtc().millisecondsSinceEpoch
      });
      analytics!.logShare(
          contentType: 'Friend Request', itemId: user!.uid, method: 'link');
    });
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
