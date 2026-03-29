import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

void main() {
  group('SchemaUtils.resolveRef', () {
    test('returns schema unchanged when ref is null', () {
      final schema = JsonSchema.create({'type': 'string'});
      final resolved = SchemaUtils.resolveRef(schema);
      expect(resolved, same(schema));
    });

    test('returns schema unchanged when root is null (no ref to follow)', () {
      final schema = JsonSchema.create({'type': 'object'});
      final resolved = SchemaUtils.resolveRef(schema);
      expect(resolved, same(schema));
    });
  });

  group('SchemaUtils.maxRefDepth', () {
    test('maxRefDepth is 3', () {
      expect(SchemaUtils.maxRefDepth, equals(3));
    });
  });

  group('SchemaUtils.detectType with typeList', () {
    test('returns non-null type from union [string, null]', () {
      final schema = JsonSchema.create({
        'type': ['string', 'null'],
      });
      expect(SchemaUtils.detectType(schema), SchemaType.string);
    });

    test('returns non-null type from union [integer, null]', () {
      final schema = JsonSchema.create({
        'type': ['integer', 'null'],
      });
      expect(SchemaUtils.detectType(schema), SchemaType.integer);
    });

    test('returns null when typeList has multiple non-null types', () {
      final schema = JsonSchema.create({
        'type': ['string', 'integer'],
      });
      expect(SchemaUtils.detectType(schema), isNull);
    });

    test('returns direct type when schema.type is set', () {
      final schema = JsonSchema.create({'type': 'boolean'});
      expect(SchemaUtils.detectType(schema), SchemaType.boolean);
    });

    test('returns null when no type is set', () {
      final schema = JsonSchema.create({});
      expect(SchemaUtils.detectType(schema), isNull);
    });
  });
}
