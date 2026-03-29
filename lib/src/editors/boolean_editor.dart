import 'package:flutter/material.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

class BooleanEditor extends SchemaFieldEditor {
  const BooleanEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<BooleanEditor> createState() => _BooleanEditorState();
}

class _BooleanEditorState extends State<BooleanEditor> {
  bool get _currentValue {
    if (widget.value is bool) return widget.value as bool;
    final defaultVal = widget.schema.defaultValue;
    if (defaultVal is bool) return defaultVal;
    return false;
  }

  void _handleChanged(bool? value) {
    widget.onChanged(value);
  }

  String _buildTitle() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    final isDisabled = widget.schema.readOnly == true;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: CheckboxListTile(
        title: Text(_buildTitle(), style: editorTheme.labelStyle),
        subtitle: widget.schema.description != null
            ? Text(widget.schema.description!, style: editorTheme.helperStyle)
            : null,
        value: _currentValue,
        onChanged: isDisabled ? null : _handleChanged,
        controlAffinity: ListTileControlAffinity.platform,
        activeColor: Theme.of(context).colorScheme.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
