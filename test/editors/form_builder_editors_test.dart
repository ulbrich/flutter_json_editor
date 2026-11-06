import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    JsonEditorLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: JsonEditorLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

class _Form {
  dynamic data;
  bool submitted = false;
  Map get map => (data ?? const {}) as Map;
}

/// A form whose root has [properties]; its data is kept in the result.
Future<_Form> _pump(
  WidgetTester tester,
  Map<String, dynamic> properties, {
  Map<String, dynamic>? initial,
  Map<String, dynamic> root = const {},
  List<String> required = const [],
  Locale? locale,
}) async {
  final form = _Form()..data = initial;
  await tester.pumpWidget(
    _wrap(
      JsonEditor(
        schema: SchemaUtils.createSchema({
          r'$schema': 'http://json-schema.org/draft-07/schema#',
          'type': 'object',
          if (required.isNotEmpty) 'required': required,
          'properties': properties,
          ...root,
        }),
        initialData: initial,
        onUpdate: (full, diff) => form.data = full,
        onSubmit: (data) => form.submitted = true,
      ),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
  return form;
}

void main() {
  group('ScaleEditor', () {
    testWidgets('linear scale stores the tapped number and shows labels', (
      tester,
    ) async {
      final form = await _pump(tester, {
        'f': {
          'type': 'integer',
          'x-format': 'linear-scale',
          'minimum': 1,
          'maximum': 5,
          'x-min-label': 'Bad',
          'x-max-label': 'Great',
        },
      });
      expect(find.byKey(const ValueKey('scale-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('scale-5')), findsOneWidget);
      expect(find.byKey(const ValueKey('scale-6')), findsNothing);
      expect(find.text('Bad'), findsOneWidget);
      expect(find.text('Great'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scale-4')));
      await tester.pump();
      expect(form.map['f'], 4);
      await tester.tap(find.byKey(const ValueKey('scale-4')));
      await tester.pump();
      expect(form.map.containsKey('f'), isFalse);
    });

    testWidgets('nps runs 0 to 10 with default labels', (tester) async {
      final form = await _pump(tester, {
        'f': {'type': 'integer', 'x-format': 'nps'},
      });
      expect(find.byKey(const ValueKey('scale-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('scale-10')), findsOneWidget);
      expect(find.text('Not at all likely'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scale-9')));
      await tester.pump();
      expect(form.map['f'], 9);
    });

    testWidgets('emoji scale shows faces', (tester) async {
      final form = await _pump(tester, {
        'f': {'type': 'integer', 'x-format': 'emoji-scale'},
      });
      expect(find.byIcon(Icons.sentiment_very_satisfied_outlined), findsOne);
      await tester.tap(find.byKey(const ValueKey('scale-1')));
      await tester.pump();
      expect(form.map['f'], 1);
    });

    testWidgets('a string falls back to the plain editor', (tester) async {
      await _pump(tester, {
        'f': {'type': 'string', 'x-format': 'nps'},
      });
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('MatrixEditor', () {
    final agree = {
      'type': 'string',
      'oneOf': [
        {'const': 'no', 'title': 'No'},
        {'const': 'yes', 'title': 'Yes'},
      ],
    };

    testWidgets('radio rows store one answer each', (tester) async {
      final form = await _pump(tester, {
        'm': {
          'type': 'object',
          'x-format': 'matrix',
          'properties': {
            'a': {'title': 'Row A', ...agree},
            'b': {'title': 'Row B', ...agree},
          },
        },
      });
      expect(find.text('Row A'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('matrix-a-yes')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('matrix-b-no')));
      await tester.pump();
      expect(form.map['m'], {'a': 'yes', 'b': 'no'});
      await tester.tap(find.byKey(const ValueKey('matrix-a-yes')));
      await tester.pump();
      expect(form.map['m'], {'b': 'no'});
    });

    testWidgets('array rows take several answers', (tester) async {
      final form = await _pump(tester, {
        'm': {
          'type': 'object',
          'x-format': 'matrix',
          'properties': {
            'a': {'type': 'array', 'title': 'Row A', 'items': agree},
          },
        },
      });
      await tester.tap(find.byKey(const ValueKey('matrix-a-no')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('matrix-a-yes')));
      await tester.pump();
      expect(form.map['m'], {
        'a': ['no', 'yes'],
      });
    });
  });

  group('RankingEditor', () {
    final schema = {
      'r': {
        'type': 'array',
        'x-format': 'ranking',
        'items': {
          'type': 'string',
          'enum': ['A', 'B', 'C'],
        },
      },
    };

    test('order keeps stored values first and appends the rest', () {
      const choices = [
        ConstChoice(value: 'A', title: 'A'),
        ConstChoice(value: 'B', title: 'B'),
        ConstChoice(value: 'C', title: 'C'),
      ];
      expect(
        RankingEditor.order(choices, ['C', 'X', 'A']).map((c) => c.value),
        ['C', 'A', 'B'],
      );
    });

    testWidgets('arrows move choices and store the whole order', (
      tester,
    ) async {
      final form = await _pump(tester, schema);
      expect(find.text('Drag or use the arrows to put the choices in order'),
          findsOneWidget);
      final down = find.descendant(
        of: find.byKey(const ValueKey('ranking-A')),
        matching: find.byIcon(Icons.arrow_downward),
      );
      await tester.tap(down);
      await tester.pump();
      expect(form.map['r'], ['B', 'A', 'C']);
    });

    testWidgets('loads a stored order', (tester) async {
      await _pump(tester, schema, initial: {
        'r': ['C', 'B', 'A'],
      });
      final c = tester.getTopLeft(find.byKey(const ValueKey('ranking-C')));
      final a = tester.getTopLeft(find.byKey(const ValueKey('ranking-A')));
      expect(c.dy, lessThan(a.dy));
    });
  });

  group('DateRangeEditor', () {
    test('formatDate and parseDate', () {
      expect(DateRangeEditor.formatDate(DateTime(2026, 3, 4)), '2026-03-04');
      expect(DateRangeEditor.parseDate('2026-03-04T10:00:00Z'),
          DateTime(2026, 3, 4));
      expect(DateRangeEditor.parseDate('nope'), isNull);
    });

    testWidgets('shows a stored object range with its day count', (
      tester,
    ) async {
      await _pump(
        tester,
        {
          'v': {
            'type': 'object',
            'x-format': 'date-range',
            'properties': {
              'from': {'type': 'string'},
              'to': {'type': 'string'},
            },
          },
        },
        initial: {
          'v': {'from': '2026-11-06', 'to': '2026-11-10'},
        },
      );
      expect(find.text('Nov 6, 2026 – Nov 10, 2026'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
    });

    testWidgets('picks a string range in the calendar', (tester) async {
      final form = await _pump(tester, {
        'v': {
          'type': 'string',
          'x-format': 'date-range',
          'x-min-date': '2026-11-01',
          'x-max-date': '2026-11-30',
        },
      });
      await tester.tap(find.byKey(const ValueKey('date-range-text')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').last);
      await tester.pump();
      await tester.tap(find.text('12').last);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(form.map['v'], '2026-11-10/2026-11-12');
    });
  });

  group('PhoneEditor', () {
    testWidgets('stores E.164 from a national number', (tester) async {
      final form = await _pump(tester, {
        'p': {'type': 'string', 'x-format': 'phone', 'x-default-country': 'DE'},
      });
      await tester.enterText(
        find.byKey(const ValueKey('phone-number')),
        '0151 12345678',
      );
      await tester.pump();
      expect(form.map['p'], '+4915112345678');
      expect(find.text('Not a valid phone number for this country'),
          findsNothing);
    });

    testWidgets('shows an error for an impossible number', (tester) async {
      await _pump(tester, {
        'p': {'type': 'string', 'x-format': 'phone', 'x-default-country': 'DE'},
      });
      await tester.enterText(find.byKey(const ValueKey('phone-number')), '12');
      await tester.pump();
      expect(find.text('Not a valid phone number for this country'),
          findsOneWidget);
    });

    testWidgets('loads a stored number into country and number', (
      tester,
    ) async {
      await _pump(
        tester,
        {
          'p': {'type': 'string', 'x-format': 'phone'},
        },
        initial: {'p': '+4366412345678'},
      );
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('phone-number')),
      );
      expect(field.controller!.text.replaceAll(' ', ''), '66412345678');
      expect(find.text('AT +43'), findsWidgets);
    });
  });

  group('FileDataEditor', () {
    tearDown(() => FileDataEditor.picker = ({
          required bool multiple,
          List<String>? extensions,
        }) async => []);

    PickedFileData file(String name, int size) => PickedFileData(
          name: name,
          bytes: Uint8List.fromList(List.filled(size, 65)),
        );

    test('read and store round-trip', () {
      final schema = SchemaUtils.createSchema({'type': 'string'});
      final stored = FileDataEditor.store(schema, file('a b.pdf', 3));
      expect(stored, 'data:application/pdf;name=a%20b.pdf;base64,QUFB');
      final read = FileDataEditor.read(stored)!;
      expect(read.name, 'a b.pdf');
      expect(read.type, 'application/pdf');
      expect(read.bytes.length, 3);
      expect(FileDataEditor.extensionsForType('image/*'), contains('png'));
    });

    testWidgets('picks a file into an object', (tester) async {
      List<String>? asked;
      FileDataEditor.picker = ({
        required bool multiple,
        List<String>? extensions,
      }) async {
        asked = extensions;
        return [file('cv.pdf', 10)];
      };
      final form = await _pump(tester, {
        'f': {
          'type': 'object',
          'x-format': 'file-data',
          'contentMediaType': 'application/pdf',
        },
      });
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(asked, ['pdf']);
      expect(form.map['f'], {
        'name': 'cv.pdf',
        'type': 'application/pdf',
        'size': 10,
        'data': base64.encode(List.filled(10, 65)),
      });
      expect(find.text('cv.pdf'), findsOneWidget);
      expect(find.text('Replace file'), findsOneWidget);
    });

    testWidgets('rejects files over the limit', (tester) async {
      FileDataEditor.picker = ({
        required bool multiple,
        List<String>? extensions,
      }) async => [file('big.txt', 2048)];
      final form = await _pump(tester, {
        'f': {
          'type': 'string',
          'x-format': 'file-data',
          'x-max-file-size': 1024,
        },
      });
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(form.map.containsKey('f'), isFalse);
      expect(find.text('The file is larger than 1.0 KB'), findsOneWidget);
    });

    testWidgets('an array collects several files up to maxItems', (
      tester,
    ) async {
      FileDataEditor.picker = ({
        required bool multiple,
        List<String>? extensions,
      }) async {
        expect(multiple, isTrue);
        return [file('a.txt', 1), file('b.txt', 1), file('c.txt', 1)];
      };
      final form = await _pump(tester, {
        'f': {
          'type': 'array',
          'x-format': 'file-data',
          'maxItems': 2,
          'items': {'type': 'string'},
        },
      });
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect((form.map['f'] as List).length, 2);
      expect(find.text('Choose file'), findsNothing);
      await tester.tap(find.byTooltip('Remove file').first);
      await tester.pump();
      expect((form.map['f'] as List).length, 1);
    });
  });

  group('ImageGalleryEditor', () {
    const png =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

    testWidgets('shows stored pictures and removes one', (tester) async {
      final form = await _pump(
        tester,
        {
          'g': {
            'type': 'array',
            'x-format': 'image-data',
            'items': {'type': 'string'},
          },
        },
        initial: {
          'g': [png, png],
        },
      );
      expect(find.byKey(const ValueKey('image-gallery-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('image-gallery-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('image-gallery-remove-0')));
      await tester.pump();
      expect(form.map['g'], [png]);
    });

    testWidgets('hides the add tile at maxItems', (tester) async {
      await _pump(
        tester,
        {
          'g': {
            'type': 'array',
            'x-format': 'image-data',
            'maxItems': 1,
            'items': {'type': 'string'},
          },
        },
        initial: {
          'g': [png],
        },
      );
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    });
  });

  group('ConsentEditor', () {
    testWidgets('ticks, opens links and asks for consent when unticked', (
      tester,
    ) async {
      final opened = <Uri>[];
      ConsentEditor.openLink = (uri) async => opened.add(uri);
      final form = await _pump(tester, {
        'c': {
          'type': 'boolean',
          'const': true,
          'x-format': 'consent',
          'title': 'I accept the [terms](https://example.com/terms)',
        },
      });
      await tester.tap(find.byKey(const ValueKey('consent-checkbox')));
      await tester.pump();
      expect(form.map['c'], true);
      await tester.tap(find.byKey(const ValueKey('consent-checkbox')));
      await tester.pump();
      expect(form.map.containsKey('c'), isFalse);
      expect(find.text('Please agree to continue'), findsOneWidget);
      await tester.tapOnText(find.textRange.ofSubstring('terms'));
      await tester.pump();
      expect(opened, [Uri.parse('https://example.com/terms')]);
    });

    testWidgets('an optional consent stores false', (tester) async {
      final form = await _pump(tester, {
        'c': {'type': 'boolean', 'x-format': 'consent', 'title': 'News'},
      });
      await tester.tap(find.byKey(const ValueKey('consent-checkbox')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('consent-checkbox')));
      await tester.pump();
      expect(form.map['c'], false);
      expect(find.text('Please agree to continue'), findsNothing);
    });
  });

  group('TextareaEditor', () {
    testWidgets('multi-line with a counter and enforced limit', (
      tester,
    ) async {
      final form = await _pump(tester, {
        't': {
          'type': 'string',
          'x-format': 'textarea',
          'x-rows': 3,
          'maxLength': 10,
        },
      });
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('textarea')),
      );
      expect(field.minLines, 3);
      await tester.enterText(find.byKey(const ValueKey('textarea')), 'a\nb');
      await tester.pump();
      expect(form.map['t'], 'a\nb');
      expect(find.text('3/10'), findsOneWidget);
    });
  });

  group('NumberEditor units', () {
    testWidgets('shows unit and currency, reads a decimal comma', (
      tester,
    ) async {
      final form = await _pump(tester, {
        'w': {'type': 'number', 'x-unit': 'kg'},
        'p': {'type': 'number', 'x-currency': 'EUR'},
      });
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('€ '), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '1,5');
      await tester.pump();
      expect(form.map['w'], 1.5);
    });
  });

  group('StringEditor masks', () {
    testWidgets('keeps the pattern and stores the shown text', (tester) async {
      final form = await _pump(tester, {
        's': {'type': 'string', 'x-mask': '00-00'},
      });
      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.pump();
      expect(form.map['s'], '12-34');
    });

    testWidgets('x-mask-raw stores only the typed characters', (
      tester,
    ) async {
      final form = await _pump(tester, {
        's': {'type': 'string', 'x-mask': '(000) 000', 'x-mask-raw': true},
      });
      await tester.enterText(find.byType(TextFormField), '12');
      await tester.pump();
      expect(form.map['s'], '12');
      expect(find.text('Please enter it as (___) ___'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pump();
      expect(form.map['s'], '123456');
      expect(find.text('(123) 456'), findsOneWidget);
    });

    test('the formatter drops the slot before a deleted literal', () {
      final formatter = const InputMask('00-00').formatter;
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '12-3'),
        const TextEditingValue(
          text: '123',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '13');
    });
  });

  group('Layouts', () {
    final fields = {
      'name': {'type': 'string', 'title': 'Name'},
      'age': {'type': 'integer', 'title': 'Age'},
    };

    testWidgets('wizard pages, blocks incomplete steps and submits', (
      tester,
    ) async {
      final form = await _pump(tester, {
        'w': {
          'type': 'object',
          'x-layout': 'wizard',
          'required': ['name'],
          'properties': fields,
        },
      });
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Age'), findsNothing);
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Please fill in the required fields on this page'),
          findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Ada');
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      await tester.tap(find.text('Finish'));
      await tester.pump();
      expect(form.submitted, isTrue);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(form.map['w'], {'name': 'Ada'});
    });

    testWidgets('tabs switch freely and mark tabs left incomplete', (
      tester,
    ) async {
      final form = await _pump(tester, {
        'profile': {
          'type': 'object',
          'title': 'Profile',
          'x-layout': 'tabs',
          'required': ['person'],
          'properties': {
            'person': {
              'type': 'object',
              'title': 'Person',
              'description': 'Who you are',
              'required': ['name'],
              'properties': fields,
            },
            'note': {'type': 'string', 'title': 'Note'},
          },
        },
      });
      expect(find.byKey(const ValueKey('tab:person')), findsOneWidget);
      expect(find.text('Person *'), findsOneWidget);
      expect(find.text('Who you are'), findsOneWidget);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget); // the tab, not the field
      // The tab's page has no header of its own.
      expect(find.text('Person'), findsNothing);
      expect(find.byKey(const ValueKey('tab-error:person')), findsNothing);

      // Leaving a tab with missing answers is allowed, and marks it.
      await tester.tap(find.byKey(const ValueKey('tab:note')));
      await tester.pumpAndSettle();
      expect(find.text('Name *'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-error:person')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Hi');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('tab:person')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tab-error:person')), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, 'Ada');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tab:note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tab-error:person')), findsNothing);
      expect(form.map['profile'], {
        'person': {'name': 'Ada'},
        'note': 'Hi',
      });
    });

    testWidgets('collapsible starts closed with x-collapsed', (tester) async {
      await _pump(tester, {
        'c': {
          'type': 'object',
          'title': 'More',
          'x-layout': 'collapsible',
          'x-collapsed': true,
          'properties': fields,
        },
      });
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Name'), findsNothing);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('card shows the title and the fields', (tester) async {
      await _pump(tester, {
        'c': {
          'type': 'object',
          'title': 'Person',
          'x-layout': 'card',
          'properties': fields,
        },
      });
      expect(find.byType(Card), findsWidgets);
      expect(find.text('Person'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });
  });

  group('Form logic', () {
    testWidgets('hidden fields keep their value but show nothing', (
      tester,
    ) async {
      final form = await _pump(
        tester,
        {
          'source': {'type': 'string', 'title': 'Source', 'x-hidden': true},
          'name': {'type': 'string', 'title': 'Name'},
        },
        initial: {'source': 'newsletter'},
      );
      expect(find.text('Source'), findsNothing);
      await tester.enterText(find.byType(TextFormField), 'Ada');
      await tester.pump();
      expect(form.map, {'source': 'newsletter', 'name': 'Ada'});
    });

    testWidgets('calculated fields follow their inputs', (tester) async {
      final form = await _pump(tester, {
        'qty': {'type': 'integer', 'title': 'Qty'},
        'total': {
          'type': 'number',
          'title': 'Total',
          'readOnly': true,
          'x-calc': {
            '*': [
              {'var': 'qty'},
              2.5,
            ],
          },
        },
      });
      await tester.enterText(find.byType(TextFormField).first, '4');
      await tester.pump();
      expect(form.map['total'], 10);
      final total = tester.widget<TextFormField>(
        find.byType(TextFormField).last,
      );
      expect(total.controller!.text, '10');
    });

    testWidgets('titles pipe in earlier answers', (tester) async {
      await _pump(tester, {
        'name': {'type': 'string', 'title': 'Name'},
        'why': {'type': 'string', 'title': 'Why did you join, {{name}}?'},
      });
      expect(find.text('Why did you join, …?'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Ada');
      await tester.pump();
      expect(find.text('Why did you join, Ada?'), findsOneWidget);
    });
  });
}
