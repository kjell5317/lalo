import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Id of a pending friend-request link (`links/{id}` in Firestore).
///
/// Invite links look like `https://app.lalo.lighting/?id=<linkId>`. On Android
/// they arrive as App Links via the `app_links` plugin, on the web the id is
/// read from the launch URL. `HomePage` listens to this notifier and shows the
/// accept/deny modal once the user is ready (signed in, light selected).
final ValueNotifier<String?> pendingLink = ValueNotifier(null);

/// Link id the user has already been asked to pick a light for. Kept at module
/// scope (not in `HomePage`'s state) so the "select a light" prompt survives a
/// rebuild/remount and is shown once per link instead of on every tab switch.
String? lightPromptShownFor;

Future<void> initDeepLinks() async {
  if (kIsWeb) {
    _handleUri(Uri.base);
    return;
  }
  final appLinks = AppLinks();
  // The launch link must be fetched explicitly — subscribing to the stream
  // alone can miss it if the native side delivers it before Dart listens.
  final initial = await appLinks.getInitialLink();
  if (initial != null) _handleUri(initial);
  appLinks.uriLinkStream.listen(_handleUri);
}

void _handleUri(Uri uri) {
  final id = uri.queryParameters['id'];
  if (id != null && id.isNotEmpty) {
    pendingLink.value = id;
  }
}
