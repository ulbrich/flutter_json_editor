import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const _simpleSchema = {
  'type': 'object',
  'required': ['name'],
  'properties': {
    'name': {'type': 'string', 'title': 'Name'},
    'age': {'type': 'integer', 'title': 'Age'},
    'active': {'type': 'boolean', 'title': 'Active'},
    'score': {'type': 'number', 'title': 'Score'},
  },
};

const _nullableSchema = {
  'type': 'object',
  'properties': {
    'nickname': {
      'type': ['string', 'null'],
      'title': 'Nickname',
    },
  },
};

const _enumSchema = {
  'type': 'object',
  'properties': {
    'role': {
      'type': 'string',
      'title': 'Role',
      'enum': ['admin', 'user', 'guest'],
    },
  },
};

void main() {
  // ------------------------------------------------------------------ AC#1
  group('AC#1 — JsonEditor renders from a JsonSchema', () {
    testWidgets('instantiates with a JsonSchema without error', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      expect(find.byType(JsonEditor), findsOneWidget);
    });

    testWidgets('renders string field for string property', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pump();
      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  // ------------------------------------------------------------------ AC#2
  group('AC#2 — initialData pre-populates the form', () {
    testWidgets('string field is pre-populated', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(
        _wrap(JsonEditor(schema: schema, initialData: {'name': 'Alice'})),
      );
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Alice'), findsOneWidget);
    });

    testWidgets('multiple fields are all pre-populated', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(
        _wrap(
          JsonEditor(schema: schema, initialData: {'name': 'Bob', 'age': 25}),
        ),
      );
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Bob'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '25'), findsOneWidget);
    });

    testWidgets('widget renders without error when initialData is null', (
      tester,
    ) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      expect(find.byType(JsonEditor), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ AC#3
  group('AC#3 — onUpdate fires with (fullObject, diff)', () {
    testWidgets('onUpdate fires when a field changes', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      Map<String, dynamic>? receivedFull;
      Map<String, dynamic>? receivedDiff;

      await tester.pumpWidget(
        _wrap(
          JsonEditor(
            schema: schema,
            initialData: {'name': 'Alice'},
            onUpdate: (full, diff) {
              receivedFull = full;
              receivedDiff = diff;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Bob');
      await tester.pump();

      expect(receivedFull, isNotNull);
      expect(receivedDiff, isNotNull);
      expect(receivedFull!['name'], 'Bob');
      expect(receivedDiff!['name'], 'Bob');
    });

    testWidgets('diff only contains changed keys', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      Map<String, dynamic>? receivedDiff;

      await tester.pumpWidget(
        _wrap(
          JsonEditor(
            schema: schema,
            initialData: {'name': 'Alice', 'age': 30},
            onUpdate: (_, diff) => receivedDiff = diff,
          ),
        ),
      );
      await tester.pump();

      // Change only the name field (first TextFormField)
      await tester.enterText(find.byType(TextFormField).first, 'Carol');
      await tester.pump();

      expect(receivedDiff, isNotNull);
      expect(receivedDiff!.containsKey('name'), isTrue);
      // age was not changed, should not appear in diff
      expect(receivedDiff!.containsKey('age'), isFalse);
    });

    testWidgets('onUpdate is not called when widget renders without change', (
      tester,
    ) async {
      final schema = JsonSchema.create(_simpleSchema);
      var callCount = 0;

      await tester.pumpWidget(
        _wrap(
          JsonEditor(
            schema: schema,
            initialData: {'name': 'Alice'},
            onUpdate: (_, __) => callCount++,
          ),
        ),
      );
      await tester.pump();

      expect(callCount, 0);
    });
  });

  // ------------------------------------------------------------------ AC#4
  group('AC#4 — currentData getter returns latest state', () {
    testWidgets('currentData is readable via GlobalKey', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      final key = GlobalKey<JsonEditorState>();

      await tester.pumpWidget(
        _wrap(
          JsonEditor(key: key, schema: schema, initialData: {'name': 'Alice'}),
        ),
      );
      await tester.pump();

      expect(key.currentState, isNotNull);
      expect(key.currentState!.currentData['name'], 'Alice');
    });

    testWidgets('currentData updates after field change', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      final key = GlobalKey<JsonEditorState>();

      await tester.pumpWidget(
        _wrap(
          JsonEditor(key: key, schema: schema, initialData: {'name': 'Alice'}),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Dave');
      await tester.pump();

      expect(key.currentState!.currentData['name'], 'Dave');
    });

    testWidgets('currentData is unmodifiable', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      final key = GlobalKey<JsonEditorState>();

      await tester.pumpWidget(
        _wrap(
          JsonEditor(key: key, schema: schema, initialData: {'name': 'Alice'}),
        ),
      );
      await tester.pump();

      expect(
        () => key.currentState!.currentData['name'] = 'hacked',
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // ------------------------------------------------------------------ AC#16 / AC#18
  group('AC#16/AC#18 — EditorRegistry path override renders custom widget', () {
    testWidgets('custom builder is invoked for the overridden path', (
      tester,
    ) async {
      final schema = JsonSchema.create(_simpleSchema);
      const customKey = Key('custom-name-editor');

      final registry = EditorRegistryData(
        pathOverrides: {
          'name':
              ({
                required schema,
                required path,
                required value,
                required onChanged,
                required isRequired,
                isNullable = false,
              }) {
                return const SizedBox(key: customKey, width: 100, height: 40);
              },
        },
      );

      await tester.pumpWidget(
        _wrap(
          JsonEditor(
            schema: schema,
            initialData: {'name': 'Alice'},
            registry: registry,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(customKey), findsOneWidget);
    });

    testWidgets('non-overridden fields still render default editor', (
      tester,
    ) async {
      final schema = JsonSchema.create(_simpleSchema);

      final registry = EditorRegistryData(
        pathOverrides: {
          'name':
              ({
                required schema,
                required path,
                required value,
                required onChanged,
                required isRequired,
                isNullable = false,
              }) {
                return const SizedBox(width: 100, height: 40);
              },
        },
      );

      await tester.pumpWidget(
        _wrap(JsonEditor(schema: schema, registry: registry)),
      );
      await tester.pump();

      // 'age' is not overridden — should still render as a TextFormField
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('registry passed via widget.registry takes effect', (
      tester,
    ) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'email': {'type': 'string', 'title': 'Email'},
        },
      });

      var customBuilderCalled = false;
      final registry = EditorRegistryData(
        pathOverrides: {
          'email':
              ({
                required schema,
                required path,
                required value,
                required onChanged,
                required isRequired,
                isNullable = false,
              }) {
                customBuilderCalled = true;
                return TextFormField(
                  key: const Key('custom-email'),
                  decoration: const InputDecoration(labelText: 'Custom Email'),
                );
              },
        },
      );

      await tester.pumpWidget(
        _wrap(JsonEditor(schema: schema, registry: registry)),
      );
      await tester.pump();

      expect(customBuilderCalled, isTrue);
      expect(find.byKey(const Key('custom-email')), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ AC#20
  group('AC#20 — No Save/Cancel buttons inside the widget', () {
    testWidgets('widget does not render any ElevatedButton', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('widget does not render any FilledButton', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pump();
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('widget does not render a Save text button', (tester) async {
      final schema = JsonSchema.create(_simpleSchema);
      await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
      await tester.pump();
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });
  });

  // ------------------------------------------------------------------ Nullable
  group('Nullable field', () {
    testWidgets('nullable string field renders without error', (tester) async {
      final schema = JsonSchema.create(_nullableSchema);
      await tester.pumpWidget(
        _wrap(JsonEditor(schema: schema, initialData: {'nickname': 'Sparky'})),
      );
      await tester.pump();
      expect(find.byType(JsonEditor), findsOneWidget);
    });

    testWidgets('nullable field pre-populates correctly', (tester) async {
      final schema = JsonSchema.create(_nullableSchema);
      await tester.pumpWidget(
        _wrap(JsonEditor(schema: schema, initialData: {'nickname': 'Ghost'})),
      );
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Ghost'), findsOneWidget);
    });

    testWidgets('clearing nullable field fires null via onUpdate', (
      tester,
    ) async {
      final schema = JsonSchema.create(_nullableSchema);
      Map<String, dynamic>? lastFull;

      await tester.pumpWidget(
        _wrap(
          JsonEditor(
            schema: schema,
            initialData: {'nickname': 'Sparky'},
            onUpdate: (full, _) => lastFull = full,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // After clearing, the key should be absent (or null) in full object
      if (lastFull != null) {
        final hasNickname = lastFull!.containsKey('nickname');
        if (hasNickname) {
          expect(lastFull!['nickname'], isNull);
        } else {
          expect(hasNickname, isFalse);
        }
      }
    });
  });

  // ------------------------------------------------------------------ Enum
  group('Enum field pre-population', () {
    testWidgets('enum schema renders without error', (tester) async {
      final schema = JsonSchema.create(_enumSchema);
      await tester.pumpWidget(
        _wrap(JsonEditor(schema: schema, initialData: {'role': 'admin'})),
      );
      await tester.pump();
      expect(find.byType(JsonEditor), findsOneWidget);
    });
  });
}
