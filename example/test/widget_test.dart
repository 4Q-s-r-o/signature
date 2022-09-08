// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Test clear works on PNG', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(
      find.byKey(const Key('snackbarPNG')),
      findsNothing,
    );

    // Tap on the signature pad
    await tester.tap(find.byKey(const Key('signature')));
    await tester.pump();

    // Tap on the clear button
    await tester.tap(find.byKey(const Key('clear')));
    await tester.pump();

    // Tap on the export button
    await tester.tap(find.byKey(const Key('exportPNG')));
    await tester.pump();

    expect(
      find.byKey(const Key('snackbarPNG')),
      findsOneWidget,
    );
  });

  testWidgets('Test clear works on SVG', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(
      find.byKey(const Key('snackbarSVG')),
      findsNothing,
    );

    // Tap on the signature pad
    await tester.tap(find.byKey(const Key('signature')));
    await tester.pump();

    // Tap on the clear button
    await tester.tap(find.byKey(const Key('clear')));
    await tester.pump();

    // Tap on the export button
    await tester.tap(find.byKey(const Key('exportSVG')));
    await tester.pump();

    expect(
      find.byKey(const Key('snackbarSVG')),
      findsOneWidget,
    );
  });

  testWidgets('Test export to PNG works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(
      find.byKey(const Key('snackbarPNG')),
      findsNothing,
    );

    // Tap on the signature pad
    await tester.tap(find.byKey(const Key('signature')));
    await tester.pump();

    // Tap on the export button
    await tester.tap(find.byKey(const Key('exportPNG')));
    await tester.pump();

    expect(
      find.byKey(const Key('snackbarPNG')),
      findsNothing,
    );
  });

  testWidgets('Test export to SVG works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(
      find.byKey(const Key('snackbarSVG')),
      findsNothing,
    );

    // Tap on the signature pad
    await tester.tap(find.byKey(const Key('signature')));
    await tester.pump();

    // Tap on the export button
    await tester.tap(find.byKey(const Key('exportSVG')));
    await tester.pump();

    expect(
      find.byKey(const Key('snackbarSVG')),
      findsNothing,
    );
  });
}
