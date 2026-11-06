import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'format_support.dart';

/// Several lines of plain text, activated by `"x-format": "textarea"` on a
/// `string`:
///
/// ```json
/// {"type": "string", "title": "Feedback", "x-format": "textarea",
///  "x-rows": 5, "maxLength": 500}
/// ```
///
/// The field is `x-rows` lines high (default [TextareaEditor.defaultRows])
/// and grows up to twice that before it scrolls. With `maxLength` a counter
/// shows the characters used, and typing stops at the limit. A schema that
/// isn't a string renders with the editor it would get without the
/// `x-format`.
class TextareaEditor extends SchemaFieldEditor {
  const TextareaEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// Height in lines without `x-rows`.
  static const int defaultRows = 4;

  @override
  State<TextareaEditor> createState() => _TextareaEditorState();
}

class _TextareaEditorState extends State<TextareaEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value is String ? widget.value as String : '',
  );
  List<String> _errors = const [];

  @override
  void didUpdateWidget(TextareaEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value is String ? widget.value as String : '';
    if (widget.value != oldWidget.value && _controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    final value = text.isEmpty ? null : text;
    setState(
      () => _errors = ValidationHelper.validateField(widget.schema, value),
    );
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    if (!schemaTypeNames(widget.schema).contains('string')) {
      return editorWithoutFormat(
        context,
        format: 'textarea',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final readOnly =
        widget.schema.readOnly == true || widget.schema.constValue != null;
    final rowsValue = widget.schema.schemaMap?['x-rows'];
    final rows = rowsValue is num && rowsValue >= 1
        ? rowsValue.toInt()
        : TextareaEditor.defaultRows;
    final maxLength = widget.schema.maxLength;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('textarea'),
              controller: _controller,
              enabled: !readOnly,
              minLines: rows,
              maxLines: rows * 2,
              maxLength: maxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: fieldLabel(
                  widget.schema,
                  widget.path,
                  widget.isRequired,
                ),
                alignLabelWithHint: true,
                helperText: widget.schema.description,
                helperMaxLines: 3,
                errorText: localizeFirstValidationError(l10n, _errors),
                labelStyle: editorTheme.labelStyle,
                helperStyle: editorTheme.helperStyle,
                errorStyle: editorTheme.errorStyle,
              ),
              onChanged: _changed,
            ),
          ),
          if (widget.isNullable && !readOnly && widget.value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.clearToNullTooltip,
              onPressed: () {
                _controller.clear();
                setState(() => _errors = const []);
                widget.onChanged(null);
              },
            ),
        ],
      ),
    );
  }
}
