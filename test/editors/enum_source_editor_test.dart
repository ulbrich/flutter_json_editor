import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

/// A schema whose `transfer` property is a local `$ref` into a `$defs`
/// definition that carries an `enumSource` value/title list. The label
/// (`title`) must be displayed while the code (`value`) is stored.
Map<String, dynamic> _schemaMap() => {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': {
        'transfer': {r'$ref': r'#/$defs/transfer'},
      },
      r'$defs': {
        'transfer': {
          'type': 'string',
          'title': 'Übergabe an',
          'default': 'ktw',
          'enumSource': [
            {
              'source': [
                {'value': 'ktw', 'title': 'Krankenwagen'},
                {'value': 'rth', 'title': 'Hubschrauber'},
              ],
            }
          ],
        },
      },
    };

void main() {
  group('local \$ref -> \$defs enumSource labeled select', () {
    testWidgets('renders a labeled dropdown showing titles, not codes',
        (tester) async {
      final schema = SchemaUtils.createSchema(_schemaMap());
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Open the dropdown so every option is rendered.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Titles are shown ...
      expect(find.text('Krankenwagen'), findsWidgets);
      expect(find.text('Hubschrauber'), findsWidgets);
      // ... raw code values are never shown as display text.
      expect(find.text('ktw'), findsNothing);
      expect(find.text('rth'), findsNothing);
    });

    testWidgets('applies the default (stored value ktw -> label Krankenwagen)',
        (tester) async {
      final schema = SchemaUtils.createSchema(_schemaMap());
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      // The stored value is the code, applied from `default`.
      expect(dropdown.initialValue, 'ktw');
    });

    testWidgets('selecting an option stores its value, not its title',
        (tester) async {
      dynamic captured;
      final schema = SchemaUtils.createSchema(_schemaMap());
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: schema,
        onUpdate: (fullData, diff) => captured = fullData,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hubschrauber').last);
      await tester.pumpAndSettle();

      expect(captured, isA<Map>());
      expect((captured as Map)['transfer'], 'rth');
    });
  });
}
