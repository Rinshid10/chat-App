import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/models/message.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/theme/app_theme.dart';
import 'package:chatapp/user_flow/widgets/message_bubble.dart';

void main() {
  final message = Message(
    id: '1',
    username: 'me',
    text: 'hello there',
    timestamp: DateTime(2026, 1, 1),
  );

  testWidgets('sent bubble uses the accent color with white text (light)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ListView(
            children: [MessageBubble(message: message, isMe: true, index: 0)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MessageBubble));
    final scheme = Theme.of(context).colorScheme;
    expect(scheme.sentBubble, scheme.primary);

    final text = tester.widget<Text>(find.text(message.text));
    expect(text.style?.color, scheme.onSentBubble);
    expect(scheme.onSentBubble, const Color(0xFFFFFFFF));
  });

  testWidgets('sent bubble uses the accent color with white text (dark)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: ListView(
            children: [MessageBubble(message: message, isMe: true, index: 0)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MessageBubble));
    final scheme = Theme.of(context).colorScheme;
    expect(scheme.sentBubble, scheme.primary);

    final text = tester.widget<Text>(find.text(message.text));
    expect(text.style?.color, scheme.onSentBubble);
  });

  test('light and dark themes share a blue accent and flat elevation', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    // Blue accent: more blue than red or green in both modes.
    for (final scheme in [light.colorScheme, dark.colorScheme]) {
      final p = scheme.primary;
      expect(p.b, greaterThan(p.r));
      expect(p.b, greaterThan(p.g));
    }

    // Cards draw their own depth; Material buttons are raised by the theme.
    expect(light.cardTheme.elevation, 0);
    expect(dark.cardTheme.elevation, 0);
    expect(light.floatingActionButtonTheme.elevation, greaterThan(0));
    expect(dark.floatingActionButtonTheme.elevation, greaterThan(0));
  });
}
