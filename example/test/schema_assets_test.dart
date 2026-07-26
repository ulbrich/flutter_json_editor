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

      // The whole schema is accepted by the package without throwing.
      expect(SchemaUtils.createSchema(Map<String, dynamic>.from(raw)), isNotNull);
    });
  }

  test('avatar_lookup.json loads with an enumSource of avatars', () async {
    final raw = await loadAsset('assets/schemas/avatar_lookup.json');
    expect((raw['enumSource'] as List).first['source'], hasLength(6));
  });
}
