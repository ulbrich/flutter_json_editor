import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';
import 'package:uuid/uuid.dart';

import '../editor_registry.dart';
import '../schema_field_editor.dart';
import '../schema_resolver.dart';
import '../schema_utils.dart';

class ArrayEditor extends SchemaFieldEditor {
  final int refDepth;

  const ArrayEditor({
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
  State<ArrayEditor> createState() => _ArrayEditorState();
}

class _ArrayEditorState extends State<ArrayEditor> {
  late List<dynamic> _data;
  late List<String> _itemIds;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _data = List<dynamic>.from((widget.value as List?) ?? []);
    _itemIds = List.generate(_data.length, (_) => _uuid.v4());
  }

  @override
  void didUpdateWidget(ArrayEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newData = List<dynamic>.from((widget.value as List?) ?? []);
      // Adjust stable IDs: keep existing, add new, drop removed
      if (newData.length > _data.length) {
        final extras = newData.length - _data.length;
        _itemIds.addAll(List.generate(extras, (_) => _uuid.v4()));
      } else if (newData.length < _data.length) {
        _itemIds = _itemIds.sublist(0, newData.length);
      }
      _data = newData;
    }
  }

  void _addItem() {
    setState(() {
      _data.add(_getDefaultValue());
      _itemIds.add(_uuid.v4());
      widget.onChanged(List.from(_data));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _data.removeAt(index);
      _itemIds.removeAt(index);
      widget.onChanged(List.from(_data));
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _data.removeAt(oldIndex);
      final id = _itemIds.removeAt(oldIndex);
      _data.insert(newIndex, item);
      _itemIds.insert(newIndex, id);
      widget.onChanged(List.from(_data));
    });
  }

  void _onItemChanged(int index, dynamic newValue) {
    setState(() {
      _data[index] = newValue;
      widget.onChanged(List.from(_data));
    });
  }

  dynamic _getDefaultValue() {
    final itemSchema = widget.schema.items;
    if (itemSchema?.defaultValue != null) return itemSchema!.defaultValue;
    final type = itemSchema != null ? SchemaUtils.detectType(itemSchema) : null;
    switch (type) {
      case SchemaType.string:
        return '';
      case SchemaType.integer:
      case SchemaType.number:
        return 0;
      case SchemaType.boolean:
        return false;
      case SchemaType.object:
        return <String, dynamic>{};
      case SchemaType.array:
        return <dynamic>[];
      default:
        return '';
    }
  }

  JsonSchema _getItemSchema(int index) {
    if (widget.schema.itemsList != null &&
        index < widget.schema.itemsList!.length) {
      final tupleSchema = widget.schema.itemsList![index];
      if (tupleSchema != null) return tupleSchema;
    }
    return widget.schema.items ?? JsonSchema.create({});
  }

  @override
  Widget build(BuildContext context) {
    final registry = EditorRegistry.of(context);
    final title = widget.schema.title ?? widget.path.split('.').last;
    final canAdd = widget.schema.maxItems == null ||
        _data.length < widget.schema.maxItems!;
    final canRemove = widget.schema.minItems == null ||
        _data.length > widget.schema.minItems!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title + (widget.isRequired ? ' *' : ''),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (canAdd)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addItem,
                tooltip: 'Add item',
              ),
          ],
        ),
        if (widget.schema.description != null)
          Text(
            widget.schema.description!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _data.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final itemSchema = _getItemSchema(index);
            return ListTile(
              titleAlignment: ListTileTitleAlignment.top,
              contentPadding: const EdgeInsets.fromLTRB(2.0, 0.0, 0.0, 0.0),
              key: ValueKey(_itemIds[index]),
              title: SchemaResolver.resolve(
                schema: itemSchema,
                path: '${widget.path}[$index]',
                value: _data[index],
                onChanged: (newVal) => _onItemChanged(index, newVal),
                registry: registry,
                isRequired: false,
                isNullable: SchemaUtils.isNullable(itemSchema),
                refDepth: widget.refDepth,
              ),
              trailing: canRemove
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeItem(index),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}
