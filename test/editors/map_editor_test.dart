import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/map_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  group('MapEditor', () {
    testWidgets('renders without error', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'metadata',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(MapEditor), findsOneWidget);
    });

    testWidgets('shows title from schema.title', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'title': 'Metadata',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'metadata',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Metadata'), findsOneWidget);
    });

    testWidgets('shows path segment as title when no schema title',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'my.meta',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('meta'), findsOneWidget);
    });

    testWidgets('required field shows asterisk', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'title': 'Labels',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'labels',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      expect(find.text('Labels *'), findsOneWidget);
    });

    testWidgets('shows description', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'description': 'Key-value metadata',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Key-value metadata'), findsOneWidget);
    });

    testWidgets('shows add button', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('add button fires onChanged with new entry', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      dynamic received;
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: <String, dynamic>{},
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(received, isA<Map<String, dynamic>>());
      expect((received as Map<String, dynamic>).length, 1);
    });

    testWidgets('renders existing entries with key fields', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: {'foo': 'bar', 'baz': 'qux'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // Should find two key fields labeled 'Key'
      expect(find.widgetWithText(TextFormField, 'Key'), findsNWidgets(2));
    });

    testWidgets('delete button fires onChanged with entry removed',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      dynamic received;
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: {'a': '1', 'b': '2'},
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pump();
      expect(received, isA<Map<String, dynamic>>());
      expect((received as Map<String, dynamic>).length, 1);
    });

    testWidgets('auto-generates unique key name on add', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      final received = <dynamic>[];
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: <String, dynamic>{},
        onChanged: (v) => received.add(v),
        isRequired: false,
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      // Both add calls should produce maps — each with unique keys
      expect(received.length, 2);
      final first = received[0] as Map<String, dynamic>;
      final second = received[1] as Map<String, dynamic>;
      expect(first.keys.toSet().intersection(second.keys.toSet()).length,
          lessThan(second.length));
    });

    testWidgets('entry Padding widgets have stable ValueKey', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(MapEditor(
        schema: schema,
        path: 'meta',
        value: {'x': '1', 'y': '2'},
        onChanged: (_) {},
        isRequired: false,
      )));
      final paddings = tester
          .widgetList<Padding>(find.byType(Padding))
          .where((p) => p.key is ValueKey<String>)
          .toList();
      expect(paddings.length, 2);
    });
  });
}
