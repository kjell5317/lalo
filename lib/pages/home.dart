import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lalo/components/lalo_add_tile.dart';
import 'package:lalo/components/lalo_tile.dart';
import 'package:lalo/pages/lalo_page.dart';
import 'package:lalo/pages/subpages/loading.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lalo/services/services.dart';

/// When each friend's light was last blinked (friend uid -> time). Kept at
/// module scope so the 30 s cooldown survives the HomePage being remounted
/// when the user switches tabs (like [lightPromptShownFor]) — instance state
/// would be lost on remount and the tile would wrongly re-enable early.
final Map<String, DateTime> _lastBlinked = {};

/// How long a tile stays disabled after a blink — mirrors the server-side
/// rate limit the `blink` function enforces via `light.last`.
const Duration _blinkCooldown = Duration(seconds: 30);

/// Tile background while a friend is on cooldown: a muted grey so the tile
/// reads clearly as temporarily disabled.
final Color _cooldownColor = Colors.lightBlueAccent;

class HomePage extends StatefulWidget implements LaloPage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  @override
  String get name => 'Home';
}

class _HomePageState extends State<HomePage> {
  // uids that already have a pending re-enable timer, so [_scheduleCooldownEnd]
  // doesn't stack duplicate timers across rebuilds.
  final Set<String> _cooldownTimers = {};
  bool _handlingLink = false;

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

  void _toast(String msg) => showAppToast(msg);

  /// Validates the pending friend-request link and shows the accept/deny
  /// modal. If no light is selected yet the link stays pending and this is
  /// retried once the user document shows a selected light.
  Future<void> _handlePendingLink() async {
    final link = pendingLink.value;
    if (link == null || _handlingLink) return;
    _handlingLink = true;
    try {
      final linkDoc = await FirebaseFirestore.instance.doc('links/$link').get();
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
        // Prompt once per link, tracked at module scope so a rebuild/remount
        // (e.g. switching tabs) doesn't re-show the toast.
        if (lightPromptShownFor != link) {
          lightPromptShownFor = link;
          _toast('Select a light before you can accept the request');
        }
        return;
      }
      lightPromptShownFor = null;
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

  bool _isCooling(String uid) {
    final last = _lastBlinked[uid];
    return last != null && DateTime.now().difference(last) < _blinkCooldown;
  }

  /// Schedules a single rebuild for when [uid]'s cooldown ends so the tile
  /// re-enables on its own — including after a remount, where the timer from
  /// the previous State was lost but [_lastBlinked] survived.
  void _scheduleCooldownEnd(String uid) {
    final last = _lastBlinked[uid];
    if (last == null) return;
    final remaining = _blinkCooldown - DateTime.now().difference(last);
    if (remaining <= Duration.zero || !_cooldownTimers.add(uid)) return;
    Future.delayed(remaining, () {
      _cooldownTimers.remove(uid);
      if (mounted) setState(() {});
    });
  }

  Future<void> _blink(Map<String, dynamic> friend) async {
    final uid = friend['uid'] as String;
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
      // The blink didn't happen (error/status message), so lift the cooldown.
      setState(() => _lastBlinked.remove(uid));
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
        // Once a link is pending and a light has been selected (possibly just
        // now, on the More tab), re-run handling to show the accept modal.
        if (pendingLink.value != null &&
            snapshot.data['light']['name'] != 'Not selected') {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handlePendingLink(),
          );
        }
        final dnd = snapshot.data['dnd'] == true;
        List<Widget> tiles = snapshot.data['friends']
            .map((i) {
              final String uid = i['uid'];
              // The cooldown comes from [_lastBlinked] (module scope, so it
              // survives a tab-switch remount); Do Not Disturb is a render-time
              // overlay so toggling DND off restores the tiles right away.
              final cooling = _isCooling(uid);
              if (cooling) _scheduleCooldownEnd(uid);
              return LaloTile(
                color: dnd
                    ? Colors.lightBlueAccent
                    : cooling
                    ? _cooldownColor
                    : Colors.orange,
                text: i['name'],
                icon: Icons.lightbulb,
                onTap: () {
                  if (dnd) {
                    _toast('Switch off Do Not Disturb mode');
                  } else if (cooling) {
                    _toast('Please wait at least 30 seconds');
                  } else {
                    setState(() => _lastBlinked[uid] = DateTime.now());
                    _scheduleCooldownEnd(uid);
                    _blink(i);
                  }
                },
              );
            })
            .toList()
            .cast<Widget>();
        if (snapshot.data['friends'].length < 10) {
          tiles.add(const LaloAddTile());
        }
        return GridView(
          primary: false,
          padding: const EdgeInsets.all(20),
          // Scales from 2 columns on phones to more on large screens.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          children: tiles,
        );
      },
    );
  }
}
