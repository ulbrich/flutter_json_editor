import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../editor_registry.dart';
import '../schema_field_editor.dart';
import '../schema_resolver.dart';

class CompositionEditor extends SchemaFieldEditor {
  final int refDepth;

  const CompositionEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
    this.refDepth = 0,
  });

  @override
  State<CompositionEditor> createState() => _CompositionEditorState();
}

class _CompositionEditorState extends State<CompositionEditor> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _autoDetectIndex();
  }

  @override
  void didUpdateWidget(CompositionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedIndex = _autoDetectIndex();
    }
  }

  /// Auto-detect which sub-schema matches the existing value.
  int? _autoDetectIndex() {
    if (widget.value == null) return null;
    final subSchemas = _getSubSchemas();
    for (int i = 0; i < subSchemas.length; i++) {
      final results = subSchemas[i].validate(widget.value);
      if (results.isValid) return i;
    }
    return null;
  }

  List<JsonSchema> _getSubSchemas() {
    if (widget.schema.oneOf.isNotEmpty) return widget.schema.oneOf;
    if (widget.schema.anyOf.isNotEmpty) return widget.schema.anyOf;
    return [];
  }

  String _getSubSchemaLabel(JsonSchema subSchema, int index) {
    return subSchema.title ?? 'Option ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final registry = EditorRegistry.of(context);
    final subSchemas = _getSubSchemas();
    final title = widget.schema.title ?? widget.path.split('.').last;
    final isOneOf = widget.schema.oneOf.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: '$title (${isOneOf ? "one of" : "any of"})'
                '${widget.isRequired ? " *" : ""}',
            helperText: widget.schema.description,
          ),
          value: _selectedIndex,
          items: [
            if (!widget.isRequired || widget.isNullable)
              const DropdownMenuItem<int>(value: null, child: Text('-- None --')),
            ...subSchemas.asMap().entries.map((entry) => DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(_getSubSchemaLabel(entry.value, entry.key)),
                )),
          ],
          onChanged: (newIndex) {
            setState(() {
              _selectedIndex = newIndex;
              // Clear value when switching type to avoid incompatible data
              widget.onChanged(null);
            });
          },
        ),
        const SizedBox(height: 8),
        if (_selectedIndex != null)
          SchemaResolver.resolve(
            schema: subSchemas[_selectedIndex!],
            path: widget.path,
            value: widget.value,
            onChanged: widget.onChanged,
            registry: registry,
            isRequired: widget.isRequired,
            isNullable: widget.isNullable,
            refDepth: widget.refDepth,
          ),
      ],
    );
  }
}
