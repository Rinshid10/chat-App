import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/models/message.dart';
import 'package:chatapp/user_flow/widgets/message_bubble.dart';

void main() {
  testWidgets('bubble width is capped on a wide layout', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final message = Message(
      id: '1',
      username: 'alice',
      text: 'word ' * 200,
      timestamp: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [MessageBubble(message: message, isMe: false, index: 0)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bubbleText = find.text(message.text);
    final width = tester.getSize(bubbleText).width;
    expect(width, lessThanOrEqualTo(MessageBubble.maxBubbleWidth));
  });
}
