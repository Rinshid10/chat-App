import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/theme/app_theme.dart';
import 'package:chatapp/widgets/depth.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('DepthSurface fires onTap and presses down while held', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        DepthSurface(
          onTap: () => taps++,
          child: const SizedBox(key: Key('box'), width: 120, height: 48),
        ),
      ),
    );

    final restingTop = tester.getTopLeft(find.byKey(const Key('box'))).dy;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('box'))),
    );
    // One frame for the tap-down to register, one for the animation to run.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    final pressedTop = tester.getTopLeft(find.byKey(const Key('box'))).dy;
    expect(pressedTop, greaterThan(restingTop));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.getTopLeft(find.byKey(const Key('box'))).dy, restingTop);
  });

  testWidgets('DepthSurface lifts on hover when hoverLift is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DepthSurface(
          hoverLift: true,
          onTap: () {},
          child: const SizedBox(key: Key('box'), width: 120, height: 48),
        ),
      ),
    );

    final restingTop = tester.getTopLeft(find.byKey(const Key('box'))).dy;

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('box'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester.getTopLeft(find.byKey(const Key('box'))).dy,
      lessThan(restingTop),
    );
  });

  testWidgets('DepthButton shows its label and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(DepthButton(onPressed: () => taps++, child: const Text('Go'))),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('TiltCard applies a perspective transform under the mouse', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TiltCard(
          child: SizedBox(key: Key('card'), width: 300, height: 200),
        ),
      ),
    );

    Matrix4 transformOf() {
      final t = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byKey(const Key('card')),
              matching: find.byType(Transform),
            )
            .first,
      );
      return t.transform;
    }

    expect(transformOf().isIdentity(), isTrue);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final rect = tester.getRect(find.byKey(const Key('card')));
    await mouse.moveTo(Offset(rect.left + 20, rect.top + 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(transformOf().isIdentity(), isFalse);
  });
}
