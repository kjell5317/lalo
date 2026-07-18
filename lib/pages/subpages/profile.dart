import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lalo/services/theme.dart';
import 'package:lalo/services/toast.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// The provider the user signed in with. Only used for a read-only label —
  /// we deliberately don't offer linking additional sign-in methods.
  String _providerId(User user) => user.providerData.isNotEmpty
      ? user.providerData.first.providerId
      : 'unknown';

  String _providerLabel(User user) {
    switch (_providerId(user)) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email & password';
      default:
        return _providerId(user);
    }
  }

  IconData _providerIcon(User user) =>
      _providerId(user) == 'google.com' ? Icons.g_mobiledata : Icons.mail_outline;

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    // The auth-state StreamBuilder in [App] rebuilds the home (first) route
    // into the login screen on sign-out. Popping back to it reveals that,
    // instead of pushing a fresh App() while the tree is being torn down —
    // which is what crashed the old ProfileScreen action.
    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and connected light, and '
          'removes you from your friends\' lists. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    showAppToast('Deleting your account…');
    try {
      // The Cloud Function removes all Firestore references and deletes the
      // auth user with admin rights — no reauth needed, and no orphaned data.
      await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
      await FirebaseAuth.instance.signOut();
      navigator.popUntil((route) => route.isFirst);
      showAppToast('Your account has been deleted');
    } on FirebaseFunctionsException catch (e) {
      showAppToast(e.message ?? 'Could not delete your account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Signed out from under us for a frame before the pop lands.
      return const Scaffold(body: SizedBox.shrink());
    }
    final theme = Theme.of(context);
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'You';
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: brandOrange,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user.email!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(_providerIcon(user), color: brandOrange),
                  title: const Text('Signed in with'),
                  subtitle: Text(_providerLabel(user)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text('Sign out', style: TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _deleteAccount(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
