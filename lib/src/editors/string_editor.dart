import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import '../input_mask.dart';

/// A one-line text field. With `x-mask` (see [InputMask]) the text keeps a
/// fixed pattern while typing, `"x-mask": "AA00 0000 0000 0000 0000 00"`;
/// the value is the text as shown, or only the typed characters with
/// `"x-mask-raw": true`. A text that doesn't fill the pattern shows an
/// error.
class StringEditor extends SchemaFieldEditor {
  const StringEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<StringEditor> createState() => _StringEditorState();
}

class _StringEditorState extends State<StringEditor> {
  late TextEditingController _controller;
  List<String> _errors = [];

  InputMask? get _mask {
    final pattern = widget.schema.schemaMap?['x-mask'];
    return pattern is String && pattern.isNotEmpty ? InputMask(pattern) : null;
  }

  bool get _storesRaw => widget.schema.schemaMap?['x-mask-raw'] == true;

  /// [value] as the field shows it: laid out by the mask, when there is one.
  String _display(dynamic value) {
    final text = value?.toString() ?? '';
    final mask = _mask;
    return mask == null || text.isEmpty ? text : mask.apply(text);
  }

  @override
  void initState() {
    super.initState();
    final isConstValue = widget.schema.constValue != null;
    final initialText = isConstValue
        ? widget.schema.constValue?.toString() ?? ''
        : _display(widget.value);
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StringEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = _display(widget.value);
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  void _handleChanged(String text) {
    final mask = _mask;
    final stored = mask != null && _storesRaw ? mask.raw(text) : text;
    final value = stored.isEmpty ? null : stored;
    final errors = [...ValidationHelper.validateField(widget.schema, value)];
    if (mask != null && text.isNotEmpty && !mask.isComplete(text)) {
      errors.insert(0, JsonEditorL10n.of(context).maskIncomplete(mask.hint));
    }
    setState(() => _errors = errors);
    widget.onChanged(value);
  }

  void _clearToNull() {
    _controller.clear();
    setState(() => _errors = []);
    widget.onChanged(null);
  }

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  TextInputType _keyboardType() {
    final format = widget.schema.format;
    if (format == 'email') return TextInputType.emailAddress;
    if (format == 'uri') return TextInputType.url;
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    final isConstValue = widget.schema.constValue != null;
    final isDisabled = isConstValue || widget.schema.readOnly == true;
    final isObscured = widget.schema.writeOnly == true;
    final mask = _mask;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              enabled: !isDisabled,
              obscureText: isObscured,
              keyboardType:
                  mask != null && !mask.pattern.contains(RegExp('[A*]'))
                  ? TextInputType.number
                  : _keyboardType(),
              inputFormatters: mask == null ? null : [mask.formatter],
              maxLines: isDisabled ? null : 1,
              minLines: isDisabled ? 1 : null,
              decoration: InputDecoration(
                labelText: _buildLabel(),
                hintText: mask?.hint,
                helperText: widget.schema.description,
                errorText: localizeFirstValidationError(
                  JsonEditorL10n.of(context),
                  _errors,
                ),
                labelStyle: editorTheme.labelStyle,
                helperStyle: editorTheme.helperStyle,
                errorStyle: editorTheme.errorStyle,
              ),
              onChanged: isDisabled ? null : _handleChanged,
            ),
          ),
          if (widget.isNullable && !isDisabled && widget.value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: JsonEditorL10n.of(context).clearToNullTooltip,
              onPressed: _clearToNull,
            ),
        ],
      ),
    );
  }
}
