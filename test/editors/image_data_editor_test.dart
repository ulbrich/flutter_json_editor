import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter/material.dart';

/// A 1×1 PNG.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

/// The picker the editor talks to, without a platform behind it.
class _FakePicker extends ImagePickerPlatform {
  XFile? next;
  Object? error;
  bool camera = true;
  ImageSource? lastSource;
  ImagePickerOptions? lastOptions;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    lastOptions = options;
    if (error != null) throw error!;
    return next;
  }

  @override
  bool supportsImageSource(ImageSource source) =>
      source == ImageSource.gallery || camera;
}

Widget _wrap(Widget child, {Locale? locale}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    JsonEditorLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: JsonEditorLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<Map Function()> _pump(
  WidgetTester tester,
  Map<String, dynamic> field, {
  dynamic initial,
  Locale? locale,
}) async {
  dynamic data = initial == null ? null : {'photo': initial};
  await tester.pumpWidget(
    _wrap(
      JsonEditor(
        schema: SchemaUtils.createSchema({
          r'$schema': 'http://json-schema.org/draft-07/schema#',
          'type': 'object',
          'properties': {'photo': field},
        }),
        initialData: data as Map<String, dynamic>?,
        onUpdate: (full, diff) => data = full,
      ),
      locale: locale,
    ),
  );
  return () => (data ?? const {}) as Map;
}

Map<String, dynamic> _photo([Map<String, dynamic> extra = const {}]) => {
  'type': 'string',
  'title': 'Photo',
  'x-format': 'image-data',
  ...extra,
};

/// Lets the picker's future and the file read complete.
Future<void> _settlePick(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

void main() {
  late _FakePicker picker;

  setUp(() {
    picker = _FakePicker()
      ..next = XFile.fromData(base64.decode(_png), name: 'dot.png');
    ImagePickerPlatform.instance = picker;
  });

  group('codec', () {
    test('decodes data URIs and plain, URL-safe or unpadded base64', () {
      final bytes = base64.decode(_png);
      expect(ImageDataEditor.decode('data:image/png;base64,$_png'), bytes);
      expect(ImageDataEditor.decode(_png), bytes);
      expect(ImageDataEditor.decode(_png.replaceAll('=', '')), bytes);
      expect(ImageDataEditor.decode(' $_png\n'), bytes);
      expect(ImageDataEditor.decode('data:image/png,abc'), isNull);
      expect(ImageDataEditor.decode('not base64!'), isNull);
      expect(ImageDataEditor.decode(''), isNull);
      expect(ImageDataEditor.decode(null), isNull);
    });

    test('recognises image types by their signature', () {
      Uint8List bytes(List<int> b) => Uint8List.fromList([...b, 0, 0, 0, 0]);
      expect(ImageDataEditor.mimeTypeOf(base64.decode(_png)), 'image/png');
      expect(
        ImageDataEditor.mimeTypeOf(bytes([0xFF, 0xD8, 0xFF])),
        'image/jpeg',
      );
      expect(
        ImageDataEditor.mimeTypeOf(bytes(ascii.encode('GIF89a'))),
        'image/gif',
      );
      expect(
        ImageDataEditor.mimeTypeOf(
          bytes([...ascii.encode('RIFF'), 0, 0, 0, 0, ...ascii.encode('WEBP')]),
        ),
        'image/webp',
      );
      expect(
        ImageDataEditor.mimeTypeOf(
          bytes([0, 0, 0, 0x18, ...ascii.encode('ftypheic')]),
        ),
        'image/heic',
      );
      expect(ImageDataEditor.mimeTypeOf(bytes([1, 2, 3])), isNull);
    });

    test('encodes as data URI or plain base64', () {
      final bytes = base64.decode(_png);
      expect(ImageDataEditor.encode(bytes), 'data:image/png;base64,$_png');
      expect(ImageDataEditor.encode(bytes, dataUri: false), _png);
      expect(
        ImageDataEditor.encode(
          Uint8List.fromList([1, 2]),
          mimeType: 'image/x-custom',
        ),
        'data:image/x-custom;base64,AQI=',
      );
    });
  });

  testWidgets('picks a picture from the library as a data URI', (tester) async {
    final data = await _pump(tester, _photo());
    expect(find.byType(ImageDataEditor), findsOneWidget);
    expect(
      find.byKey(const ValueKey('image-data-placeholder')),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove picture'), findsNothing);

    await tester.tap(find.text('Choose picture'));
    await _settlePick(tester);

    expect(picker.lastSource, ImageSource.gallery);
    expect(picker.lastOptions!.maxWidth, 1024);
    expect(picker.lastOptions!.maxHeight, 1024);
    expect(picker.lastOptions!.imageQuality, 85);
    expect(data()['photo'], 'data:image/png;base64,$_png');
    expect(find.byKey(const ValueKey('image-data-preview')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('image-data-info'))).data,
      'PNG · 0.1 KB',
    );

    await tester.tap(find.byTooltip('Remove picture'));
    await tester.pump();
    expect(data()['photo'], isNull);
    expect(
      find.byKey(const ValueKey('image-data-placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('takes a photo and stores plain base64 for contentEncoding', (
    tester,
  ) async {
    final data = await _pump(
      tester,
      _photo({
        'contentEncoding': 'base64',
        'contentMediaType': 'image/png',
        'x-max-width': 640,
        'x-image-quality': 70,
      }),
    );
    await tester.tap(find.text('Take photo'));
    await _settlePick(tester);

    expect(picker.lastSource, ImageSource.camera);
    expect(picker.lastOptions!.maxWidth, 640);
    expect(picker.lastOptions!.maxHeight, 1024);
    expect(picker.lastOptions!.imageQuality, 70);
    expect(data()['photo'], _png);
  });

  testWidgets('offers no camera where the platform has none', (tester) async {
    picker.camera = false;
    await _pump(tester, _photo());
    expect(find.text('Choose picture'), findsOneWidget);
    expect(find.text('Take photo'), findsNothing);
  });

  testWidgets('keeps the value when picking is cancelled', (tester) async {
    picker.next = null;
    final data = await _pump(tester, _photo(), initial: _png);
    await tester.tap(find.text('Choose picture'));
    await _settlePick(tester);
    expect(data()['photo'], _png);
  });

  testWidgets('shows an error when picking fails', (tester) async {
    picker.error = Exception('camera_access_denied');
    await _pump(tester, _photo());
    await tester.tap(find.text('Take photo'));
    await _settlePick(tester);
    expect(find.text('The picture could not be loaded'), findsOneWidget);
  });

  testWidgets('shows a stored picture', (tester) async {
    await _pump(tester, _photo(), initial: 'data:image/png;base64,$_png');
    expect(find.byKey(const ValueKey('image-data-preview')), findsOneWidget);
    expect(find.text('Invalid image data'), findsNothing);
  });

  testWidgets('flags stored data that is not a picture', (tester) async {
    await _pump(tester, _photo(), initial: 'not base64!');
    expect(find.text('Invalid image data'), findsOneWidget);
  });

  testWidgets('hides the buttons when read-only', (tester) async {
    await _pump(tester, _photo({'readOnly': true}), initial: _png);
    expect(find.byKey(const ValueKey('image-data-preview')), findsOneWidget);
    expect(find.text('Choose picture'), findsNothing);
    expect(find.byTooltip('Remove picture'), findsNothing);
  });

  testWidgets('falls back to the usual editor for non-strings', (tester) async {
    await _pump(tester, {'type': 'integer', 'x-format': 'image-data'});
    expect(find.byType(ImageDataEditor), findsOneWidget);
    expect(find.text('Choose picture'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('is localized', (tester) async {
    await _pump(tester, _photo(), locale: const Locale('de'));
    expect(find.text('Bild auswählen'), findsOneWidget);
    expect(find.text('Foto aufnehmen'), findsOneWidget);
  });
}
