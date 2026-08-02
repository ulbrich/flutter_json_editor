import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

// Standard JSON Schema: subcategory's allowed values depend on category, via
// if/then under allOf (one conditional per category).
Map<String, dynamic> _schema() => {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': {
        'category': {
          'type': 'string',
          'title': 'Category',
          'oneOf': [
            {'const': 'a', 'title': 'Alpha'},
            {'const': 'b', 'title': 'Beta'},
          ],
        },
      },
      'allOf': [
        {
          'if': {
            'properties': {
              'category': {'const': 'a'}
            },
            'required': ['category']
          },
          'then': {
            'properties': {
              'subcategory': {
                'type': 'string',
                'title': 'Sub',
                'oneOf': [
                  {'const': 'a1', 'title': 'Alpha one'},
                  {'const': 'a2', 'title': 'Alpha two'},
                ],
              }
            },
            'required': ['subcategory'],
          },
        },
        {
          'if': {
            'properties': {
              'category': {'const': 'b'}
            },
            'required': ['category']
          },
          'then': {
            'properties': {
              'subcategory': {
                'type': 'string',
                'title': 'Sub',
                'oneOf': [
                  {'const': 'b1', 'title': 'Beta one'},
                ],
              }
            },
            'required': ['subcategory'],
          },
        },
      ],
    };

void main() {
  testWidgets('subcategory options depend on category via allOf if/then',
      (tester) async {
    final schema = SchemaUtils.createSchema(_schema());
    await tester.pumpWidget(_wrap(JsonEditor(schema: schema)));
    await tester.pumpAndSettle();

    // No category chosen yet -> subcategory not shown (only category).
    expect(find.byType(ConstChoiceEditor), findsOneWidget);

    // Choose category = Alpha.
    await tester.tap(find.byType(ConstChoiceEditor).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha').last);
    await tester.pumpAndSettle();

    // Subcategory appears, scoped to Alpha's options.
    expect(find.byType(ConstChoiceEditor), findsNWidgets(2));
    await tester.tap(find.byType(ConstChoiceEditor).last);
    await tester.pumpAndSettle();
    expect(find.text('Alpha one'), findsWidgets);
    expect(find.text('Alpha two'), findsWidgets);
    expect(find.text('Beta one'), findsNothing);
  });
}
