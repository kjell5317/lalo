import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:lalo/pages/subpages/loading.dart';
import 'package:lalo/services/globals.dart';

class FriendPage extends StatelessWidget {
  const FriendPage({super.key});

  static Color _fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _toHex(Color color) =>
      color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);

  void _confirmRemove(BuildContext context, Map<String, dynamic> permission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Do you want to remove ${permission["name"]}?'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    userRef?.update({
                      'permissions': FieldValue.arrayRemove([permission]),
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Yes'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _pickColor(
    BuildContext context,
    Map<String, dynamic> permission,
  ) {
    Color pickerColor = _fromHex(permission['color']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: BlockPicker(
              layoutBuilder:
                  (BuildContext context, List<Color> colors, PickerItem child) {
                    final portrait =
                        MediaQuery.of(context).orientation ==
                        Orientation.portrait;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      width: 300,
                      height: portrait ? 360 : 200,
                      child: GridView.count(
                        crossAxisCount: portrait ? 4 : 6,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        children: [for (Color color in colors) child(color)],
                      ),
                    );
                  },
              availableColors: const [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.white,
              ],
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('OK'),
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                // Read-modify-write in a transaction so a concurrent change
                // to `permissions` (e.g. a newly accepted friend) is not
                // clobbered by writing back a stale array.
                await FirebaseFirestore.instance.runTransaction((tx) async {
                  final snap = await tx.get(userRef!);
                  final current = (snap.get('permissions') as List)
                      .map((p) => Map<String, dynamic>.from(p as Map))
                      .toList();
                  final updated = current
                      .map(
                        (p) => p['uid'] == permission['uid']
                            ? {...p, 'color': _toHex(pickerColor)}
                            : p,
                      )
                      .toList();
                  tx.update(userRef!, {'permissions': updated});
                });
                navigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: userRef?.snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }
        final permissions = snapshot.data['permissions'] as List<dynamic>;
        final hasColorLight = snapshot.data['light']['color'] == true;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Friends'),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[400],
                    child: Text(
                      user!.displayName?.substring(0, 2).toUpperCase() ?? 'HI',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        for (final permission in permissions)
                          ListTile(
                            leading: const Icon(Icons.account_circle_outlined),
                            title: Text(permission['name']),
                            subtitle: const Text('Tap to remove this friend'),
                            onTap: () => _confirmRemove(
                              context,
                              Map<String, dynamic>.from(permission),
                            ),
                            trailing: hasColorLight
                                ? GestureDetector(
                                    onTap: () => _pickColor(
                                      context,
                                      Map<String, dynamic>.from(permission),
                                    ),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.5,
                                          color:
                                              Colors.grey[400] ?? Colors.black,
                                        ),
                                        shape: BoxShape.circle,
                                        color: _fromHex(permission['color']),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      'Here are all the friends who\'s requests you accepted!\nYou can remove them or change the color in which they blink your light',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
