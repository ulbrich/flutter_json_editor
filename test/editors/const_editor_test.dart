import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/const_editor.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('ConstEditor shows the fixed const value read-only',
      (tester) async {
    final schema = JsonSchema.create({
      'const': 'fixed-value',
      'title': 'Status',
      'description': 'Cannot be changed',
    });

    await tester.pumpWidget(_wrap(ConstEditor(
      schema: schema,
      path: 'status',
      value: null,
      onChanged: (_) {},
      isRequired: false,
    )));

    // The constant + label/description are shown...
    expect(find.text('fixed-value'), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Cannot be changed'), findsWidgets);
    // ...but there is nothing editable.
    expect(find.byType(TextField), findsNothing);
  });
}
