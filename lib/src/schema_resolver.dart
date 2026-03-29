import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import 'editor_registry.dart';
import 'editors/array_editor.dart';
import 'editors/boolean_editor.dart';
import 'editors/composition_editor.dart';
import 'editors/enum_editor.dart';
import 'editors/map_editor.dart';
import 'editors/number_editor.dart';
import 'editors/object_editor.dart';
import 'editors/remote_ref_editor.dart';
import 'editors/string_editor.dart';
import 'schema_utils.dart';

class SchemaResolver {
  static Widget resolve({
    required JsonSchema schema,
    required String path,
    required dynamic value,
    required void Function(dynamic value) onChanged,
    EditorRegistryData? registry,
    bool isRequired = false,
    bool isNullable = false,
    int refDepth = 0,
  }) {
    // 0a. Detect x-remote-ref (URL $ref replaced during sanitization)
    final remoteRef = schema.schemaMap?['x-remote-ref'];
    if (remoteRef is String) {
      return RemoteRefEditor(
        refUrl: remoteRef,
        schema: schema,
        path: path,
        value: value,
        onChanged: onChanged,
        isRequired: isRequired,
        isNullable: isNullable,
      );
    }

    // 0b. $ref resolution with circular reference protection
    final originalRef = schema.ref;
    schema = SchemaUtils.resolveRef(schema);
    if (originalRef != null) {
      refDepth++;
      if (refDepth > SchemaUtils.maxRefDepth) {
        final typeName = schema.title ?? path.split('.').last;
        return _CircularRefWidget(path: path, typeName: typeName);
      }
    }

    // 1. Check registry for override
    if (registry != null) {
      final builder = registry.resolve(schema, path);
      if (builder != null) {
        return builder(
          schema: schema,
          path: path,
          value: value,
          onChanged: onChanged,
          isRequired: isRequired,
          isNullable: isNullable,
        );
      }
    }

    // 2. enumValues -> EnumEditor
    if (schema.enumValues != null && schema.enumValues!.isNotEmpty) {
      return EnumEditor(
        schema: schema,
        path: path,
        value: value,
        onChanged: onChanged,
        isRequired: isRequired,
        isNullable: isNullable,
      );
    }

    // 3. oneOf/anyOf -> CompositionEditor
    if (schema.oneOf.isNotEmpty || schema.anyOf.isNotEmpty) {
      return CompositionEditor(
        schema: schema,
        path: path,
        value: value,
        onChanged: onChanged,
        isRequired: isRequired,
        isNullable: isNullable,
        refDepth: refDepth,
      );
    }

    // 4. Multi-type (typeList) handling
    final effectiveType = SchemaUtils.detectType(schema);

    // 5. Match on type
    if (effectiveType != null) {
      switch (effectiveType) {
        case SchemaType.string:
          return StringEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );
        case SchemaType.integer:
        case SchemaType.number:
          return NumberEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );
        case SchemaType.boolean:
          return BooleanEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );
        case SchemaType.object:
          if (_isMapSchema(schema)) {
            return MapEditor(
              schema: schema,
              path: path,
              value: value,
              onChanged: onChanged,
              isRequired: isRequired,
              isNullable: isNullable,
              refDepth: refDepth,
            );
          }
          return ObjectEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
            refDepth: refDepth,
          );
        case SchemaType.array:
          return ArrayEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
            refDepth: refDepth,
          );
        default:
          return _placeholder(schema, path, hint: effectiveType.toString());
      }
    }

    // 6. properties without type -> ObjectEditor
    if (schema.properties.isNotEmpty) {
      return ObjectEditor(
        schema: schema,
        path: path,
        value: value,
        onChanged: onChanged,
        isRequired: isRequired,
        isNullable: isNullable,
        refDepth: refDepth,
      );
    }

    // 6b. additionalProperties without properties -> MapEditor
    if (_isMapSchema(schema)) {
      return MapEditor(
        schema: schema,
        path: path,
        value: value,
        onChanged: onChanged,
        isRequired: isRequired,
        isNullable: isNullable,
        refDepth: refDepth,
      );
    }

    // 7. allOf without explicit type -> ObjectEditor
    if (schema.allOf.isNotEmpty) {
      return ObjectEditor(
        schema: schema,
        path: path,
        value: value,
        onChanged: onChanged,
        isRequired: isRequired,
        isNullable: isNullable,
        refDepth: refDepth,
      );
    }

    // 8. Fallback -> StringEditor
    return StringEditor(
      schema: schema,
      path: path,
      value: value,
      onChanged: onChanged,
      isRequired: isRequired,
      isNullable: isNullable,
    );
  }

  static bool _isMapSchema(JsonSchema schema) {
    final hasAdditional = schema.additionalPropertiesSchema != null ||
        schema.additionalPropertiesBool == true;
    return hasAdditional && schema.properties.isEmpty;
  }

  static Widget _placeholder(JsonSchema schema, String path, {String? hint}) {
    final typeLabel = hint ?? schema.type?.toString() ?? 'unknown';
    return _PlaceholderEditor(schemaType: typeLabel, path: path);
  }
}

class _PlaceholderEditor extends StatelessWidget {
  final String schemaType;
  final String path;

  const _PlaceholderEditor({
    required this.schemaType,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Text('Editor for $schemaType at ${path.isEmpty ? '(root)' : path}');
  }
}

class _CircularRefWidget extends StatelessWidget {
  final String path;
  final String typeName;

  const _CircularRefWidget({
    required this.path,
    required this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: null,
      child: Text('Add nested $typeName'),
    );
  }
}
