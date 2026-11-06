import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'format_support.dart';

/// Filter chips for a multiple choice, activated by `"x-format": "chips"` on
/// an `array` whose `items` are an `enum` or a `oneOf`/`anyOf` of `const`s:
///
/// ```json
/// {"type": "array", "title": "Allergens", "x-format": "chips",
///  "uniqueItems": true, "maxItems": 3,
///  "items": {"type": "string",
///            "oneOf": [{"const": "gluten", "title": "Gluten"},
///                      {"const": "nuts", "title": "Nuts"},
///                      {"const": "milk", "title": "Milk"}]}}
/// ```
///
/// Each chip toggles its value; the list is stored in the order of the
/// choices. With `maxItems` reached, the other chips are disabled;
/// `minItems` shows a validation error until enough are chosen. Values the
/// choices don't know are kept. A schema without such items renders with
/// the editor it would get without the `x-format` (the array editor).
class ChipsEditor extends SchemaFieldEditor {
  const ChipsEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<ChipsEditor> createState() => _ChipsEditorState();
}

class _ChipsEditorState extends State<ChipsEditor> {
  List<dynamic> get _values =>
      widget.value is List ? List<dynamic>.from(widget.value as List) : [];

  void _toggle(List<dynamic> choiceValues, dynamic value, bool selected) {
    final current = _values;
    final next = <dynamic>[
      // Keep the choices' order, then values the choices don't know.
      for (final v in choiceValues)
        if (v == value ? selected : current.contains(v)) v,
      for (final v in current)
        if (!choiceValues.contains(v)) v,
    ];
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isArray = schemaTypeNames(widget.schema).contains('array');
    final choices = isArray ? choicesOf(widget.schema.items) : null;
    if (choices == null) {
      return editorWithoutFormat(
        context,
        format: 'chips',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final editorTheme = Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final readOnly = widget.schema.readOnly == true;
    final values = _values;
    final maxItems = widget.schema.maxItems;
    final full = maxItems != null && values.length >= maxItems;
    final choiceValues = [for (final c in choices) c.value];
    final errors = widget.value == null
        ? const <String>[]
        : ValidationHelper.validateField(widget.schema, values);

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      errorText: localizeFirstValidationError(JsonEditorL10n.of(context), errors),
      editorTheme: editorTheme,
      onClear: widget.isNullable && !readOnly && widget.value != null
          ? () => widget.onChanged(null)
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final choice in choices)
            Tooltip(
              message: choice.description ?? '',
              child: FilterChip(
                label: Text(choice.title),
                selected: values.contains(choice.value),
                onSelected: readOnly ||
                        (full && !values.contains(choice.value))
                    ? null
                    : (selected) =>
                        _toggle(choiceValues, choice.value, selected),
              ),
            ),
        ],
      ),
    );
  }
}
