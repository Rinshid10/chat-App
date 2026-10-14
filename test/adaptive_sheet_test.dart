import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatapp/widgets/confirmation_sheet.dart';

Widget _host(void Function(BuildContext) onTap) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('confirmation opens as centered Dialog on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _host((context) {
        showConfirmationSheet<bool>(
          context: context,
          title: 'Delete?',
          message: 'Sure?',
          confirmText: 'Delete',
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Delete?'), findsOneWidget);
  });

  testWidgets('confirmation opens as bottom sheet on phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _host((context) {
        showConfirmationSheet<bool>(
          context: context,
          title: 'Delete?',
          message: 'Sure?',
          confirmText: 'Delete',
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('input sheet opens as Dialog on desktop and returns text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? result;
    await tester.pumpWidget(
      _host((context) async {
        result = await showInputSheet(
          context: context,
          title: 'Edit Message',
          initialValue: 'hello',
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 'hello');
  });
}
