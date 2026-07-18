import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lalo/components/lalo_app_bar.dart';
import 'package:lalo/services/globals.dart' as globals;

class _FakeUser implements User {
  @override
  String? get displayName => 'Test User';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    globals.user = _FakeUser();
  });

  tearDown(() {
    globals.user = null;
  });

  testWidgets('does not infer a back button when another route is below it', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('route below')),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(appBar: LaloAppBar(name: 'Home')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
