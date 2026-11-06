import 'package:material_ui/material_ui.dart';
import 'package:json_schema/json_schema.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../schema_utils.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'const_choice_editor.dart';
import 'format_support.dart';

/// A grid of questions sharing one set of answers (a Likert scale),
/// activated by `"x-format": "matrix"` on an `object`. Each property is a
/// row; the columns are the choices of the first row (an `enum` or a
/// `oneOf`/`anyOf` of `const`s, typically one shared `$ref`):
///
/// ```json
/// {"type": "object", "title": "How much do you agree?", "x-format": "matrix",
///  "required": ["tools"],
///  "properties": {
///    "tools": {"title": "I have the tools I need", "$ref": "#/definitions/agree"},
///    "team":  {"title": "My team supports me", "$ref": "#/definitions/agree"}}}
/// ```
///
/// A row that is a `string`/`integer` with those choices takes one answer
/// (radio buttons) and stores it as `{"tools": "agree"}`; a row that is an
/// `array` of them takes several (checkboxes) and stores a list. Tapping the
/// chosen radio again clears it. Required rows are marked. An object whose
/// rows have no choices renders with the editor it would get without the
/// `x-format`.
class MatrixEditor extends SchemaFieldEditor {
  const MatrixEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<MatrixEditor> createState() => _MatrixEditorState();
}

class _Row {
  _Row(this.key, this.title, this.multiple, this.required);
  final String key;
  final String title;
  final bool multiple;
  final bool required;
}

class _MatrixEditorState extends State<MatrixEditor> {
  Map<String, dynamic> get _data => widget.value is Map
      ? Map<String, dynamic>.from(widget.value as Map)
      : <String, dynamic>{};

  void _set(String key, dynamic value) {
    final data = _data;
    if (value == null || (value is List && value.isEmpty)) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    widget.onChanged(data.isEmpty && widget.isNullable ? null : data);
  }

  @override
  Widget build(BuildContext context) {
    final isObject =
        schemaTypeNames(widget.schema).contains('object') ||
        widget.schema.properties.isNotEmpty;
    final required = widget.schema.requiredProperties?.toSet() ?? {};
    List<ConstChoice>? columns;
    final rows = <_Row>[];
    if (isObject) {
      for (final entry in widget.schema.properties.entries) {
        final row = SchemaUtils.resolveRef(entry.value);
        final multiple = schemaTypeNames(row).contains('array');
        final choices = choicesOf(
          multiple && row.items != null
              ? SchemaUtils.resolveRef(row.items!)
              : row,
        );
        if (choices == null) continue;
        columns ??= choices;
        rows.add(
          _Row(
            entry.key,
            row.title ?? entry.value.title ?? entry.key,
            multiple,
            required.contains(entry.key),
          ),
        );
      }
    }
    if (columns == null || rows.isEmpty) {
      return editorWithoutFormat(
        context,
        format: 'matrix',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final cols = columns;
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readOnly = widget.schema.readOnly == true;
    final data = _data;
    final errors = data.isEmpty
        ? const <String>[]
        : _errors(widget.schema, data);

    Widget cell(_Row row, ConstChoice choice) {
      final current = data[row.key];
      if (row.multiple) {
        final list = current is List ? current : const [];
        final checked = list.contains(choice.value);
        return Checkbox(
          key: ValueKey('matrix-${row.key}-${choice.value}'),
          value: checked,
          onChanged: readOnly
              ? null
              : (on) => _set(row.key, [
                  for (final c in cols)
                    if (c.value == choice.value
                        ? on == true
                        : list.contains(c.value))
                      c.value,
                ]),
        );
      }
      final selected = current == choice.value;
      return IconButton(
        key: ValueKey('matrix-${row.key}-${choice.value}'),
        isSelected: selected,
        tooltip: choice.title,
        icon: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onPressed: readOnly
            ? null
            : () => _set(row.key, selected ? null : choice.value),
      );
    }

    final headerStyle = theme.textTheme.labelSmall;
    final rowStyle = theme.textTheme.bodyMedium;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      errorText: localizeFirstValidationError(l10n, errors),
      child: Table(
        columnWidths: {
          0: const FlexColumnWidth(2.2),
          for (var i = 1; i <= cols.length; i++) i: const FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(),
              for (final c in cols)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Text(
                    c.title,
                    textAlign: TextAlign.center,
                    style: headerStyle,
                  ),
                ),
            ],
          ),
          for (var r = 0; r < rows.length; r++)
            TableRow(
              decoration: BoxDecoration(
                color: r.isEven
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    rows[r].required ? '${rows[r].title} *' : rows[r].title,
                    style: rowStyle,
                  ),
                ),
                for (final c in cols) Center(child: cell(rows[r], c)),
              ],
            ),
        ],
      ),
    );
  }

  /// Validation errors other than missing rows, which the asterisks show.
  List<String> _errors(JsonSchema schema, Map<String, dynamic> data) =>
      ValidationHelper.validateField(
        schema,
        data,
      ).where((e) => !e.toLowerCase().contains('required')).toList();
}
