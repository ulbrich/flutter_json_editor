// Renders the README's editor screenshots into ../doc/images/ from the
// example's own schema (assets/schemas/en.json), with real fonts.
//
// Not part of `flutter test` (which only runs test/); run it on purpose:
//
//   cd example && flutter test screenshots
//
// The images change with the Flutter/Material version, so they are made by
// hand and committed rather than compared in CI.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader, Uint8List;
import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Logical width of every screenshot.
const double _width = 480;

/// Pixels per logical pixel in the PNGs.
const double _pixelRatio = 2;

/// Where the PNGs go, relative to example/.
const String _outDir = '../doc/images';

/// One screenshot: the example fields it shows and their values.
class _Shot {
  const _Shot(this.name, this.fields, [this._data = const {}])
      : _lazyData = null;

  /// A shot whose data is only known once [setUpAll] has run.
  const _Shot.lazy(this.name, this.fields, this._lazyData) : _data = const {};

  final String name;
  final List<String> fields;
  final Map<String, dynamic> _data;
  final Map<String, dynamic> Function()? _lazyData;

  Map<String, dynamic> get data => _lazyData?.call() ?? _data;
}

final _shots = <_Shot>[
  const _Shot('slider', ['workload'], {'workload': 80}),
  const _Shot(
    'stepper',
    ['deskCount', 'officeDays'],
    {'deskCount': 2, 'officeDays': 2.5},
  ),
  const _Shot(
    'segmented',
    ['workMode', 'shirtSize'],
    {'workMode': 'hybrid', 'shirtSize': 'M'},
  ),
  const _Shot('chips', [
    'languages',
  ], {
    'languages': ['en', 'de'],
  }),
  const _Shot(
    'duration',
    ['weeklyHours', 'dailyBreak'],
    {'weeklyHours': 'PT38H30M', 'dailyBreak': 1800},
  ),
  _Shot('signature', ['signature'], {'signature': _sampleSignature()}),
  _Shot.lazy('image-data', ['photo'], () => {'photo': _samplePhoto}),
  const _Shot(
    'scales',
    ['satisfaction', 'recommend', 'mood'],
    {'satisfaction': 4, 'recommend': 9, 'mood': 4},
  ),
  const _Shot('matrix', [
    'engagement',
  ], {
    'engagement': {'tools': 'agree', 'team': 'neutral'},
  }),
  const _Shot('ranking', [
    'priorities',
  ], {
    'priorities': ['team', 'growth', 'salary', 'remote'],
  }),
  const _Shot('date-range', [
    'vacation',
  ], {
    'vacation': {'start': '2026-12-21', 'end': '2027-01-03'},
  }),
  const _Shot('phone', ['mobile'], {'mobile': '+4915112345678'}),
  _Shot('file-data', ['documents'], {'documents': _sampleDocuments()}),
  _Shot.lazy(
    'image-gallery',
    ['teamPhotos'],
    () => {
      'teamPhotos': [_samplePhoto, _samplePhoto, _samplePhoto],
    },
  ),
  const _Shot(
    'units',
    ['commute', 'commuteYearly', 'salary', 'bonusRate'],
    {'commute': 12.5, 'officeDays': 3, 'salary': 62000, 'bonusRate': 7.5},
  ),
  const _Shot('textarea', [
    'feedback',
  ], {
    'feedback': 'The new office is great, but the coffee could be better.',
  }),
  const _Shot('sections', [
    'emergencyContact',
    'bank',
  ], {
    'emergencyContact': {'name': 'John Doe', 'phone': '+4930123456'},
    'bank': {'holder': 'Jane Doe', 'iban': 'DE89370400440532013000'},
  }),
  const _Shot('wizard', [
    'onboarding',
  ], {
    'onboarding': {
      'you': {'team': 'Engineering', 'buddy': 'Sam'},
    },
  }),
  const _Shot('tabs', [
    'workplace',
  ], {
    'workplace': {
      'office': {'building': 'Campus', 'floor': 3, 'desk': 'B-114'},
    },
  }),
  const _Shot('consent', [
    'consent',
  ]),
];

/// A PDF and a picture as the file editor stores them (sizes made up).
List<dynamic> _sampleDocuments() {
  final schema = SchemaUtils.createSchema({'type': 'object'});
  PickedFileData file(String name, int size) =>
      PickedFileData(name: name, bytes: Uint8List(size));
  return [
    FileDataEditor.store(schema, file('cv-jane-doe.pdf', 48213)),
    FileDataEditor.store(schema, file('certificate.png', 612000)),
  ];
}

/// A drawn landscape as a data URI, standing in for a photo; made in
/// [setUpAll] because encoding a PNG is asynchronous.
late String _samplePhoto;

Future<String> _drawSamplePhoto() async {
  const size = Size(640, 400);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        const [Color(0xFF7FB3E6), Color(0xFFF3D9B1)],
      ),
  );
  canvas.drawCircle(
    const Offset(470, 120),
    48,
    Paint()..color = const Color(0xFFFFF4C2),
  );
  Path hill(double base, double amplitude, double phase) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8) {
      path.lineTo(
          x, base - amplitude * math.sin(x / size.width * math.pi + phase));
    }
    return path
      ..lineTo(size.width, size.height)
      ..close();
  }

  canvas.drawPath(hill(250, 90, 0.3), Paint()..color = const Color(0xFF5C7F9E));
  canvas.drawPath(hill(300, 60, 1.6), Paint()..color = const Color(0xFF3F6B57));
  canvas.drawRect(
    Rect.fromLTWH(0, 330, size.width, 70),
    Paint()..color = const Color(0xFF2E5845),
  );
  final image = await recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return ImageDataEditor.encode(png!.buffer.asUint8List());
}

/// A cursive-looking scribble with an underline, as the pad would store it.
String _sampleSignature() {
  final loops = <Offset>[
    for (var i = 0; i <= 240; i++)
      () {
        final t = i / 240;
        final phase = t * 9 * math.pi;
        return Offset(
          70 + 430 * t + 26 * math.cos(phase),
          105 - 48 * math.sin(phase) * (1 - 0.35 * t) + 12 * t,
        );
      }(),
  ];
  final underline = <Offset>[
    for (var i = 0; i <= 40; i++)
      Offset(60 + 12 * i.toDouble(), 168 - 10 * math.sin(i / 40 * math.pi)),
  ];
  return SignatureEditor.toSvg([loops, underline])!;
}

/// The Flutter SDK's bundled Material fonts (Roboto, MaterialIcons).
Directory _materialFonts() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    return Directory('$root/bin/cache/artifacts/material_fonts');
  }
  // …/bin/cache/artifacts/engine/<platform>/flutter_tester
  var dir = File(Platform.resolvedExecutable).parent;
  while (!dir.path.endsWith('${Platform.pathSeparator}artifacts')) {
    dir = dir.parent;
  }
  return Directory('${dir.path}/material_fonts');
}

Future<void> _loadFonts() async {
  final fonts = _materialFonts();
  Future<ByteData> bytes(String file) async =>
      ByteData.sublistView(await File('${fonts.path}/$file').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final file in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(bytes(file));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(bytes('MaterialIcons-Regular.otf')))
      .load();
}

void main() {
  late Map<String, dynamic> schema;

  setUpAll(() async {
    await _loadFonts();
    schema = jsonDecode(File('assets/schemas/en.json').readAsStringSync())
        as Map<String, dynamic>;
    Directory(_outDir).createSync(recursive: true);
    _samplePhoto = await _drawSamplePhoto();
  });

  for (final shot in _shots) {
    testWidgets('screenshot ${shot.name}', (tester) async {
      tester.view.devicePixelRatio = _pixelRatio;
      tester.view.physicalSize = const Size(_width, 1600) * _pixelRatio;
      addTearDown(tester.view.reset);

      final properties = schema['properties'] as Map<String, dynamic>;
      final fieldSchema = SchemaUtils.createSchema({
        r'$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'properties': {
          for (final f in shot.fields)
            f: properties[f] ??
                (properties['onboarding']['properties'] as Map)[f == 'consent'
                    ? 'privacy'
                    : f],
        },
      });
      final boundary = GlobalKey();

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        localizationsDelegates: const [
          JsonEditorLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: JsonEditorLocalizations.supportedLocales,
        home: Scaffold(
          // Unbounded height, so the shot is only as tall as the fields.
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color:
                    ThemeData(colorSchemeSeed: Colors.blue).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: JsonEditor(
                    schema: fieldSchema,
                    initialData: shot.data,
                    onUpdate: (data, diff) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // Decode pictures for real, which the fake test clock never does.
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: _pixelRatio);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('$_outDir/${shot.name}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}
