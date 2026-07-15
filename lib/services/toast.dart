import 'package:flutter/material.dart';
import 'package:lalo/services/theme.dart';

/// App-wide messenger key so toasts can be shown from anywhere — including
/// after an `await` — without needing a live [BuildContext].
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Shows a branded, app-styled toast: a floating [SnackBar] in the brand
/// color with the lightbulb glyph and white text, matching the tiles and
/// sheets. Any toast already on screen is replaced so messages don't queue.
void showAppToast(String message) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: brandOrange,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ),
  );
}
