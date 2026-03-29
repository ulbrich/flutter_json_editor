import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'package:flutter_json_editor/flutter_json_editor.dart';

void main() {
  group('DiffCalculator', () {
    test('returns empty diff for identical maps', () {
      final a = {'name': 'Alice', 'age': 30};
      final b = {'name': 'Alice', 'age': 30};
      expect(DiffCalculator.diff(a, b), isEmpty);
    });

    test('detects additions', () {
      final a = <String, dynamic>{};
      final b = {'name': 'Alice'};
      expect(DiffCalculator.diff(a, b), {'name': 'Alice'});
    });

    test('detects removals as null', () {
      final a = {'name': 'Alice'};
      final b = <String, dynamic>{};
      expect(DiffCalculator.diff(a, b), {'name': null});
    });

    test('detects modifications', () {
      final a = {'age': 30};
      final b = {'age': 31};
      expect(DiffCalculator.diff(a, b), {'age': 31});
    });

    test('handles nested maps', () {
      final a = {
        'address': {'city': 'Berlin', 'zip': '10115'}
      };
      final b = {
        'address': {'city': 'Munich', 'zip': '10115'}
      };
      expect(DiffCalculator.diff(a, b), {
        'address': {'city': 'Munich'}
      });
    });

    test('treats lists as atomic — returns full new list when changed', () {
      final a = {
        'tags': ['a', 'b']
      };
      final b = {
        'tags': ['a', 'b', 'c']
      };
      expect(DiffCalculator.diff(a, b), {
        'tags': ['a', 'b', 'c']
      });
    });

    test('handles null previous', () {
      final b = {'x': 1};
      expect(DiffCalculator.diff(null, b), {'x': 1});
    });

    test('handles null current', () {
      final a = {'x': 1};
      expect(DiffCalculator.diff(a, null), {'x': null});
    });
  });

  group('SchemaUtils', () {
    test('detectType returns single type', () {
      final schema = JsonSchema.create({'type': 'string'});
      expect(SchemaUtils.detectType(schema), SchemaType.string);
    });

    test('isNullable returns false for non-nullable schema', () {
      final schema = JsonSchema.create({'type': 'string'});
      expect(SchemaUtils.isNullable(schema), isFalse);
    });

    test('isNullable returns true for nullable union type', () {
      final schema = JsonSchema.create({
        'type': ['string', 'null']
      });
      expect(SchemaUtils.isNullable(schema), isTrue);
    });

    test('detectType extracts non-null type from union', () {
      final schema = JsonSchema.create({
        'type': ['string', 'null']
      });
      expect(SchemaUtils.detectType(schema), SchemaType.string);
    });
  });

  group('EditorRegistryData', () {
    test('resolve returns null when no overrides', () {
      final registry = EditorRegistryData();
      final schema = JsonSchema.create({'type': 'string'});
      expect(registry.resolve(schema, '/name'), isNull);
    });

    test('merge combines path overrides', () {
      builder({
        required schema,
        required path,
        required value,
        required onChanged,
        required isRequired,
        isNullable = false,
      }) =>
          throw UnimplementedError();

      final a = EditorRegistryData(pathOverrides: {'/a': builder});
      final b = EditorRegistryData(pathOverrides: {'/b': builder});
      final merged = a.merge(b);
      final schema = JsonSchema.create({'type': 'string'});
      expect(merged.resolve(schema, '/a'), isNotNull);
      expect(merged.resolve(schema, '/b'), isNotNull);
    });
  });
}
