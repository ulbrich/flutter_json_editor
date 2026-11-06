import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../editor_registry.dart';
import '../l10n/json_editor_l10n.dart';
import '../schema_resolver.dart';
import '../schema_utils.dart';
import '../theme/editor_theme.dart';
import 'const_choice_editor.dart';

/// Helpers shared by the built-in `x-format` editors.

/// The names of the schema's `type`s (`integer`, `string`, …); empty when it
/// has none. Never throws, unlike [JsonSchema.type] on multi-type schemas.
Set<String> schemaTypeNames(JsonSchema schema) {
  try {
    return {
      for (final type in schema.typeList ?? const <SchemaType?>[])
        if (type != null) type.toString(),
    };
  } catch (_) {
    return const {};
  }
}

/// Whether the schema allows numbers (`integer` or `number`).
bool isNumericSchema(JsonSchema schema) {
  final types = schemaTypeNames(schema);
  return types.contains('integer') || types.contains('number');
}

/// Whether the schema stores whole numbers only (`integer` without `number`).
bool isIntegerSchema(JsonSchema schema) {
  final types = schemaTypeNames(schema);
  return types.contains('integer') && !types.contains('number');
}

/// The field's label: its `title` or the last path segment, with ` *` when
/// it is required.
String fieldLabel(JsonSchema schema, String path, bool isRequired) {
  final base = schema.title ?? path.split('.').last;
  return isRequired ? '$base *' : base;
}

/// The labeled choices of a schema: the `const` branches of a
/// `oneOf`/`anyOf` (see [ConstChoiceEditor.tryExtract]) or else its `enum`
/// values, titled by their text. Null when it has neither.
List<ConstChoice>? choicesOf(JsonSchema? schema) {
  if (schema == null) return null;
  final consts = ConstChoiceEditor.tryExtract(schema);
  if (consts != null) return consts;
  final values = schema.enumValues;
  if (values == null || values.isEmpty) return null;
  return [
    for (final value in values)
      ConstChoice(value: value, title: value?.toString() ?? '—'),
  ];
}

/// Renders the field with the editor it would get without the `x-format`
/// [format] (and without a standard `format` of the same name), for schemas
/// a format editor can't handle.
Widget editorWithoutFormat(
  BuildContext context, {
  required String format,
  required JsonSchema schema,
  required String path,
  required dynamic value,
  required void Function(dynamic) onChanged,
  required bool isRequired,
  required bool isNullable,
}) {
  final map = Map<String, dynamic>.from(schema.schemaMap ?? const {})
    ..remove('x-format');
  if (map['format'] == format) map.remove('format');
  return SchemaResolver.resolve(
    schema: SchemaUtils.createSchema(map),
    path: path,
    value: value,
    onChanged: onChanged,
    registry: EditorRegistry.of(context),
    isRequired: isRequired,
    isNullable: isNullable,
  );
}

/// The label row (with a clear-to-null button for nullable fields that have
/// a value), the description and the error of a format editor whose control
/// isn't a text field, followed by [child].
class FormatFieldFrame extends StatelessWidget {
  const FormatFieldFrame({
    super.key,
    required this.label,
    required this.editorTheme,
    required this.child,
    this.description,
    this.errorText,
    this.onClear,
    this.trailing,
  });

  final String label;
  final String? description;
  final String? errorText;
  final JsonEditorTheme editorTheme;

  /// Shown as a clear button next to the label when not null.
  final VoidCallback? onClear;

  /// Extra actions next to the label (before the clear button).
  final List<Widget>? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onClear = this.onClear;
    final description = this.description;
    final errorText = this.errorText;
    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: editorTheme.labelStyle ?? theme.textTheme.bodyMedium,
                ),
              ),
              ...?trailing,
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: JsonEditorL10n.of(context).clearToNullTooltip,
                  onPressed: onClear,
                ),
            ],
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                description,
                style: editorTheme.helperStyle ?? theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 4),
          child,
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                errorText,
                style:
                    editorTheme.errorStyle ??
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
