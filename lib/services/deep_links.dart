import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Id of a pending friend-request link (`links/{id}` in Firestore).
///
/// Invite links look like `https://app.lalo.lighting/?id=<linkId>`. On Android
/// they arrive as App Links via the `app_links` plugin, on the web the id is
/// read from the launch URL. `HomePage` listens to this notifier and shows the
/// accept/deny modal once the user is ready (signed in, light selected).
final ValueNotifier<String?> pendingLink = ValueNotifier(null);

Future<void> initDeepLinks() async {
  if (kIsWeb) {
    _handleUri(Uri.base);
    return;
  }
  // The stream also emits the link the app was launched with.
  AppLinks().uriLinkStream.listen(_handleUri);
}

void _handleUri(Uri uri) {
  final id = uri.queryParameters['id'];
  if (id != null && id.isNotEmpty) {
    pendingLink.value = id;
  }
}
