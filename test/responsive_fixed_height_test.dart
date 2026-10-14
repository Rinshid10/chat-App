import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/utils/responsive.dart';

void main() {
  testWidgets(
    'ResponsiveFormCard with fixedHeight gives Spacer-based children a bounded height on desktop',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveFormCard(
              fixedHeight: 600,
              child: Column(
                children: [
                  Spacer(),
                  SizedBox(key: Key('pad'), width: 200, height: 100),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final card = find.byKey(const Key('pad'));
      expect(card, findsOneWidget);
      final bottom = tester.getBottomLeft(card).dy;
      // Centered 600px card on a 900px window ends at 750 (150 + 600), minus
      // the card's own padding.
      expect(bottom, closeTo(750 - 32, 1));
    },
  );

  testWidgets('ResponsiveFormCard with fixedHeight is pass-through on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveFormCard(
            fixedHeight: 600,
            child: Column(
              children: [
                Spacer(),
                SizedBox(key: Key('pad'), width: 200, height: 100),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getBottomLeft(find.byKey(const Key('pad'))).dy, 844);
  });
}
