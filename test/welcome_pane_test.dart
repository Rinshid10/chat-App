import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/theme/app_theme.dart';
import 'package:chatapp/user_flow/widgets/welcome_pane.dart';

void main() {
  testWidgets('WelcomePane greets the user by name and fires chip actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var addTapped = 0;
    var lockTapped = 0;
    var themeTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WelcomePane(
            username: 'akbar',
            onAddContact: () => addTapped++,
            onAppLock: () => lockTapped++,
            onToggleTheme: () => themeTapped++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The greeting is one rich Text, so match on the combined string.
    expect(find.text('Welcome Back, akbar', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Add a contact'));
    await tester.tap(find.text('App lock'));
    await tester.tap(find.text('Switch theme'));
    await tester.pump();

    expect(addTapped, 1);
    expect(lockTapped, 1);
    expect(themeTapped, 1);
  });
}
