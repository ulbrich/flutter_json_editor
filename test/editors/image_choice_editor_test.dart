import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

Map<String, dynamic> _dish() => {
      'type': 'string',
      'title': 'Dish',
      'x-format': 'image-choice',
      'oneOf': [
        {
          'const': 'margherita',
          'title': 'Margherita',
          'description': 'Tomato and mozzarella',
        },
        {'const': 'diavola', 'title': 'Diavola'},
      ],
    };

Map<String, dynamic> _schema(Map<String, dynamic> dish) => {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': {'dish': dish},
    };

void main() {
  test('ConstChoice carries a branch\'s description and x-image', () {
    final choices = ConstChoiceEditor.tryExtract(JsonSchema.create({
      'oneOf': [
        {
          'const': 'a',
          'title': 'A',
          'description': 'First',
          'x-image': 'https://example.com/a.jpg',
        },
        {'const': 'b'},
      ],
    }))!;
    expect(choices.first.description, 'First');
    expect(choices.first.imageUrl, 'https://example.com/a.jpg');
    expect(choices.last.description, isNull);
    expect(choices.last.imageUrl, isNull);
  });

  testWidgets('picks an option from the picture grid', (tester) async {
    dynamic data;
    await tester.pumpWidget(_wrap(JsonEditor(
      schema: SchemaUtils.createSchema(_schema(_dish())),
      onUpdate: (full, _) => data = full,
    )));

    expect(find.byType(ImageChoiceEditor), findsOneWidget);
    expect(find.text('Select…'), findsOneWidget);

    await tester.tap(find.byType(ImageChoiceEditor));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Margherita'));
    await tester.pumpAndSettle();

    expect((data as Map)['dish'], 'margherita');
    expect(find.text('Tomato and mozzarella'), findsOneWidget);
  });

  testWidgets('shows pictures through a custom image builder', (tester) async {
    final dish = _dish();
    (dish['oneOf'] as List).first['x-image'] = 'https://example.com/m.jpg';
    final loaded = <String>[];
    await tester.pumpWidget(_wrap(JsonEditor(
      schema: SchemaUtils.createSchema(_schema(dish)),
      initialData: const {'dish': 'margherita'},
      onUpdate: (_, __) {},
      registry: EditorRegistryData(formatOverrides: {
        'image-choice': ImageChoiceEditor.builderWith((context, url, _) {
          loaded.add(url);
          return const SizedBox.shrink();
        }),
      }),
    )));

    expect(loaded, ['https://example.com/m.jpg']);
  });

  testWidgets('falls back to the usual editor without const options',
      (tester) async {
    await tester.pumpWidget(_wrap(JsonEditor(
      schema: SchemaUtils.createSchema(_schema({
        'type': 'string',
        'title': 'Dish',
        'x-format': 'image-choice',
      })),
      onUpdate: (_, __) {},
    )));

    expect(find.byType(TextFormField), findsOneWidget);
  });
}
