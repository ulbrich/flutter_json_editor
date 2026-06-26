import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/src/editors/string_editor.dart';
import 'package:flutter_json_editor/src/l10n/generated/json_editor_localizations.dart';

Widget _wrap(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      JsonEditorLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: JsonEditorLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('StringEditor', () {
    testWidgets('renders without error', (tester) async {
      final schema = JsonSchema.create({'type': 'string'});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'name',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows label from path when no title', (tester) async {
      final schema = JsonSchema.create({'type': 'string'});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'my.field.name',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('name'), findsOneWidget);
    });

    testWidgets('shows label from schema.title when present', (tester) async {
      final schema =
          JsonSchema.create({'type': 'string', 'title': 'Full Name'});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'name',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Full Name'), findsOneWidget);
    });

    testWidgets('required field shows asterisk in label', (tester) async {
      final schema = JsonSchema.create({'type': 'string', 'title': 'Email'});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'email',
        value: null,
        onChanged: (_) {},
        isRequired: true,
      )));
      expect(find.text('Email *'), findsOneWidget);
    });

    testWidgets('fires onChanged with string value on text change',
        (tester) async {
      final schema = JsonSchema.create({'type': 'string'});
      dynamic received;
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'name',
        value: null,
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), 'hello');
      await tester.pump();
      expect(received, 'hello');
    });

    testWidgets('fires onChanged with null when field is cleared',
        (tester) async {
      final schema = JsonSchema.create({'type': 'string'});
      dynamic received = 'initial';
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'name',
        value: 'initial',
        onChanged: (v) => received = v,
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      expect(received, isNull);
    });

    testWidgets('constValue renders disabled field', (tester) async {
      final schema = JsonSchema.create({'type': 'string', 'const': 'fixed'});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'field',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('readOnly renders disabled field', (tester) async {
      final schema = JsonSchema.create({'type': 'string', 'readOnly': true});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'field',
        value: 'value',
        onChanged: (_) {},
        isRequired: false,
      )));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('writeOnly obscures text', (tester) async {
      final schema = JsonSchema.create({'type': 'string', 'writeOnly': true});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'password',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      // TextFormField delegates to an EditableText which carries obscureText
      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('shows helper text from description', (tester) async {
      final schema = JsonSchema.create({
        'type': 'string',
        'description': 'Enter your name',
      });
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'name',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('shows validation error for minLength violation',
        (tester) async {
      final schema = JsonSchema.create({'type': 'string', 'minLength': 5});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'name',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.pump();
      // ValidationHelper returns errors; the editor sets errorText which Flutter
      // renders as a Text widget in the InputDecorator.
      final errorWidgets = tester.widgetList<Text>(find.byType(Text)).where(
            (t) => t.data != null && t.data!.isNotEmpty && t.data != 'name',
          );
      expect(errorWidgets, isNotEmpty);
    });

    testWidgets('localizes the email format error in English by default',
        (tester) async {
      final schema =
          JsonSchema.create({'type': 'string', 'format': 'email'});
      await tester.pumpWidget(_wrap(StringEditor(
        schema: schema,
        path: 'email',
        value: null,
        onChanged: (_) {},
        isRequired: false,
      )));
      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.pump();
      expect(find.text('Invalid email address'), findsOneWidget);
    });

    testWidgets('localizes the email format error in German', (tester) async {
      final schema =
          JsonSchema.create({'type': 'string', 'format': 'email'});
      await tester.pumpWidget(_wrap(
        StringEditor(
          schema: schema,
          path: 'email',
          value: null,
          onChanged: (_) {},
          isRequired: false,
        ),
        locale: const Locale('de'),
      ));
      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.pump();
      expect(find.text('Ungültige E-Mail-Adresse'), findsOneWidget);
    });
  });
}
