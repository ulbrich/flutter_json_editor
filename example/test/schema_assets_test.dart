// Verifies the example's schemas load from JSON assets and build via
// SchemaUtils — and that `hobby` resolves through a local `$defs` `$ref`
// (enumSource), not the old remote URL `$ref`.
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, dynamic>> loadAsset(String path) async =>
      jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;

  for (final locale in <String>['en', 'de']) {
    test('$locale.json loads, uses a local \$defs hobby ref, and builds',
        () async {
      final raw = await loadAsset('assets/schemas/$locale.json');

      // hobby: bare local $ref into $defs (title/enumSource live in the def).
      expect(raw['properties']['hobby'], <String, dynamic>{r'$ref': r'#/$defs/hobby'});
      final hobbyDef = raw[r'$defs']['hobby'] as Map<String, dynamic>;
      expect(hobbyDef['title'], 'Hobby');
      expect((hobbyDef['enumSource'] as List).first['source'], hasLength(10));

      // avatar stays a remote-style $ref (resolved via onRefLookup).
      expect(
        raw['properties']['avatar'][r'$ref'],
        'https://example.com/api/avatars',
      );

      // employeeType is a standards-compliant labeled oneOf (const + title).
      final oneOf = raw['properties']['employeeType']['oneOf'] as List;
      expect(oneOf, hasLength(4));
      expect(
        oneOf.every((b) =>
            (b as Map).containsKey('const') && b.containsKey('title')),
        isTrue,
      );

      // One sample per built-in input editor, plus a variant each.
      final props = raw['properties'] as Map<String, dynamic>;
      String? format(String key) =>
          (props[key]['x-format'] ?? props[key]['format']) as String?;
      expect(format('workload'), 'slider');
      expect(format('deskCount'), 'stepper');
      expect(format('officeDays'), 'stepper');
      expect(props['officeDays']['multipleOf'], 0.5);
      expect(format('workMode'), 'segmented');
      expect(format('shirtSize'), 'segmented');
      expect(props['shirtSize']['enum'], ['S', 'M', 'L', 'XL']);
      expect(format('languages'), 'chips');
      expect(props['languages']['items']['oneOf'], hasLength(4));
      expect(format('weeklyHours'), 'duration');
      expect(props['weeklyHours']['type'], 'string');
      expect(format('dailyBreak'), 'duration');
      expect(props['dailyBreak']['type'], 'integer');
      expect(format('signature'), 'signature');
      expect(format('photo'), 'image-data');
      expect(format('satisfaction'), 'linear-scale');
      expect(format('recommend'), 'nps');
      expect(format('mood'), 'emoji-scale');
      expect(format('engagement'), 'matrix');
      expect(format('priorities'), 'ranking');
      expect(format('vacation'), 'date-range');
      expect(format('mobile'), 'phone');
      expect(format('documents'), 'file-data');
      expect(format('teamPhotos'), 'image-data');
      expect(props['teamPhotos']['type'], 'array');
      expect(format('feedback'), 'textarea');
      expect(props['commute']['x-unit'], 'km');
      expect(props['salary']['x-currency'], 'EUR');
      expect(props['commuteYearly']['x-calc'], isA<Map>());
      expect(props['source']['x-hidden'], isTrue);
      expect(props['bank']['properties']['iban']['x-mask'], isA<String>());
      expect(props['emergencyContact']['x-layout'], 'card');
      expect(props['bank']['x-layout'], 'collapsible');
      expect(props['onboarding']['x-layout'], 'wizard');
      expect(props['workplace']['x-layout'], 'tabs');
      expect(
        props['onboarding']['properties']['privacy']['x-format'],
        'consent',
      );

      // The whole schema is accepted by the package without throwing.
      expect(SchemaUtils.createSchema(Map<String, dynamic>.from(raw)), isNotNull);
    });
  }

  test('avatar_lookup.json loads with an enumSource of avatars', () async {
    final raw = await loadAsset('assets/schemas/avatar_lookup.json');
    expect((raw['enumSource'] as List).first['source'], hasLength(6));
  });
}
