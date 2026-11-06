import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// A form whose only field is [field].
Map<String, dynamic> wrapField(Map<String, dynamic> field) => {
  'type': 'object',
  'properties': {'field': field},
};

/// Renders [schema] as a form.
Future<void> pumpForm(WidgetTester tester, Map<String, dynamic> schema) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        JsonEditorLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: JsonEditorLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: JsonEditor(
            schema: SchemaUtils.createSchema(schema),
            onUpdate: (full, diff) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
