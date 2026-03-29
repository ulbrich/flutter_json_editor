import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';

class NumberEditor extends SchemaFieldEditor {
  const NumberEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<NumberEditor> createState() => _NumberEditorState();
}

class _NumberEditorState extends State<NumberEditor> {
  late TextEditingController _controller;
  List<String> _errors = [];

  bool get _isDecimal => widget.schema.type == SchemaType.number;

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
  void didUpdateWidget(NumberEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = widget.value?.toString() ?? '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  void _handleChanged(String text) {
    if (text.isEmpty) {
      setState(() => _errors = []);
      widget.onChanged(null);
      return;
    }

    final parsed = _isDecimal ? double.tryParse(text) : int.tryParse(text);

    if (parsed == null) {
      setState(() => _errors = ['Invalid number format']);
      return;
    }

    final errors = ValidationHelper.validateField(widget.schema, parsed);
    setState(() => _errors = errors);
    widget.onChanged(parsed);
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

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    final isConstValue = widget.schema.constValue != null;
    final isDisabled = isConstValue || widget.schema.readOnly == true;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              enabled: !isDisabled,
              keyboardType: TextInputType.numberWithOptions(
                decimal: _isDecimal,
              ),
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
