import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';
import 'package:uuid/uuid.dart';

import '../editor_registry.dart';
import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../schema_resolver.dart';
import '../schema_utils.dart';
import 'string_editor.dart';

class MapEditor extends SchemaFieldEditor {
  final int refDepth;

  const MapEditor({
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
  State<MapEditor> createState() => _MapEditorState();
}

class _MapEditorState extends State<MapEditor> {
  late Map<String, dynamic> _data;
  late List<String> _entryIds;
  late List<String> _keys;
  static const _uuid = Uuid();
  bool _selfUpdating = false;

  /// Index of the most recently added entry, so its key field can be
  /// auto-selected for immediate overwriting. Reset to -1 after build.
  int _newEntryIndex = -1;

  @override
  void initState() {
    super.initState();
    final map = (widget.value as Map<String, dynamic>?) ?? {};
    _data = Map<String, dynamic>.from(map);
    _keys = _data.keys.toList();
    _entryIds = List.generate(_keys.length, (_) => _uuid.v4());
  }

  @override
  void didUpdateWidget(MapEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Skip re-init when the change came from this widget (preserves focus)
    if (_selfUpdating) {
      _selfUpdating = false;
      return;
    }
    if (widget.value != oldWidget.value) {
      final map = (widget.value as Map<String, dynamic>?) ?? {};
      _data = Map<String, dynamic>.from(map);
      _keys = _data.keys.toList();
      _entryIds = List.generate(_keys.length, (_) => _uuid.v4());
    }
  }

  void _notifyParent() {
    _selfUpdating = true;
    widget.onChanged(Map<String, dynamic>.from(_data));
  }

  void _addEntry() {
    setState(() {
      var newKey = '#${_keys.length + 1}';
      while (_keys.contains(newKey)) {
        newKey = '${newKey}_';
      }
      _keys.add(newKey);
      _data[newKey] = '';
      _entryIds.add(_uuid.v4());
      _newEntryIndex = _keys.length - 1;
      _notifyParent();
    });
  }

  void _removeEntry(int index) {
    setState(() {
      final key = _keys.removeAt(index);
      _entryIds.removeAt(index);
      _data.remove(key);
      _notifyParent();
    });
  }

  void _onKeyChanged(int index, String newKey) {
    final oldKey = _keys[index];
    if (oldKey != newKey && !_keys.contains(newKey)) {
      _data.remove(oldKey);
      _keys[index] = newKey;
      _data[newKey] = _data[oldKey] ?? '';
      _notifyParent();
    }
  }

  void _onValueChanged(int index, dynamic newValue) {
    _data[_keys[index]] = newValue;
    _notifyParent();
  }

  JsonSchema? _getValueSchema() {
    return widget.schema.additionalPropertiesSchema;
  }

  @override
  Widget build(BuildContext context) {
    final registry = EditorRegistry.of(context);
    final title = widget.schema.title ?? widget.path.split('.').last;
    final valueSchema = _getValueSchema();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title + (widget.isRequired ? ' *' : ''),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addEntry,
              tooltip: JsonEditorL10n.of(context).addEntryTooltip,
            ),
          ],
        ),
        if (widget.schema.description != null)
          Text(
            widget.schema.description!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ...List.generate(_keys.length, (index) {
          final key = _keys[index];
          final isNew = index == _newEntryIndex;
          if (isNew) _newEntryIndex = -1;
          return Padding(
            key: ValueKey(_entryIds[index]),
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _KeyField(
                    initialValue: key,
                    autoSelect: isNew,
                    label: JsonEditorL10n.of(context).keyLabel,
                    onChanged: (newKey) => _onKeyChanged(index, newKey),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: valueSchema != null
                      ? SchemaResolver.resolve(
                          schema: valueSchema,
                          path: '${widget.path}.$key',
                          value: _data[key],
                          onChanged: (newVal) => _onValueChanged(index, newVal),
                          registry: registry,
                          isRequired: false,
                          isNullable: SchemaUtils.isNullable(valueSchema),
                          refDepth: widget.refDepth,
                        )
                      : StringEditor(
                          schema: widget.schema,
                          path: '${widget.path}.$key',
                          value: _data[key]?.toString() ?? '',
                          onChanged: (newVal) => _onValueChanged(index, newVal),
                          isRequired: false,
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeEntry(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// A key text field that optionally auto-selects its content on first build
/// so the user can immediately type a replacement.
class _KeyField extends StatefulWidget {
  final String initialValue;
  final bool autoSelect;
  final String label;
  final ValueChanged<String> onChanged;

  const _KeyField({
    required this.initialValue,
    required this.autoSelect,
    required this.label,
    required this.onChanged,
  });

  @override
  State<_KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<_KeyField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    if (widget.autoSelect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: widget.onChanged,
    );
  }
}
