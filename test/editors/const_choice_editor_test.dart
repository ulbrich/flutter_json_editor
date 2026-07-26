import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

// A oneOf whose branches are all scalar const+title = a standards-compliant
// labeled enum (the alternative to json-editor's enumSource).
Map<String, dynamic> _oneOfSchema() => {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': {
        'employeeType': {
          'type': 'string',
          'title': 'Employee Type',
          'default': 'full-time',
          'oneOf': [
            {'const': 'full-time', 'title': 'Full-time'},
            {'const': 'part-time', 'title': 'Part-time'},
            {'const': 'contractor', 'title': 'Contractor'},
          ],
        },
      },
    };

void main() {
  group('ConstChoiceEditor.tryExtract', () {
    test('extracts choices when every branch is a scalar const', () {
      final schema = JsonSchema.create({
        'oneOf': [
          {'const': 'a', 'title': 'Alpha'},
          {'const': 'b', 'title': 'Beta'},
        ],
      });
      final choices = ConstChoiceEditor.tryExtract(schema);
      expect(choices, isNotNull);
      expect(choices!.map((c) => c.value).toList(), ['a', 'b']);
      expect(choices.map((c) => c.title).toList(), ['Alpha', 'Beta']);
    });

    test('works for anyOf too', () {
      final schema = JsonSchema.create({
        'anyOf': [
          {'const': 'x', 'title': 'Ex'},
          {'const': 'y', 'title': 'Why'},
        ],
      });
      expect(ConstChoiceEditor.tryExtract(schema), hasLength(2));
    });

    test('falls back (null) for a heterogeneous composition', () {
      final schema = JsonSchema.create({
        'oneOf': [
          {'type': 'string', 'title': 'Text'},
          {'type': 'integer', 'title': 'Number'},
        ],
      });
      expect(ConstChoiceEditor.tryExtract(schema), isNull);
    });

    test('uses the const itself as the label when no title is given', () {
      final schema = JsonSchema.create({
        'anyOf': [
          {'const': 'x'},
          {'const': 'y'},
        ],
      });
      final choices = ConstChoiceEditor.tryExtract(schema)!;
      expect(choices.map((c) => c.title).toList(), ['x', 'y']);
    });

    test('preserves non-string const types (integers)', () {
      final schema = JsonSchema.create({
        'oneOf': [
          {'const': 1, 'title': 'One'},
          {'const': 2, 'title': 'Two'},
        ],
      });
      final choices = ConstChoiceEditor.tryExtract(schema)!;
      expect(choices.map((c) => c.value).toList(), [1, 2]);
      expect(choices.first.value, isA<int>());
    });
  });

  group('oneOf/anyOf const labeled dropdown (via JsonEditor)', () {
    testWidgets('renders a labeled dropdown showing titles, not raw consts',
        (tester) async {
      final schema = SchemaUtils.createSchema(_oneOfSchema());
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<Object?>), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<Object?>));
      await tester.pumpAndSettle();
      expect(find.text('Full-time'), findsWidgets);
      expect(find.text('Contractor'), findsWidgets);
      // The raw code is never shown as display text.
      expect(find.text('full-time'), findsNothing);
    });

    testWidgets('applies the default const', (tester) async {
      final schema = SchemaUtils.createSchema(_oneOfSchema());
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButtonFormField<Object?>>(
        find.byType(DropdownButtonFormField<Object?>),
      );
      expect(dropdown.initialValue, 'full-time');
    });

    testWidgets('selecting an option stores its const value', (tester) async {
      dynamic captured;
      final schema = SchemaUtils.createSchema(_oneOfSchema());
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: schema,
        onUpdate: (fullData, diff) => captured = fullData,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Object?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contractor').last);
      await tester.pumpAndSettle();

      expect((captured as Map)['employeeType'], 'contractor');
    });
  });
}
