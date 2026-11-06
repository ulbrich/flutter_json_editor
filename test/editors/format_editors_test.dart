import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

Widget _wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        JsonEditorLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: JsonEditorLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Map<String, dynamic> _schema(String name, Map<String, dynamic> field) => {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': {name: field},
    };

/// Pumps a [JsonEditor] for one field and returns a getter for the last data
/// it reported.
Future<Map Function()> _pump(
  WidgetTester tester,
  String name,
  Map<String, dynamic> field, {
  Map<String, dynamic>? initialData,
  Locale? locale,
}) async {
  dynamic data = initialData;
  await tester.pumpWidget(_wrap(
    JsonEditor(
      schema: SchemaUtils.createSchema(_schema(name, field)),
      initialData: initialData,
      onUpdate: (full, _) => data = full,
    ),
    locale: locale,
  ));
  return () => (data ?? const {}) as Map;
}

void main() {
  group('slider', () {
    Map<String, dynamic> volume() => {
          'type': 'integer',
          'title': 'Volume',
          'x-format': 'slider',
          'minimum': 0,
          'maximum': 10,
        };

    testWidgets('reads — while empty and sets a whole number on drag',
        (tester) async {
      final data = await _pump(tester, 'volume', volume());
      expect(find.byType(SliderEditor), findsOneWidget);
      expect(find.byKey(const ValueKey('slider-value')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('slider-value'))).data,
        '—',
      );

      await tester.drag(find.byType(Slider), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(data()['volume'], 10);
      expect(data()['volume'], isA<int>());
    });

    testWidgets('shows the stored value and the range', (tester) async {
      await _pump(tester, 'volume', volume(), initialData: {'volume': 4});
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('slider-value'))).data,
        '4',
      );
      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 10);
    });

    testWidgets('falls back to the usual editor for strings', (tester) async {
      await _pump(tester, 'name', {
        'type': 'string',
        'title': 'Name',
        'x-format': 'slider',
      });
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('stepper', () {
    Map<String, dynamic> guests() => {
          'type': 'integer',
          'title': 'Guests',
          'x-format': 'stepper',
          'minimum': 1,
          'maximum': 3,
        };

    testWidgets('starts at the minimum and stays within the range',
        (tester) async {
      final data = await _pump(tester, 'guests', guests());
      expect(find.byType(StepperEditor), findsOneWidget);

      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      expect(data()['guests'], 1);

      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      expect(data()['guests'], 3);

      final plus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(plus.onPressed, isNull);

      await tester.tap(find.byTooltip('Decrease'));
      await tester.pump();
      expect(data()['guests'], 2);
    });

    testWidgets('moves by multipleOf for numbers', (tester) async {
      final data = await _pump(
        tester,
        'dose',
        {'type': 'number', 'x-format': 'stepper', 'multipleOf': 0.5},
        initialData: {'dose': 1.5},
      );
      await tester.tap(find.byTooltip('Increase'));
      await tester.pump();
      expect(data()['dose'], 2.0);
    });
  });

  group('segmented', () {
    Map<String, dynamic> priority() => {
          'type': 'string',
          'title': 'Priority',
          'x-format': 'segmented',
          'oneOf': [
            {'const': 'low', 'title': 'Low'},
            {'const': 'high', 'title': 'High'},
          ],
        };

    testWidgets('picks a segment and clears it again', (tester) async {
      final data = await _pump(tester, 'priority', priority());
      expect(find.byType(SegmentedButton<int>), findsOneWidget);

      await tester.tap(find.text('High'));
      await tester.pump();
      expect(data()['priority'], 'high');

      await tester.tap(find.text('High'));
      await tester.pump();
      expect(data()['priority'], isNull);
    });

    testWidgets('uses enum values as labels', (tester) async {
      final data = await _pump(tester, 'size', {
        'type': 'string',
        'x-format': 'segmented',
        'enum': ['S', 'M', 'L'],
      });
      await tester.tap(find.text('M'));
      await tester.pump();
      expect(data()['size'], 'M');
    });

    testWidgets('falls back to the usual editor without choices',
        (tester) async {
      await _pump(tester, 'note', {'type': 'string', 'x-format': 'segmented'});
      expect(find.byType(SegmentedButton<int>), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('chips', () {
    Map<String, dynamic> allergens() => {
          'type': 'array',
          'title': 'Allergens',
          'x-format': 'chips',
          'uniqueItems': true,
          'maxItems': 2,
          'items': {
            'type': 'string',
            'oneOf': [
              {'const': 'gluten', 'title': 'Gluten'},
              {'const': 'nuts', 'title': 'Nuts'},
              {'const': 'milk', 'title': 'Milk'},
            ],
          },
        };

    testWidgets('toggles values in the order of the choices', (tester) async {
      final data = await _pump(tester, 'allergens', allergens());
      expect(find.byType(FilterChip), findsNWidgets(3));

      await tester.tap(find.text('Milk'));
      await tester.pump();
      await tester.tap(find.text('Gluten'));
      await tester.pump();
      expect(data()['allergens'], ['gluten', 'milk']);

      // maxItems reached: the third chip is disabled.
      final nuts = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Nuts'),
      );
      expect(nuts.onSelected, isNull);

      await tester.tap(find.text('Gluten'));
      await tester.pump();
      expect(data()['allergens'], ['milk']);
    });

    testWidgets('keeps values the choices do not know', (tester) async {
      final data = await _pump(
        tester,
        'allergens',
        allergens(),
        initialData: {
          'allergens': ['soy'],
        },
      );
      await tester.tap(find.text('Nuts'));
      await tester.pump();
      expect(data()['allergens'], ['nuts', 'soy']);
    });

    testWidgets('shows minItems errors', (tester) async {
      final schema = allergens()..['minItems'] = 2;
      await _pump(
        tester,
        'allergens',
        schema,
        initialData: {
          'allergens': ['nuts'],
        },
      );
      expect(find.text('minItems violated (1 vs 2)'), findsOneWidget);
    });

    testWidgets('falls back to the array editor without choices',
        (tester) async {
      await _pump(tester, 'tags', {
        'type': 'array',
        'x-format': 'chips',
        'items': {'type': 'string'},
      });
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byTooltip('Add item'), findsOneWidget);
    });
  });

  group('duration', () {
    test('parses and formats ISO 8601 durations', () {
      expect(DurationEditor.parseIso8601('PT1H30M'), 5400);
      expect(DurationEditor.parseIso8601('P1DT2H'), 93600);
      expect(DurationEditor.parseIso8601('P1W'), 604800);
      expect(DurationEditor.parseIso8601('PT45S'), 45);
      expect(DurationEditor.parseIso8601('P1M'), isNull);
      expect(DurationEditor.parseIso8601('PT'), isNull);
      expect(DurationEditor.parseIso8601('90'), isNull);
      expect(DurationEditor.formatIso8601(5400), 'PT1H30M');
      expect(DurationEditor.formatIso8601(3600), 'PT1H');
      expect(DurationEditor.formatIso8601(0), 'PT0M');
      expect(DurationEditor.formatIso8601(3725), 'PT1H2M5S');
    });

    testWidgets('stores an ISO 8601 string for the standard format',
        (tester) async {
      final data = await _pump(
        tester,
        'effort',
        {'type': 'string', 'title': 'Effort', 'format': 'duration'},
        initialData: {'effort': 'P1DT2H'},
      );
      expect(find.byType(DurationEditor), findsOneWidget);
      expect(find.widgetWithText(TextField, '26'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '90');
      await tester.pump();
      expect(data()['effort'], 'PT27H30M');

      await tester.enterText(find.widgetWithText(TextField, 'Hours'), '');
      await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '');
      await tester.pump();
      expect(data()['effort'], isNull);
    });

    testWidgets('stores seconds for integers', (tester) async {
      final data = await _pump(tester, 'pause', {
        'type': 'integer',
        'x-format': 'duration',
      });
      await tester.enterText(find.widgetWithText(TextField, 'Hours'), '1');
      await tester.pump();
      expect(data()['pause'], 3600);
    });

    testWidgets('is localized', (tester) async {
      await _pump(
        tester,
        'pause',
        {'type': 'integer', 'x-format': 'duration'},
        locale: const Locale('de'),
      );
      expect(find.text('Stunden'), findsOneWidget);
      expect(find.text('Minuten'), findsOneWidget);
    });
  });

  group('signature', () {
    test('round-trips strokes through SVG', () {
      final strokes = [
        [const Offset(10, 20), const Offset(30.26, 40)],
        [const Offset(50, 60)],
      ];
      final svg = SignatureEditor.toSvg(strokes)!;
      expect(svg, startsWith('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('d="M10 20 L30.3 40 M50 60 L50 60"'));
      final parsed = SignatureEditor.parseSvg(svg);
      expect(parsed, hasLength(2));
      expect(parsed.first.last, const Offset(30.3, 40));
      expect(SignatureEditor.toSvg(const []), isNull);
      expect(SignatureEditor.parseSvg('<svg/>'), isEmpty);
    });

    testWidgets('draws a stroke, undoes it', (tester) async {
      final data = await _pump(tester, 'sig', {
        'type': 'string',
        'title': 'Signature',
        'x-format': 'signature',
      });
      expect(find.text('Sign here'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('signature-pad')),
        const Offset(120, 30),
      );
      await tester.pump();
      final svg = data()['sig'] as String;
      expect(svg, contains('<path d="M'));
      expect(SignatureEditor.parseSvg(svg), hasLength(1));
      expect(find.text('Sign here'), findsNothing);

      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(data()['sig'], isNull);
      expect(find.text('Sign here'), findsOneWidget);
    });

    testWidgets('keeps a stored signature and adds strokes to it',
        (tester) async {
      final stored = SignatureEditor.toSvg([
        [const Offset(10, 10), const Offset(100, 100)],
      ]);
      final data = await _pump(
        tester,
        'sig',
        {'type': 'string', 'x-format': 'signature'},
        initialData: {'sig': stored},
      );
      expect(find.text('Sign here'), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey('signature-pad')),
        const Offset(50, 0),
      );
      await tester.pump();
      expect(SignatureEditor.parseSvg(data()['sig'] as String), hasLength(2));

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(data()['sig'], isNull);
    });
  });
}
