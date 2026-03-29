import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/composition_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  group('CompositionEditor (oneOf)', () {
    testWidgets('renders dropdown with sub-schema option labels',
        (tester) async {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
          {'type': 'integer', 'title': 'Number'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('Text'), findsWidgets);
      expect(find.text('Number'), findsWidgets);
    });

    testWidgets('uses fallback label "Option N" when sub-schema has no title',
        (tester) async {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string'},
          {'type': 'integer'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('Option 1'), findsWidgets);
      expect(find.text('Option 2'), findsWidgets);
    });

    testWidgets('auto-detects index from existing value', (tester) async {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
          {'type': 'integer', 'title': 'Number'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: 42,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.pump();
      // The integer sub-schema (index 1 = 'Number') should be auto-selected.
      // 'Number' may appear in the selected dropdown button display.
      expect(find.text('Number'), findsWidgets);
      // 'Text' should not appear since it was not auto-detected
      expect(find.text('Text'), findsNothing);
    });

    testWidgets(
        'selecting an option fires onChanged with null (clear on switch)',
        (tester) async {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
          {'type': 'integer', 'title': 'Number'},
        ],
      });
      dynamic received = 'initial';
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Text').last);
      await tester.pumpAndSettle();
      expect(received, isNull);
    });

    testWidgets('non-required shows null option "-- None --"', (tester) async {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('-- None --'), findsWidgets);
    });

    testWidgets('required field hides null option', (tester) async {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
          {'type': 'integer', 'title': 'Number'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('-- None --'), findsNothing);
    });

    testWidgets('label includes "one of" for oneOf schema', (tester) async {
      final schema = JsonSchema.create({
        'title': 'My Field',
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.textContaining('one of'), findsOneWidget);
    });
  });

  group('CompositionEditor (anyOf)', () {
    testWidgets('label includes "any of" for anyOf schema', (tester) async {
      final schema = JsonSchema.create({
        'title': 'My Field',
        'anyOf': [
          {'type': 'string', 'title': 'Text'},
          {'type': 'integer', 'title': 'Number'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.textContaining('any of'), findsOneWidget);
    });

    testWidgets('renders sub-schema options for anyOf', (tester) async {
      final schema = JsonSchema.create({
        'anyOf': [
          {'type': 'string', 'title': 'Alpha'},
          {'type': 'integer', 'title': 'Beta'},
        ],
      });
      await tester.pumpWidget(_wrap(CompositionEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Beta'), findsWidgets);
    });
  });
}
