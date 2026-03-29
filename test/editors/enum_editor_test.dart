import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/enum_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('EnumEditor', () {
    testWidgets('renders without error', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['a', 'b', 'c'],
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'status',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(DropdownButtonFormField<dynamic>), findsOneWidget);
    });

    testWidgets('shows label from path when no title', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['a', 'b'],
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'my.status',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('status'), findsOneWidget);
    });

    testWidgets('required field shows asterisk in label', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'title': 'Status',
        'enum': ['active', 'inactive'],
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'status',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      expect(find.text('Status *'), findsOneWidget);
    });

    testWidgets('fires onChanged with selected value', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['active', 'inactive'],
      });
      dynamic received;
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'status',
        value: null,
        onChanged: (v) => received = v,
        isRequired: false,
      )));

      await tester.tap(find.byType(DropdownButtonFormField<dynamic>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('active').last);
      await tester.pumpAndSettle();

      expect(received, 'active');
    });

    testWidgets('non-required dropdown includes null option', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['a', 'b'],
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));

      await tester.tap(find.byType(DropdownButtonFormField<dynamic>));
      await tester.pumpAndSettle();
      // Null option shown as '—' — may appear multiple times (selected + list item)
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('readOnly disables dropdown', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['a', 'b'],
        'readOnly': true,
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'field',
        value: 'a',
        onChanged: (_) {},
        isRequired: false,
      )));
      final dropdown = tester.widget<DropdownButtonFormField<dynamic>>(
        find.byType(DropdownButtonFormField<dynamic>),
      );
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('shows helper text from description', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['a', 'b'],
        'description': 'Choose a value',
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Choose a value'), findsOneWidget);
    });

    testWidgets('shows currently selected value', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'enum': ['alpha', 'beta', 'gamma'],
      });
      await tester.pumpWidget(_wrap(EnumEditor(
        schema: schema,
        path: 'field',
        value: 'beta',
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('beta'), findsOneWidget);
    });
  });
}
