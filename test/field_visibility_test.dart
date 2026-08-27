import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const _schema = {
  'type': 'object',
  'properties': {
    'name': {'type': 'string', 'title': 'Name'},
    'nickname': {'type': 'string', 'title': 'Nickname'},
    'address': {
      'type': 'object',
      'title': 'Address',
      'properties': {
        'street': {'type': 'string', 'title': 'Street'},
        'zip': {'type': 'string', 'title': 'Zip'},
      },
    },
    'contacts': {
      'type': 'array',
      'title': 'Contacts',
      'items': {
        'type': 'object',
        'properties': {
          'email': {'type': 'string', 'title': 'Email'},
          'phone': {'type': 'string', 'title': 'Phone'},
        },
      },
    },
  },
};

const _mapSchema = {
  'type': 'object',
  'properties': {
    'meta': {
      'type': 'object',
      'title': 'Meta',
      'additionalProperties': {'type': 'string'},
    },
    'name': {'type': 'string', 'title': 'Name'},
  },
};

void main() {
  group('FieldVisibility path parsing', () {
    test('splits dotted paths with array indices', () {
      expect(
        FieldVisibility.parsePath('contacts[0].email'),
        ['contacts', '[0]', 'email'],
      );
      expect(FieldVisibility.parsePath('name'), ['name']);
      expect(FieldVisibility.parsePath(''), isEmpty);
      expect(FieldVisibility.parsePath(r'$.address.zip'), ['address', 'zip']);
    });

    test('normalizes JSON Pointer form', () {
      expect(
        FieldVisibility.parsePath('/contacts/0/email'),
        ['contacts', '[0]', 'email'],
      );
      expect(FieldVisibility.parsePath('/address/zip'), ['address', 'zip']);
    });
  });

  group('FieldVisibility matching', () {
    test('all() shows everything and filters nothing', () {
      const v = FieldVisibility.all();
      expect(v.isFiltering, isFalse);
      expect(v.isVisible('anything.at.all'), isTrue);
      expect(v.isSubtreeVisible('anything'), isTrue);
      expect(v.allowsStructuralEdits('contacts'), isTrue);
    });

    test('whitelisted path, its ancestors, and its descendants are visible', () {
      final v = FieldVisibility.whitelist(['address.zip']);
      expect(v.isVisible('address'), isTrue, reason: 'ancestor container');
      expect(v.isVisible('address.zip'), isTrue, reason: 'exact match');
      expect(v.isVisible('address.zip.extra'), isTrue, reason: 'descendant');
      expect(v.isVisible('address.street'), isFalse, reason: 'sibling');
      expect(v.isVisible('name'), isFalse);
    });

    test('a whitelisted container exposes its whole subtree', () {
      final v = FieldVisibility.whitelist(['address']);
      expect(v.isSubtreeVisible('address'), isTrue);
      expect(v.isSubtreeVisible('address.zip'), isTrue);
      expect(v.isSubtreeVisible('name'), isFalse);
      // Ancestor-only visibility is not subtree visibility.
      final partial = FieldVisibility.whitelist(['address.zip']);
      expect(partial.isSubtreeVisible('address'), isFalse);
      expect(partial.isSubtreeVisible('address.zip'), isTrue);
    });

    test('[*] matches any index, * matches any property', () {
      final v = FieldVisibility.whitelist(['contacts[*].email']);
      expect(v.isVisible('contacts[0].email'), isTrue);
      expect(v.isVisible('contacts[7].email'), isTrue);
      expect(v.isVisible('contacts[0].phone'), isFalse);

      final w = FieldVisibility.whitelist(['address.*']);
      expect(w.isVisible('address.zip'), isTrue);
      expect(w.isVisible('address.street'), isTrue);
      expect(w.isVisible('name'), isFalse);
    });

    test('an empty whitelist hides everything, including the root', () {
      final v = FieldVisibility.whitelist(const <String>[]);
      expect(v.isFiltering, isTrue);
      expect(v.isVisible(''), isFalse);
      expect(v.isVisible('name'), isFalse);
    });

    test('structural edits follow index wildcards, not concrete indices', () {
      expect(
        FieldVisibility.whitelist(['contacts[*].email'])
            .allowsStructuralEdits('contacts'),
        isTrue,
      );
      expect(
        FieldVisibility.whitelist(['contacts[0].email'])
            .allowsStructuralEdits('contacts'),
        isFalse,
      );
      // A fully whitelisted array is freely editable.
      expect(
        FieldVisibility.whitelist(['contacts']).allowsStructuralEdits('contacts'),
        isTrue,
      );
      // Mixing a concrete index in locks it down again.
      expect(
        FieldVisibility.whitelist(['contacts[*].email', 'contacts[1].phone'])
            .allowsStructuralEdits('contacts'),
        isFalse,
      );
      // An array the whitelist never reaches is not editable.
      expect(
        FieldVisibility.whitelist(['name']).allowsStructuralEdits('contacts'),
        isFalse,
      );
    });

    test('equality ignores path spelling differences', () {
      expect(
        FieldVisibility.whitelist(['/address/zip']),
        FieldVisibility.whitelist(['address.zip']),
      );
      expect(
        FieldVisibility.whitelist(['address.zip']).hashCode,
        FieldVisibility.whitelist(['address.zip']).hashCode,
      );
      expect(
        FieldVisibility.whitelist(['address.zip']),
        isNot(FieldVisibility.whitelist(['address.street'])),
      );
    });
  });

  group('JsonEditor rendering with visiblePaths', () {
    testWidgets('renders only whitelisted top-level fields', (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        visiblePaths: const ['name'],
      )));
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Nickname'), findsNothing);
      expect(find.text('Address'), findsNothing);
      expect(find.text('Contacts'), findsNothing);
    });

    testWidgets('renders a nested container with only the listed child',
        (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        visiblePaths: const ['address.zip'],
      )));
      await tester.pump();

      expect(find.text('Address'), findsOneWidget, reason: 'section shell');
      expect(find.text('Zip'), findsOneWidget);
      expect(find.text('Street'), findsNothing);
      expect(find.text('Name'), findsNothing);
    });

    testWidgets('a whitelisted container shows its whole subtree',
        (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        visiblePaths: const ['address'],
      )));
      await tester.pump();

      expect(find.text('Zip'), findsOneWidget);
      expect(find.text('Street'), findsOneWidget);
      expect(find.text('Name'), findsNothing);
    });

    testWidgets('an empty whitelist renders no fields', (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        visiblePaths: const [],
      )));
      await tester.pump();

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Name'), findsNothing);
      expect(find.text('Address'), findsNothing);
    });

    testWidgets('no whitelist renders everything', (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
      )));
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Nickname'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
    });

    testWidgets('visibility takes precedence over visiblePaths',
        (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        visiblePaths: const ['nickname'],
        visibility: FieldVisibility.whitelist(const ['name']),
      )));
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Nickname'), findsNothing);
    });
  });

  group('Array and map filtering', () {
    testWidgets('wildcard index shows every item, filtered to one field',
        (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        initialData: const {
          'contacts': [
            {'email': 'a@example.com', 'phone': '1'},
            {'email': 'b@example.com', 'phone': '2'},
          ],
        },
        visiblePaths: const ['contacts[*].email'],
      )));
      await tester.pump();

      expect(find.text('Email'), findsNWidgets(2));
      expect(find.text('Phone'), findsNothing);
      // Wildcard indices keep add/delete available.
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNWidgets(2));
    });

    testWidgets('a concrete index shows that item only and freezes the list',
        (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        initialData: const {
          'contacts': [
            {'email': 'a@example.com', 'phone': '1'},
            {'email': 'b@example.com', 'phone': '2'},
          ],
        },
        visiblePaths: const ['contacts[1].email'],
      )));
      await tester.pump();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('b@example.com'), findsOneWidget);
      expect(find.text('a@example.com'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('map entries are filtered by key and the map is frozen',
        (tester) async {
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_mapSchema),
        initialData: const {
          'meta': {'author': 'ada', 'source': 'import'},
        },
        visiblePaths: const ['meta.author'],
      )));
      await tester.pump();

      // The key shows up twice: in the key field and as the value editor's
      // fallback label (which falls back to the last path segment).
      expect(find.text('author'), findsWidgets);
      expect(find.text('source'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });
  });

  group('Hidden data is preserved', () {
    testWidgets('editing a visible field returns the full object',
        (tester) async {
      dynamic captured;
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        initialData: const {
          'name': 'Ada',
          'nickname': 'The Countess',
          'address': {'street': 'Main St', 'zip': '12345'},
          'contacts': [
            {'email': 'a@example.com', 'phone': '1'},
          ],
        },
        visiblePaths: const ['name'],
        onUpdate: (fullData, diff) => captured = fullData,
      )));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Ada Lovelace');
      await tester.pump();

      expect(captured, isNotNull);
      final data = captured as Map<String, dynamic>;
      expect(data['name'], 'Ada Lovelace');
      // Everything the editor never rendered comes back untouched.
      expect(data['nickname'], 'The Countess');
      expect(data['address'], const {'street': 'Main St', 'zip': '12345'});
      expect(data['contacts'], const [
        {'email': 'a@example.com', 'phone': '1'},
      ]);
    });

    testWidgets('editing inside a partially visible object keeps its siblings',
        (tester) async {
      dynamic captured;
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        initialData: const {
          'name': 'Ada',
          'address': {'street': 'Main St', 'zip': '12345'},
        },
        visiblePaths: const ['address.zip'],
        onUpdate: (fullData, diff) => captured = fullData,
      )));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '99999');
      await tester.pump();

      final data = captured as Map<String, dynamic>;
      expect(data['name'], 'Ada');
      expect(data['address'], const {'street': 'Main St', 'zip': '99999'});
    });

    testWidgets('hidden array items survive an edit to a visible one',
        (tester) async {
      dynamic captured;
      await tester.pumpWidget(_wrap(JsonEditor(
        schema: JsonSchema.create(_schema),
        initialData: const {
          'contacts': [
            {'email': 'a@example.com', 'phone': '1'},
            {'email': 'b@example.com', 'phone': '2'},
          ],
        },
        visiblePaths: const ['contacts[1].email'],
        onUpdate: (fullData, diff) => captured = fullData,
      )));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'z@example.com');
      await tester.pump();

      final data = captured as Map<String, dynamic>;
      expect(data['contacts'], const [
        {'email': 'a@example.com', 'phone': '1'},
        {'email': 'z@example.com', 'phone': '2'},
      ]);
    });
  });
}
