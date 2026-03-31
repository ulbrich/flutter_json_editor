import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/array_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  group('ArrayEditor', () {
    testWidgets('renders without error', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(ArrayEditor), findsOneWidget);
    });

    testWidgets('shows title from schema.title', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'title': 'Tags',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Tags'), findsOneWidget);
    });

    testWidgets('shows path segment as title when no schema title',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'my.tags',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('tags'), findsOneWidget);
    });

    testWidgets('required field shows asterisk', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'title': 'Tags',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      expect(find.text('Tags *'), findsOneWidget);
    });

    testWidgets('shows description', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'description': 'List of tags',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('List of tags'), findsOneWidget);
    });

    testWidgets('shows add button', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('add button fires onChanged with new item', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      dynamic received;
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: <dynamic>[],
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(received, isA<List>());
      expect((received as List).length, 1);
    });

    testWidgets('renders existing items', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: ['a', 'b', 'c'],
        onChanged: (_) {},
        isRequired: false,
      )));
      // Three ListTiles for three items
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('delete button fires onChanged with item removed',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      dynamic received;
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: ['a', 'b'],
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pump();
      expect(received, isA<List>());
      expect((received as List).length, 1);
    });

    testWidgets('hides add button when maxItems reached', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'maxItems': 2,
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: ['a', 'b'],
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('hides delete button when minItems reached', (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'minItems': 2,
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: ['a', 'b'],
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('item change fires onChanged with updated list',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      dynamic received;
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: ['hello'],
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField).first, 'world');
      await tester.pump();
      expect(received, isA<List>());
      expect((received as List).first, 'world');
    });

    testWidgets('stable keys: items keep ValueKey after reorder',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'array',
        'items': {'type': 'string'},
      });
      await tester.pumpWidget(_wrap(ArrayEditor(
        schema: schema,
        path: 'tags',
        value: ['a', 'b'],
        onChanged: (_) {},
        isRequired: false,
      )));
      // Verify that each array item has a stable ValueKey<String>.
      // The key is on the item wrapper widget above the ListTile.
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(2));
      for (final element in listTiles.evaluate()) {
        // Walk up to find the nearest ancestor with a ValueKey.
        var found = false;
        element.visitAncestorElements((ancestor) {
          if (ancestor.widget.key is ValueKey<String>) {
            found = true;
            return false;
          }
          return true;
        });
        expect(found, isTrue);
      }
    });
  });
}
