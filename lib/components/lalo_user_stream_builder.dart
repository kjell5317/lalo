import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lalo/pages/subpages/loading.dart';
import 'package:lalo/pages/subpages/name.dart';
import 'package:lalo/services/globals.dart';

class LaloUserStreamBuilder extends StatelessWidget {
  const LaloUserStreamBuilder({Key? key, required this.widget})
      : super(key: key);
  final Widget widget;

  void setInitialData() {
    analytics!.logSignUp(signUpMethod: user!.providerData[0].providerId);
    userRef?.set({
      'light': {'name': 'Not selected', 'id': '', 'last': 0, 'color': false},
      'api': {'name': 'No services connected'},
      'friends': [],
      'permissions': [],
      'dnd': false,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: userRef?.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshotDb) {
          if (!snapshotDb.hasData) {
            return const LoadingScreen();
          }
          if (!snapshotDb.data!.exists) {
            setInitialData();
            return const LoadingScreen();
          }
          if (user?.displayName == null) {
            return const NamePage();
          }
          return widget;
        });
  }
}
