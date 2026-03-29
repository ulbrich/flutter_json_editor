import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';

class EnumEditor extends SchemaFieldEditor {
  const EnumEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<EnumEditor> createState() => _EnumEditorState();
}

class _EnumEditorState extends State<EnumEditor> {
  List<String> _errors = [];

  bool get _includeNullOption => !widget.isRequired || widget.isNullable;

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  void _handleChanged(dynamic value) {
    final errors = value != null
        ? ValidationHelper.validateField(widget.schema, value)
        : <String>[];
    setState(() => _errors = errors);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    final isDisabled = widget.schema.readOnly == true;
    final enumValues = widget.schema.enumValues ?? [];

    final items = <DropdownMenuItem<dynamic>>[];

    if (_includeNullOption) {
      items.add(const DropdownMenuItem<dynamic>(value: null, child: Text('—')));
    }

    for (final val in enumValues) {
      items.add(
        DropdownMenuItem<dynamic>(
          value: val,
          child: Text(val?.toString() ?? 'null'),
        ),
      );
    }

    // Ensure selected value is valid within the items, otherwise fall back to null
    final currentValue = enumValues.contains(widget.value)
        ? widget.value
        : null;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: DropdownButtonFormField<dynamic>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: _buildLabel(),
          helperText: widget.schema.description,
          errorText: _errors.isNotEmpty ? _errors.first : null,
          labelStyle: editorTheme.labelStyle,
          helperStyle: editorTheme.helperStyle,
          errorStyle: editorTheme.errorStyle,
        ),
        items: items,
        onChanged: isDisabled ? null : _handleChanged,
      ),
    );
  }
}
