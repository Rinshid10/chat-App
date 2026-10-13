import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/theme/app_theme.dart';
import 'package:chatapp/user_flow/screens/auth_screen.dart';

Widget _app() => MaterialApp(theme: AppTheme.dark(), home: const AuthScreen());

void main() {
  testWidgets('login panel shows brand, labeled fields and sign-up link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('ChatFlow'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Confirm Password'), findsNothing);
  });

  testWidgets('sign-up panel requires matching passwords', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth_username')), 'akbar');
    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'akbar@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth_password')), 'secret12');
    await tester.enterText(find.byKey(const Key('auth_confirm')), 'secret99');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('desktop login is a split screen with a brand panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Brand panel on the left.
    expect(find.text('Chat with anyone, anywhere.'), findsOneWidget);
    expect(find.text('Voice calls'), findsOneWidget);
    expect(find.text('App lock'), findsOneWidget);
    // Form on the right with its own heading.
    expect(find.text('Welcome back'), findsOneWidget);

    final brand = tester.getCenter(find.text('Chat with anyone, anywhere.'));
    final form = tester.getCenter(find.byKey(const Key('auth_email')));
    expect(brand.dx, lessThan(700));
    expect(form.dx, greaterThan(700));
  });

  testWidgets('phone login keeps the single card without a brand panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('ChatFlow'), findsOneWidget);
    expect(find.text('Voice calls'), findsNothing);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Log In'), findsOneWidget);
  });
}
