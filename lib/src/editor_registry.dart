import 'package:flutter/widgets.dart';
import 'package:json_schema/json_schema.dart';

import 'editors/chips_editor.dart';
import 'editors/colour_editor.dart';
import 'editors/date_editor.dart';
import 'editors/date_time_editor.dart';
import 'editors/duration_editor.dart';
import 'editors/image_data_editor.dart';
import 'editors/image_choice_editor.dart';
import 'editors/image_picker_editor.dart';
import 'editors/markdown_editor.dart';
import 'editors/segmented_editor.dart';
import 'editors/signature_editor.dart';
import 'editors/slider_editor.dart';
import 'editors/star_rating_editor.dart';
import 'editors/stepper_editor.dart';
import 'editors/svg_part_picker_editor.dart';
import 'editors/time_editor.dart';
import 'editors/consent_editor.dart';
import 'editors/date_range_editor.dart';
import 'editors/file_data_editor.dart';
import 'editors/image_gallery_editor.dart';
import 'editors/matrix_editor.dart';
import 'editors/phone_editor.dart';
import 'editors/ranking_editor.dart';
import 'editors/scale_editor.dart';
import 'editors/textarea_editor.dart';
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

  static SchemaFieldEditorBuilder get _markdownEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          MarkdownEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _dateEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          DateEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _timeEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          TimeEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _dateTimeEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          DateTimeEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _svgPartPickerEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          SvgPartPickerEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _sliderEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          SliderEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _stepperEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          StepperEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _segmentedEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          SegmentedEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _chipsEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ChipsEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _imageDataEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          schema.schemaMap?['type'] == 'array'
              ? ImageGalleryEditor(
                  schema: schema,
                  path: path,
                  value: value,
                  onChanged: onChanged,
                  isRequired: isRequired,
                  isNullable: isNullable,
                )
              : ImageDataEditor(
                  schema: schema,
                  path: path,
                  value: value,
                  onChanged: onChanged,
                  isRequired: isRequired,
                  isNullable: isNullable,
                );

  static SchemaFieldEditorBuilder get _durationEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          DurationEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _signatureEditorBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          SignatureEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _linearScaleBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ScaleEditor(
            variant: ScaleVariant.linear,
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _npsScaleBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ScaleEditor(
            variant: ScaleVariant.nps,
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _emojiScaleBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ScaleEditor(
            variant: ScaleVariant.emoji,
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _matrixBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          MatrixEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _rankingBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          RankingEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _dateRangeBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          DateRangeEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _phoneBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          PhoneEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _fileDataBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          FileDataEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _consentBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ConsentEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  static SchemaFieldEditorBuilder get _textareaBuilder => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          TextareaEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
          );

  /// The `x-format` values the package has editors for.
  static Iterable<String> get builtInFormats => _builtInFormatOverrides.keys;

  static final Map<String, SchemaFieldEditorBuilder> _builtInFormatOverrides = {
    'chips': _chipsEditorBuilder,
    'color': _colourEditorBuilder,
    'colour': _colourEditorBuilder,
    'consent': _consentBuilder,
    'date': _dateEditorBuilder,
    'date-range': _dateRangeBuilder,
    'date-time': _dateTimeEditorBuilder,
    'duration': _durationEditorBuilder,
    'emoji-scale': _emojiScaleBuilder,
    'file-data': _fileDataBuilder,
    'image-choice': ImageChoiceEditor.builderWith(null),
    'image-data': _imageDataEditorBuilder,
    'image-url-picker': _imagePickerEditorBuilder,
    'linear-scale': _linearScaleBuilder,
    'markdown': _markdownEditorBuilder,
    'matrix': _matrixBuilder,
    'nps': _npsScaleBuilder,
    'phone': _phoneBuilder,
    'ranking': _rankingBuilder,
    'segmented': _segmentedEditorBuilder,
    'signature': _signatureEditorBuilder,
    'slider': _sliderEditorBuilder,
    'star-rating': _starRatingEditorBuilder,
    'stepper': _stepperEditorBuilder,
    'svg-part-picker': _svgPartPickerEditorBuilder,
    'textarea': _textareaBuilder,
    'time': _timeEditorBuilder,
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

    // 2. Check x-format overrides, then fall back to standard JSON Schema
    //    `format` so that e.g. "format": "date" also resolves.
    final xFormat = schema.schemaMap?['x-format'];
    if (xFormat is String && _formatOverrides.containsKey(xFormat)) {
      return _formatOverrides[xFormat];
    }
    final stdFormat = schema.format;
    if (stdFormat != null && _formatOverrides.containsKey(stdFormat)) {
      return _formatOverrides[stdFormat];
    }

    // 3. Check predicate overrides (first match wins)
    for (final (predicate, builder) in _predicateOverrides) {
      if (predicate(schema)) {
        return builder;
      }
    }

    // 4. Check type overrides. Reading `schema.type` THROWS for a schema with
    //    no single scalar type — a bare anyOf/oneOf/allOf/$ref, or a multi-type
    //    like ["string","null"] — so guard it and treat those as untyped
    //    (they are handled later by the composition/type branches of the
    //    resolver). Without this guard, any such property crashes rendering.
    SchemaType? type;
    try {
      type = schema.type;
    } catch (_) {
      type = null;
    }
    if (type != null && _typeOverrides.containsKey(type)) {
      return _typeOverrides[type];
    }

    return null;
  }

  EditorRegistryData merge(EditorRegistryData other) {
    return EditorRegistryData(
      pathOverrides: {..._pathOverrides, ...other._pathOverrides},
      formatOverrides: {..._formatOverrides, ...other._formatOverrides},
      typeOverrides: {..._typeOverrides, ...other._typeOverrides},
      predicateOverrides: [
        ..._predicateOverrides,
        ...other._predicateOverrides,
      ],
    );
  }
}

class EditorRegistry extends InheritedWidget {
  final EditorRegistryData data;

  const EditorRegistry({super.key, required this.data, required super.child});

  static EditorRegistryData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EditorRegistry>()?.data;
  }

  @override
  bool updateShouldNotify(EditorRegistry oldWidget) {
    return data != oldWidget.data;
  }
}
