import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lalo/pages/subpages/friend.dart';
import 'package:lalo/pages/lalo_page.dart';
import 'package:lalo/pages/subpages/loading.dart';
import 'package:lalo/services/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget implements LaloPage {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();

  @override
  String get name => 'More';
}

class _MorePageState extends State<MorePage> {
  String? _version;
  String? _buildNumber;

  Uri get _hueAuthUrl => Uri(
    scheme: 'https',
    host: 'api.meethue.com',
    path: 'v2/oauth2/authorize',
    queryParameters: {
      'client_id': hueClientId,
      'response_type': 'code',
      'state': user!.uid,
    },
  );

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((value) {
      if (!mounted) return;
      setState(() {
        _version = value.version;
        _buildNumber = value.buildNumber;
      });
    });
  }

  Future<void> _connectHue(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    if (!await launchUrl(_hueAuthUrl)) {
      Fluttertoast.showToast(
        msg: 'Could not open the Philips Hue login',
        timeInSecForIosWeb: 3,
      );
    }
  }

  void _removeService(BuildContext sheetContext, String apiName) {
    userRef?.set({
      'api': {'name': 'No services connected', 'credentials': {}, 'lights': []},
      'light': {'name': 'Not selected', 'id': ''},
    }, SetOptions(merge: true));
    Fluttertoast.showToast(msg: 'Removed $apiName', timeInSecForIosWeb: 3);
    Navigator.pop(sheetContext);
  }

  /// Asks for the Home Assistant URL and a long-lived access token, then lets
  /// the `connectHomeAssistant` Cloud Function validate them and store the
  /// available lights.
  Future<void> _connectHomeAssistant(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    final urlController = TextEditingController();
    final tokenController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Connect Home Assistant'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your Home Assistant must be reachable from the '
                    'internet (e.g. Nabu Casa or your own domain). Create a '
                    'long-lived access token in your Home Assistant profile '
                    'under "Security".',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://example.duckdns.org:8123',
                    ),
                    validator: (text) {
                      final uri = Uri.tryParse(text?.trim() ?? '');
                      if (uri == null ||
                          !(uri.isScheme('http') || uri.isScheme('https')) ||
                          uri.host.isEmpty) {
                        return 'Enter a valid http(s) URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Long-lived access token',
                    ),
                    validator: (text) => (text == null || text.trim().isEmpty)
                        ? 'Enter your access token'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
    if (submitted != true) return;
    Fluttertoast.showToast(
      msg: 'Connecting to Home Assistant…',
      timeInSecForIosWeb: 3,
    );
    try {
      final resp = await FirebaseFunctions.instance
          .httpsCallable('connectHomeAssistant')
          .call(<String, String>{
            'url': urlController.text.trim(),
            'token': tokenController.text.trim(),
          });
      Fluttertoast.showToast(
        msg: resp.data ?? 'Connected to Home Assistant',
        timeInSecForIosWeb: 3,
      );
    } on FirebaseFunctionsException catch (e) {
      Fluttertoast.showToast(
        msg: e.message ?? 'Could not connect to Home Assistant',
        timeInSecForIosWeb: 3,
      );
    }
  }

  Widget _sheetButton(String caption, void Function() onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: const Size(280, 50)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(caption, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  void _showServiceSheet(String apiName) {
    final connected = apiName != 'No services connected';
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SizedBox(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Icon(Icons.lightbulb, color: Colors.orange, size: 40),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    connected
                        ? '$apiName is connected'
                        : 'Connect a service to let your friends blink your light',
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (connected)
                  _sheetButton(
                    'Remove $apiName',
                    () => _removeService(sheetContext, apiName),
                  )
                else ...[
                  _sheetButton(
                    'Connect Philips Hue',
                    () => _connectHue(sheetContext),
                  ),
                  _sheetButton(
                    'Connect Home Assistant',
                    () => _connectHomeAssistant(sheetContext),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLightSheet(List<dynamic> lights) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SizedBox(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      'Choose a Light to blink',
                      style: Theme.of(sheetContext).textTheme.headlineSmall,
                    ),
                  ),
                  for (final light in lights)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(200, 35),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        userRef?.set({'light': light}, SetOptions(merge: true));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          light['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(text, style: const TextStyle(color: Colors.orange)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: userRef?.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }
        final lightName = snapshot.data['light']['name'] ?? 'Not selected';
        final String apiName =
            snapshot.data['api']['name'] ?? 'No services connected';
        final connected = apiName != 'No services connected';
        final permissions = snapshot.data['permissions'] as List<dynamic>;

        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            _sectionTitle('Light'),
            SwitchListTile(
              secondary: const Icon(Icons.do_not_disturb),
              activeThumbColor: Colors.lightBlueAccent,
              value: snapshot.data['dnd'],
              onChanged: (value) {
                userRef?.update({'dnd': value});
              },
              title: const Text('Do Not Disturb'),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Services'),
              subtitle: Text(apiName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showServiceSheet(apiName),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Light'),
              subtitle: Text(lightName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (connected) {
                  _showLightSheet(snapshot.data['api']['lights']);
                } else {
                  Fluttertoast.showToast(
                    msg: 'No services connected',
                    timeInSecForIosWeb: 3,
                  );
                }
              },
            ),
            _sectionTitle('Accepted Requests'),
            ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: const Text('You\'re a friend of...'),
              subtitle: Text(
                permissions.isNotEmpty
                    ? permissions.map((i) => i['name']).join(', ')
                    : 'Nobody',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendPage()),
              ),
            ),
            _sectionTitle('App'),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              subtitle: const Text('Please provide your feedback'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/feedback'),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Info'),
              subtitle: Text('${_version ?? '…'}+${_buildNumber ?? ''}'),
            ),
          ],
        );
      },
    );
  }
}
