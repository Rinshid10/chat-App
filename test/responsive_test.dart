import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/utils/responsive.dart';

Widget _app(Size size, Widget child) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('isDesktopLayout is true at 1200px and false at 400px', (
    tester,
  ) async {
    bool? wide;
    bool? narrow;

    await tester.pumpWidget(
      _app(
        const Size(1200, 800),
        Builder(
          builder: (context) {
            wide = isDesktopLayout(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      _app(
        const Size(400, 800),
        Builder(
          builder: (context) {
            narrow = isDesktopLayout(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(wide, isTrue);
    expect(narrow, isFalse);
  });

  testWidgets('ResponsiveFormCard caps child width on desktop', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveFormCard(
            child: SizedBox(
              key: Key("form"),
              width: double.infinity,
              height: 100,
            ),
          ),
        ),
      ),
    );

    final width = tester.getSize(find.byKey(const Key('form'))).width;
    expect(width, lessThanOrEqualTo(ResponsiveFormCard.maxWidth));
    expect(width, greaterThan(300));
  });

  testWidgets('ResponsiveFormCard lets child fill width on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveFormCard(
            child: SizedBox(
              key: Key("form"),
              width: double.infinity,
              height: 100,
            ),
          ),
        ),
      ),
    );

    final width = tester.getSize(find.byKey(const Key('form'))).width;
    expect(width, 390);
  });
}
