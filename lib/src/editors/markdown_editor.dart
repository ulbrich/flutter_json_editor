import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';

/// A string editor that renders Markdown when read-only and shows a multiline
/// text field when editable. Activated via `x-format: "markdown"`.
class MarkdownEditor extends SchemaFieldEditor {
  const MarkdownEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _controller;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    final isReadOnly = widget.schema.readOnly == true;

    if (isReadOnly) {
      return Padding(
        padding: editorTheme.fieldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _buildLabel(),
              style: editorTheme.labelStyle ??
                  Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.schema.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.schema.description!,
                  style: editorTheme.helperStyle ??
                      Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: widget.value?.toString() ?? '',
              selectable: true,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                labelText: _buildLabel(),
                helperText: widget.schema.description,
                errorText: _errors.isNotEmpty ? _errors.first : null,
                labelStyle: editorTheme.labelStyle,
                helperStyle: editorTheme.helperStyle,
                errorStyle: editorTheme.errorStyle,
              ),
              onChanged: _handleChanged,
            ),
          ),
          if (widget.isNullable && widget.value != null)
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
