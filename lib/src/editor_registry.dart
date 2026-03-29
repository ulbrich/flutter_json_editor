import 'package:flutter/widgets.dart';
import 'package:json_schema/json_schema.dart';

import 'editors/colour_editor.dart';
import 'editors/image_picker_editor.dart';
import 'editors/star_rating_editor.dart';
import 'schema_field_editor.dart';

class EditorRegistryData {
  final Map<String, SchemaFieldEditorBuilder> _pathOverrides;
  final Map<String, SchemaFieldEditorBuilder> _formatOverrides;
  final Map<SchemaType, SchemaFieldEditorBuilder> _typeOverrides;
  final List<(bool Function(JsonSchema), SchemaFieldEditorBuilder)>
      _predicateOverrides;

  EditorRegistryData({
    Map<String, SchemaFieldEditorBuilder> pathOverrides = const {},
    Map<String, SchemaFieldEditorBuilder> formatOverrides = const {},
    Map<SchemaType, SchemaFieldEditorBuilder> typeOverrides = const {},
    List<(bool Function(JsonSchema), SchemaFieldEditorBuilder)>
        predicateOverrides = const [],
  })  : _pathOverrides = pathOverrides,
        _formatOverrides = {..._builtInFormatOverrides, ...formatOverrides},
        _typeOverrides = typeOverrides,
        _predicateOverrides = predicateOverrides;

  static SchemaFieldEditorBuilder get _colourEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ColourEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _starRatingEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          StarRatingEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _imagePickerEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ImagePickerEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static final Map<String, SchemaFieldEditorBuilder> _builtInFormatOverrides = {
    'colour': _colourEditorBuilder,
    'color': _colourEditorBuilder,
    'image-url-picker': _imagePickerEditorBuilder,
    'star-rating': _starRatingEditorBuilder,
  };

  /// Look up a builder by `x-format` value only. Used by [SchemaResolver] to
  /// check format overrides before remote-ref routing.
  SchemaFieldEditorBuilder? resolveFormat(String xFormat) {
    return _formatOverrides[xFormat];
  }

  SchemaFieldEditorBuilder? resolve(JsonSchema schema, String path) {
    // 1. Check path overrides
    if (_pathOverrides.containsKey(path)) {
      return _pathOverrides[path];
    }

    // 2. Check x-format overrides
    final xFormat = schema.schemaMap?['x-format'];
    if (xFormat is String && _formatOverrides.containsKey(xFormat)) {
      return _formatOverrides[xFormat];
    }

    // 3. Check predicate overrides (first match wins)
    for (final (predicate, builder) in _predicateOverrides) {
      if (predicate(schema)) {
        return builder;
      }
    }

    // 4. Check type overrides
    if (schema.type != null && _typeOverrides.containsKey(schema.type)) {
      return _typeOverrides[schema.type];
    }

    return null;
  }

  EditorRegistryData merge(EditorRegistryData other) {
    return EditorRegistryData(
      pathOverrides: {
        ..._pathOverrides,
        ...other._pathOverrides,
      },
      formatOverrides: {
        ..._formatOverrides,
        ...other._formatOverrides,
      },
      typeOverrides: {
        ..._typeOverrides,
        ...other._typeOverrides,
      },
      predicateOverrides: [
        ..._predicateOverrides,
        ...other._predicateOverrides,
      ],
    );
  }
}

class EditorRegistry extends InheritedWidget {
  final EditorRegistryData data;

  const EditorRegistry({
    super.key,
    required this.data,
    required super.child,
  });

  static EditorRegistryData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EditorRegistry>()?.data;
  }

  @override
  bool updateShouldNotify(EditorRegistry oldWidget) {
    return data != oldWidget.data;
  }
}
