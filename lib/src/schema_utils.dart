import 'package:json_schema/json_schema.dart';

class SchemaUtils {
  /// Maximum $ref follow depth before treating as circular reference.
  static const int maxRefDepth = 3;

  /// Resolves a $ref in the given schema.
  ///
  /// json_schema ^5.2.2 resolves $ref internally during JsonSchema.create()
  /// for Draft 7, so schema.properties already contains resolved schemas.
  /// However, if schema.ref is set, we follow it explicitly via resolvePath.
  ///
  /// Handles cross-draft compatibility: if a schema uses `$defs` (Draft 2019-09+)
  /// but is parsed as Draft 4/6/7 (which only recognizes `definitions`), this
  /// method falls back to manual lookup in the raw schema map and vice versa.
  static JsonSchema resolveRef(JsonSchema schema) {
    if (schema.ref == null || schema.root == null) return schema;

    // Try standard resolvePath first
    try {
      return schema.root!.resolvePath(schema.ref!);
    } catch (_) {
      // Standard resolution failed — try cross-draft fallback
    }

    // Fallback: manual lookup for $defs / definitions mismatch
    final refStr = schema.ref.toString();
    final root = schema.root!;

    // Extract the definition name from patterns like "#/$defs/name" or "#/definitions/name"
    final defsMatch = RegExp(r'^#/\$defs/(.+)$').firstMatch(refStr);
    final definitionsMatch = RegExp(r'^#/definitions/(.+)$').firstMatch(refStr);

    String? defName;
    if (defsMatch != null) {
      defName = defsMatch.group(1);
    } else if (definitionsMatch != null) {
      defName = definitionsMatch.group(1);
    }

    if (defName == null) return schema;

    // Check both root.definitions and root.defs
    if (root.definitions.containsKey(defName)) {
      return root.definitions[defName]!;
    }
    if (root.defs.containsKey(defName)) {
      return root.defs[defName]!;
    }

    // Last resort: look in the raw schemaMap for both keywords
    final rawMap = root.schemaMap;
    if (rawMap == null) return schema;
    for (final keyword in [r'$defs', 'definitions']) {
      final defsBlock = rawMap[keyword];
      if (defsBlock is Map && defsBlock.containsKey(defName)) {
        try {
          return JsonSchema.create(defsBlock[defName] as Map);
        } catch (_) {
          // Creation failed, skip
        }
      }
    }

    return schema;
  }

  /// Non-standard keywords used by json-editor and similar tools that
  /// cause the json_schema library to throw when it encounters them inside
  /// sub-schemas (e.g., `options.dependencies` with string values).
  static const _nonStandardKeywords = {
    'options',
    'template',
    'watch',
    'headerTemplate',
    'links',
    'enumSource',
  };

  /// Creates a [JsonSchema] from a raw schema map, sanitizing non-standard
  /// keywords (like json-editor's `options`, `template`, `watch`) that would
  /// cause the json_schema library to throw.
  ///
  /// Also normalizes `$defs` to `definitions` for Draft 4/6/7 compatibility.
  static JsonSchema createSchema(Map<String, dynamic> schemaMap) {
    final sanitized = _sanitizeMap(schemaMap);
    return JsonSchema.create(sanitized);
  }

  /// Recursively strips non-standard keywords from a schema map.
  /// Converts `$defs` to `definitions` for cross-draft compatibility.
  static Map<String, dynamic> _sanitizeMap(Map schemaMap) {
    final result = <String, dynamic>{};
    for (final entry in schemaMap.entries) {
      final key = entry.key.toString();

      final rawValue = entry.value;

      // Strip non-standard keywords
      if (_nonStandardKeywords.contains(key)) continue;

      // Strip `id` on sub-schemas when the value is not a proper URI.
      // json-editor uses `id` as a simple identifier (e.g., "arr_item"),
      // which causes json_schema to set a wrong base URI for $ref resolution.
      if (key == 'id' && rawValue is String && !rawValue.contains('://') && !rawValue.startsWith('#')) {
        continue;
      }

      // Normalize $defs → definitions (Draft 4/6/7 compatibility)
      final outputKey = key == r'$defs' ? 'definitions' : key;

      var value = rawValue;

      // Rewrite $ref values that use $defs to use definitions
      if (key == r'$ref' && value is String) {
        if (value.startsWith('http://') || value.startsWith('https://')) {
          // URL $ref: replace the entire object with a placeholder schema.
          // JsonSchema.create() cannot resolve URLs synchronously, so we
          // convert to {"type": "string", "x-remote-ref": "the-url"} which
          // SchemaResolver detects and routes to RemoteRefEditor.
          return <String, dynamic>{
            'type': 'string',
            'x-remote-ref': value,
          };
        }
        value = value.replaceAll(r'#/$defs/', '#/definitions/');
      }

      if (value is Map) {
        result[outputKey] = _sanitizeMap(value);
      } else if (value is List) {
        result[outputKey] = _sanitizeList(value);
      } else {
        result[outputKey] = value;
      }
    }
    return result;
  }

  static List<dynamic> _sanitizeList(List list) {
    return list.map((item) {
      if (item is Map) return _sanitizeMap(item);
      if (item is List) return _sanitizeList(item);
      return item;
    }).toList();
  }

  /// Detects the primary type of a schema, ignoring nullValue in union types.
  static SchemaType? detectType(JsonSchema schema) {
    // Guard against null _typeList: schema.type throws when no type is set.
    if (schema.typeList == null) return null;
    if (schema.typeList!.isEmpty) return null;
    final nonNull =
        schema.typeList!.where((t) => t != SchemaType.nullValue).toList();
    if (nonNull.length == 1) return nonNull.first;
    return null;
  }

  /// Returns true if the schema allows null values.
  static bool isNullable(JsonSchema schema) {
    if (schema.typeList == null) return false;
    return schema.typeList!.contains(SchemaType.nullValue);
  }
}
