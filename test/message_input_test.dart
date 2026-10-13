import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/theme/app_theme.dart';
import 'package:chatapp/user_flow/widgets/message_input.dart';

void main() {
  testWidgets('message bar shows plus, attach and send controls when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: Column(children: [MessageInput()])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    expect(find.byIcon(Icons.emoji_emotions_outlined), findsNothing);

    // The send button stays laid out (not scaled away) so the bar keeps a
    // stable shape; it is only dimmed while there is nothing to send.
    final sendOpacity = tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byIcon(Icons.send_rounded),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(sendOpacity.opacity, lessThan(1.0));
  });
}
