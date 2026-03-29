import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';

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

  @override
  void initState() {
    super.initState();
    final isConstValue = widget.schema.constValue != null;
    final initialText = isConstValue
        ? widget.schema.constValue?.toString() ?? ''
        : widget.value?.toString() ?? '';
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
      final newText = widget.value?.toString() ?? '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  void _handleChanged(String text) {
    final errors = ValidationHelper.validateField(
      widget.schema,
      text.isEmpty ? null : text,
    );
    setState(() => _errors = errors);
    widget.onChanged(text.isEmpty ? null : text);
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
              keyboardType: _keyboardType(),
              maxLines: isDisabled ? null : 1,
              minLines: isDisabled ? 1 : null,
              decoration: InputDecoration(
                labelText: _buildLabel(),
                helperText: widget.schema.description,
                errorText: _errors.isNotEmpty ? _errors.first : null,
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
              tooltip: 'Clear to null',
              onPressed: _clearToNull,
            ),
        ],
      ),
    );
  }
}
