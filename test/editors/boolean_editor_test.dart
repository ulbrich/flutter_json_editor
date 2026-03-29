import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/boolean_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('BooleanEditor', () {
    testWidgets('renders without error', (tester) async {
      final schema = JsonSchema.create({'type': 'boolean'});
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('shows title from schema.title', (tester) async {
      final schema = JsonSchema.create({'type': 'boolean', 'title': 'Active'});
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows title from path when no title', (tester) async {
      final schema = JsonSchema.create({'type': 'boolean'});
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'my.field.active',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('active'), findsOneWidget);
    });

    testWidgets('defaults to false when value is null', (tester) async {
      final schema = JsonSchema.create({'type': 'boolean'});
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      final tile =
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.value, isFalse);
    });

    testWidgets('shows true when value is true', (tester) async {
      final schema = JsonSchema.create({'type': 'boolean'});
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: true,
        onChanged: (_) {},
        isRequired: false,
      )));
      final tile =
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.value, isTrue);
    });

    testWidgets('fires onChanged with true on toggle from false',
        (tester) async {
      final schema = JsonSchema.create({'type': 'boolean'});
      dynamic received;
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: false,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(received, isTrue);
    });

    testWidgets('fires onChanged with false on toggle from true',
        (tester) async {
      final schema = JsonSchema.create({'type': 'boolean'});
      dynamic received;
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: true,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(received, isFalse);
    });

    testWidgets('readOnly disables the checkbox', (tester) async {
      final schema = JsonSchema.create({'type': 'boolean', 'readOnly': true});
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: false,
        onChanged: (_) {},
        isRequired: false,
      )));
      final tile =
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.onChanged, isNull);
    });

    testWidgets('shows description as subtitle', (tester) async {
      final schema = JsonSchema.create({
        'type': 'boolean',
        'description': 'Whether the account is active',
      });
      await tester.pumpWidget(_wrap(BooleanEditor(
        schema: schema,
        path: 'active',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Whether the account is active'), findsOneWidget);
    });
  });
}
