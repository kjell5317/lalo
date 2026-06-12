import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/components/lalo_add_tile.dart';
import 'package:lalo/components/lalo_tile.dart';
import 'package:lalo/pages/lalo_page.dart';
import 'package:lalo/pages/subpages/loading.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lalo/services/services.dart';

class HomePage extends StatefulWidget implements LaloPage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  @override
  String get name => 'Home';
}

class _HomePageState extends State<HomePage> {
  final Map<String, Color> _color = {};
  bool _handlingLink = false;
  bool _waitingForLight = false;

  @override
  void initState() {
    super.initState();
    pendingLink.addListener(_handlePendingLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingLink());
  }

  @override
  void dispose() {
    pendingLink.removeListener(_handlePendingLink);
    super.dispose();
  }

  void _toast(String msg) {
    Fluttertoast.showToast(msg: msg, timeInSecForIosWeb: 3);
  }

  /// Validates the pending friend-request link and shows the accept/deny
  /// modal. If no light is selected yet the link stays pending and this is
  /// retried once the user document shows a selected light.
  Future<void> _handlePendingLink() async {
    final link = pendingLink.value;
    if (link == null || _handlingLink) return;
    _handlingLink = true;
    try {
      final linkDoc = await FirebaseFirestore.instance
          .doc('links/$link')
          .get();
      if (!mounted) return;
      if (!linkDoc.exists) {
        pendingLink.value = null;
        _toast('Invalid link');
        return;
      }
      final linkData = linkDoc.data()!;
      if (linkData['senderId'] == user!.uid) {
        pendingLink.value = null;
        _toast('You can\'t be friends with yourself');
        return;
      }
      final me = await userRef!.get();
      if (!mounted) return;
      final alreadyFriends = (me['permissions'] as List).any(
        (p) => p['uid'] == linkData['senderId'],
      );
      if (alreadyFriends) {
        await linkDoc.reference.delete();
        pendingLink.value = null;
        _toast('You are already friends');
        return;
      }
      if (me['light']['name'] == 'Not selected') {
        if (!_waitingForLight) {
          _waitingForLight = true;
          _toast('Select a light before you can accept the request');
        }
        return;
      }
      _waitingForLight = false;
      pendingLink.value = null;
      _showRequestModal(link, linkData);
    } finally {
      _handlingLink = false;
    }
  }

  Future<void> _accept(String link, Map<String, dynamic> linkData) async {
    Navigator.pop(context);
    await userRef!.update({
      'permissions': FieldValue.arrayUnion([
        {
          'uid': linkData['senderId'],
          'name': linkData['senderName'],
          'color': 'FFFFFF',
        },
      ]),
    });
    final resp = await FirebaseFunctions.instance
        .httpsCallable('accept')
        .call(<String, String>{
          'senderId': linkData['senderId'],
          'friendId': user!.uid,
          'friendName': user!.displayName ?? '',
        });
    await FirebaseFirestore.instance.doc('links/$link').delete();
    _toast(resp.data);
  }

  void _showRequestModal(String link, Map<String, dynamic> linkData) {
    showModalBottomSheet<void>(
      isDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 15.0, bottom: 5.0),
                  child: Icon(
                    Icons.group_add,
                    color: Colors.orange,
                    size: 40.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text(
                        'Friend Request',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'from ${linkData["senderName"]}',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(200, 40),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Accept', style: TextStyle(fontSize: 18)),
                          Icon(Icons.check),
                        ],
                      ),
                    ),
                    onPressed: () {
                      _accept(link, linkData);
                    },
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(200, 40),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Deny', style: TextStyle(fontSize: 18)),
                        Icon(Icons.close),
                      ],
                    ),
                  ),
                  onPressed: () {
                    FirebaseFirestore.instance.doc('links/$link').delete();
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
    if (!mounted) return;
    setState(() {
      _color[uid] = Colors.orange;
    });
  }

  Future<void> _blink(Map<String, dynamic> friend) async {
    var resp = await FirebaseFunctions.instance.httpsCallable('blink').call(
      <String, String>{
        'userId': friend['uid'],
        'userName': friend['name'],
        'me': user!.uid,
      },
    );
    if (resp.data != null) {
      _toast(resp.data);
      if (!mounted) return;
      setState(() {
        _color[friend['uid']] = Colors.orange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: userRef?.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }
        if (_waitingForLight &&
            pendingLink.value != null &&
            snapshot.data['light']['name'] != 'Not selected') {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handlePendingLink(),
          );
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
              return LaloTile(
                color: _color[i['uid']]!,
                text: i['name'],
                icon: Icons.lightbulb,
                onTap: () {
                  if (_color[i['uid']] == Colors.orange) {
                    _changeColor(i['uid']);
                    _blink(i);
                  } else if (snapshot.data['dnd']) {
                    _toast('Switch off Do Not Disturb mode');
                  } else {
                    _toast('Please wait at least 30 seconds');
                  }
                },
              );
            })
            .toList()
            .cast<Widget>();
        if (snapshot.data['friends'].length < 10) {
          tiles.add(const LaloAddTile());
        }
        return GridView.count(
          primary: false,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          crossAxisCount: 2,
          children: tiles,
        );
      },
    );
  }
}
