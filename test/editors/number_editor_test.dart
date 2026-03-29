import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/number_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('NumberEditor', () {
    testWidgets('renders without error for integer type', (tester) async {
      final schema = JsonSchema.create({'type': 'integer'});
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'count',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders without error for number type', (tester) async {
      final schema = JsonSchema.create({'type': 'number'});
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'price',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('required field shows asterisk in label', (tester) async {
      final schema = JsonSchema.create({'type': 'integer', 'title': 'Count'});
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'count',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      expect(find.text('Count *'), findsOneWidget);
    });

    testWidgets('fires onChanged with int for integer type', (tester) async {
      final schema = JsonSchema.create({'type': 'integer'});
      dynamic received;
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'count',
        value: null,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), '42');
      await tester.pump();
      expect(received, 42);
      expect(received, isA<int>());
    });

    testWidgets('fires onChanged with double for number type', (tester) async {
      final schema = JsonSchema.create({'type': 'number'});
      dynamic received;
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'price',
        value: null,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), '3.14');
      await tester.pump();
      expect(received, 3.14);
      expect(received, isA<double>());
    });

    testWidgets('fires onChanged with null when cleared', (tester) async {
      final schema = JsonSchema.create({'type': 'integer'});
      dynamic received = 5;
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'count',
        value: 5,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      expect(received, isNull);
    });

    testWidgets('shows error for invalid format', (tester) async {
      final schema = JsonSchema.create({'type': 'integer'});
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'count',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();
      expect(find.text('Invalid number format'), findsOneWidget);
    });

    testWidgets('constValue renders disabled field', (tester) async {
      final schema = JsonSchema.create({'type': 'integer', 'const': 42});
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('readOnly renders disabled field', (tester) async {
      final schema = JsonSchema.create({'type': 'integer', 'readOnly': true});
      await tester.pumpWidget(_wrap(NumberEditor(
        schema: schema,
        path: 'field',
        value: 10,
        onChanged: (_) {},
        isRequired: false,
      )));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('shows validation error for minimum violation', (tester) async {
      final schema = JsonSchema.create({'type': 'integer', 'minimum': 10});
      final editor = NumberEditor(
        schema: schema,
        path: 'count',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      );
      await tester.pumpWidget(_wrap(editor));
      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pump();
      // ValidationHelper returns errors; the editor sets errorText which Flutter
      // renders as a Text widget in the InputDecorator.
      final errorWidgets = tester.widgetList<Text>(find.byType(Text)).where(
            (t) => t.data != null && t.data!.isNotEmpty && t.data != 'count',
          );
      expect(errorWidgets, isNotEmpty);
    });
  });
}
