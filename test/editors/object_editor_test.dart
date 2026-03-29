import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/object_editor.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  group('ObjectEditor', () {
    testWidgets('renders without error for root object', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: {'name': 'Alice'},
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(ObjectEditor), findsOneWidget);
    });

    testWidgets('root object does not wrap in ExpansionTile', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('nested object shows left-border container', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: 'address',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      // Nested objects use a Container with left border instead of ExpansionTile
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows title from schema when nested', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'title': 'Home Address',
        'properties': {
          'street': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: 'address',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Home Address'), findsOneWidget);
    });

    testWidgets('shows path segment as title when no schema title',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'street': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: 'address',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('address'), findsOneWidget);
    });

    testWidgets('required nested object shows asterisk', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'title': 'Address',
        'properties': {
          'street': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: 'address',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      expect(find.text('Address *'), findsOneWidget);
    });

    testWidgets('shows description as subtitle when nested', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'description': 'Mailing address',
        'properties': {
          'street': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: 'address',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Mailing address'), findsOneWidget);
    });

    testWidgets('fires onChanged when child value changes', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      });
      dynamic received;
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: {'name': 'Alice'},
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField).first, 'Bob');
      await tester.pump();
      expect(received, isA<Map<String, dynamic>>());
      expect((received as Map<String, dynamic>)['name'], 'Bob');
    });

    testWidgets('removes key from data when child fires null', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      });
      dynamic received;
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: {'name': 'Alice'},
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      // Clear the field to trigger null
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();
      expect(received, isA<Map<String, dynamic>>());
      expect((received as Map<String, dynamic>).containsKey('name'), isFalse);
    });

    testWidgets('renders child editors for each property', (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'first': {'type': 'string'},
          'last': {'type': 'string'},
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      // Two text fields for two string properties
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('allOf renders combined properties from multiple schemas',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'allOf': [
          {
            'properties': {
              'age': {'type': 'string'},
            },
          },
        ],
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      // Both base and allOf properties should render as text fields
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('allOf last-one-wins on property conflict', (tester) async {
      // Both base and allOf define 'label' — allOf version should win.
      // Since both are string, the field count stays 1 (deduplicated by map key).
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'label': {'type': 'string', 'title': 'Base Label'},
        },
        'allOf': [
          {
            'properties': {
              'label': {'type': 'string', 'title': 'AllOf Label'},
            },
          },
        ],
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      // Only one field rendered (deduplication via Map key)
      expect(find.byType(TextFormField), findsOneWidget);
      // The allOf title wins over the base title
      expect(find.text('AllOf Label'), findsOneWidget);
      expect(find.text('Base Label'), findsNothing);
    });

    testWidgets(
        'propertyDependencies makes additional field required when trigger is present',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'hasAddress': {'type': 'string'},
          'street': {'type': 'string'},
        },
        'dependencies': {
          'hasAddress': ['street'],
        },
      });
      // 'street' is not in requiredProperties, but with hasAddress present it
      // should be treated as required. We verify by checking the asterisk.
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'hasAddress': 'yes'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // 'street' should show asterisk since hasAddress is in data
      expect(find.textContaining('street *'), findsOneWidget);
    });

    testWidgets(
        'propertyDependencies does not make field required when trigger is absent',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'hasAddress': {'type': 'string'},
          'street': {'type': 'string'},
        },
        'dependencies': {
          'hasAddress': ['street'],
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{},
        onChanged: (_) {},
        isRequired: false,
      )));
      // 'street' should NOT show asterisk since hasAddress is absent
      expect(find.textContaining('street *'), findsNothing);
    });

    testWidgets(
        'schemaDependencies shows additional fields when trigger is present',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'isBusiness': {'type': 'string'},
        },
        'dependencies': {
          'isBusiness': {
            'properties': {
              'companyName': {'type': 'string'},
            },
          },
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'isBusiness': 'yes'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // companyName should appear because isBusiness is in data
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets(
        'schemaDependencies hides additional fields when trigger is absent',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'isBusiness': {'type': 'string'},
        },
        'dependencies': {
          'isBusiness': {
            'properties': {
              'companyName': {'type': 'string'},
            },
          },
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{},
        onChanged: (_) {},
        isRequired: false,
      )));
      // Only isBusiness field, companyName hidden
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('if/then/else: then-properties appear when condition is met',
        (tester) async {
      // if type == 'company' then show companyName, else show personalId
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'type': {'type': 'string'},
        },
        'if': {
          'properties': {
            'type': {'const': 'company'},
          },
          'required': ['type'],
        },
        'then': {
          'properties': {
            'companyName': {'type': 'string'},
          },
        },
        'else': {
          'properties': {
            'personalId': {'type': 'string'},
          },
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'type': 'company'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // Both 'type' and 'companyName' fields should be rendered
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets(
        'if/then/else: else-properties appear when condition is not met',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'type': {'type': 'string'},
        },
        'if': {
          'properties': {
            'type': {'const': 'company'},
          },
          'required': ['type'],
        },
        'then': {
          'properties': {
            'companyName': {'type': 'string'},
          },
        },
        'else': {
          'properties': {
            'personalId': {'type': 'string'},
          },
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'type': 'individual'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // Both 'type' and 'personalId' should be rendered (not companyName)
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets(
        'if/then/else: only then-branch shows no else when condition met',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'enabled': {'type': 'string'},
        },
        'if': {
          'properties': {
            'enabled': {'const': 'yes'},
          },
          'required': ['enabled'],
        },
        'then': {
          'properties': {
            'extraField': {'type': 'string'},
          },
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'enabled': 'yes'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // 'enabled' + 'extraField' both shown
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('if/then only: no extra fields when condition not met',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'enabled': {'type': 'string'},
        },
        'if': {
          'properties': {
            'enabled': {'const': 'yes'},
          },
          'required': ['enabled'],
        },
        'then': {
          'properties': {
            'extraField': {'type': 'string'},
          },
        },
      });
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'enabled': 'no'},
        onChanged: (_) {},
        isRequired: false,
      )));
      // Only 'enabled' shown, no extraField (no else branch)
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('if/then/else: condition flip cleans up stale then-data',
        (tester) async {
      final schema = JsonSchema.create({
        'type': 'object',
        'properties': {
          'mode': {'type': 'string'},
        },
        'if': {
          'properties': {
            'mode': {'const': 'advanced'},
          },
          'required': ['mode'],
        },
        'then': {
          'properties': {
            'advancedSetting': {'type': 'string'},
          },
        },
        'else': {
          'properties': {
            'basicSetting': {'type': 'string'},
          },
        },
      });

      Map<String, dynamic>? received;
      // Start with condition met (mode=advanced), then switch to simple
      await tester.pumpWidget(_wrap(ObjectEditor(
        schema: schema,
        path: '',
        value: <String, dynamic>{'mode': 'advanced', 'advancedSetting': 'x'},
        onChanged: (v) => received = v as Map<String, dynamic>?,
        isRequired: false,
      )));

      // Change mode to 'simple' to flip condition
      final fields = find.byType(TextFormField);
      // First field is 'mode'
      await tester.enterText(fields.first, 'simple');
      await tester.pump();

      // advancedSetting should be cleaned from received data
      if (received != null) {
        expect(received!.containsKey('advancedSetting'), isFalse);
      }
    });
  });
}
