import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:lalo/pages/loading.dart';
import 'package:lalo/services/globals.dart';
import 'package:settings_ui/settings_ui.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({Key? key}) : super(key: key);

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: userRef?.snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
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
                          user!.displayName?.substring(0, 2).toUpperCase() ??
                              'HI',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SettingsList(
                        contentPadding: const EdgeInsets.all(10),
                        lightTheme: SettingsThemeData(
                            settingsListBackground:
                                Theme.of(context).scaffoldBackgroundColor),
                        darkTheme: SettingsThemeData(
                            settingsListBackground: Colors.grey[900]),
                        sections: [
                          SettingsSection(
                              tiles: snapshot.data['permissions']
                                  .map((i) {
                                    Color pickerColor = fromHex(i['color']);
                                    void changeColor(Color color) {
                                      setState(() => pickerColor = color);
                                    }

                                    return SettingsTile.navigation(
                                      title: Text(i['name']),
                                      value: const Text(
                                          'Tap to remove this friend'),
                                      leading: const Icon(
                                        Icons.account_circle_outlined,
                                      ),
                                      onPressed: (context) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    'Do you want to remove ${i["name"]}?'),
                                                actions: [
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              userRef?.update({
                                                                'permissions':
                                                                    FieldValue
                                                                        .arrayRemove(
                                                                            [i])
                                                              });
                                                            },
                                                            child:
                                                                const Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(8.0),
                                                              child:
                                                                  Text('Yes'),
                                                            )),
                                                        TextButton(
                                                            onPressed: (() =>
                                                                Navigator.pop(
                                                                    context)),
                                                            child: const Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child:
                                                                    Text('No')))
                                                      ])
                                                ],
                                              );
                                            });
                                      },
                                      trailing: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Builder(builder: (context) {
                                          if (snapshot.data['light']['color']) {
                                            return GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              'Pick a color!'),
                                                          content:
                                                              SingleChildScrollView(
                                                            child: BlockPicker(
                                                              availableColors: const [
                                                                Colors.white,
                                                                Colors.yellow,
                                                                Colors.orange,
                                                                Colors.red,
                                                                Colors.pink,
                                                                Colors.purple,
                                                                Colors.blue,
                                                                Colors
                                                                    .lightBlue,
                                                                Colors.green,
                                                                Colors
                                                                    .lightGreen,
                                                              ],
                                                              pickerColor:
                                                                  pickerColor,
                                                              onColorChanged:
                                                                  changeColor,
                                                            ),
                                                          ),
                                                          actions: <Widget>[
                                                            ElevatedButton(
                                                              child:
                                                                  const Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            8.0),
                                                                child:
                                                                    Text('OK'),
                                                              ),
                                                              onPressed: () {
                                                                userRef!
                                                                    .update({
                                                                  'permissions':
                                                                      FieldValue
                                                                          .arrayRemove([
                                                                    i
                                                                  ])
                                                                });
                                                                userRef!
                                                                    .update({
                                                                  'permissions':
                                                                      FieldValue
                                                                          .arrayUnion([
                                                                    {
                                                                      'name': i[
                                                                          'name'],
                                                                      'uid': i[
                                                                          'uid'],
                                                                      'color': pickerColor
                                                                          .value
                                                                          .toRadixString(
                                                                              16)
                                                                          .substring(
                                                                              2)
                                                                    }
                                                                  ])
                                                                });
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      });
                                                },
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        width: 1.5,
                                                        color:
                                                            Colors.grey[400] ??
                                                                Colors.black),
                                                    shape: BoxShape.circle,
                                                    color: fromHex(i['color']),
                                                  ),
                                                ));
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        }),
                                      ),
                                    );
                                  })
                                  .toList()
                                  .cast<AbstractSettingsTile>())
                        ]),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                          'Here are all the friends who\'s requests you accepted!\nYou can remove them or change the color in which they blink your light',
                          textAlign: TextAlign.center),
                    ),
                  )
                ],
              ),
            );
          } else {
            return const LoadingScreen();
          }
        });
  }
}
