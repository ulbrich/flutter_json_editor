import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../editor_registry.dart';
import '../field_visibility.dart';
import '../schema_field_editor.dart';
import '../schema_resolver.dart';
import '../schema_utils.dart';

class ObjectEditor extends SchemaFieldEditor {
  final int refDepth;

  const ObjectEditor({
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
  State<ObjectEditor> createState() => _ObjectEditorState();
}

class _ObjectEditorState extends State<ObjectEditor> {
  late Map<String, dynamic> _data;

  // Track which properties came from conditional branches for cleanup
  Set<String> _thenKeys = {};
  Set<String> _elseKeys = {};

  // Evaluated conditional properties and required sets (populated by _evaluateConditionals)
  Map<String, JsonSchema> _conditionalProperties = {};
  Set<String> _conditionalRequired = {};

  @override
  void initState() {
    super.initState();
    final raw = widget.value;
    _data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    _evaluateConditionals();
  }

  @override
  void didUpdateWidget(ObjectEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final raw = widget.value;
      _data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    }
    if (widget.value != oldWidget.value || widget.schema != oldWidget.schema) {
      _evaluateConditionals();
    }
  }

  /// Evaluate if/then/else — the top-level one AND any nested inside `allOf`
  /// (standard JSON Schema, e.g. one conditional per category) — update the
  /// tracked sets, and drop data left over from branches that are no longer
  /// active. Must be called inside setState (or before first build).
  void _evaluateConditionals() {
    final conditionals = <JsonSchema>[
      if (widget.schema.ifSchema != null) widget.schema,
      ...widget.schema.allOf.where((s) => s.ifSchema != null),
    ];

    final newConditionalProperties = <String, JsonSchema>{};
    final newConditionalRequired = <String>{};
    final newThenKeys = <String>{};
    final newElseKeys = <String>{};

    for (final cond in conditionals) {
      final ifResult = cond.ifSchema!.validate(_data);
      if (ifResult.isValid && cond.thenSchema != null) {
        newThenKeys.addAll(cond.thenSchema!.properties.keys);
        newConditionalProperties.addAll(cond.thenSchema!.properties);
        final req = cond.thenSchema!.requiredProperties;
        if (req != null) newConditionalRequired.addAll(req);
      } else if (!ifResult.isValid && cond.elseSchema != null) {
        newElseKeys.addAll(cond.elseSchema!.properties.keys);
        newConditionalProperties.addAll(cond.elseSchema!.properties);
        final req = cond.elseSchema!.requiredProperties;
        if (req != null) newConditionalRequired.addAll(req);
      }
    }

    // Drop data for keys that fell out of every active branch and aren't base
    // properties, so a deactivated conditional field doesn't linger.
    final base = widget.schema.properties.keys.toSet();
    final active = newConditionalProperties.keys.toSet();
    for (final key in {..._thenKeys, ..._elseKeys}) {
      if (!active.contains(key) && !base.contains(key)) {
        _data.remove(key);
      }
    }

    _conditionalProperties = newConditionalProperties;
    _conditionalRequired = newConditionalRequired;
    _thenKeys = newThenKeys;
    _elseKeys = newElseKeys;
  }

  void _onChildChanged(String key, dynamic newValue) {
    setState(() {
      if (newValue == null) {
        _data.remove(key);
      } else {
        _data[key] = newValue;
      }
      _evaluateConditionals();
      widget.onChanged(Map<String, dynamic>.from(_data));
    });
  }

  @override
  Widget build(BuildContext context) {
    final registry = EditorRegistry.of(context);
    final visibility = FieldVisibilityScope.of(context);
    // Inside a fully-whitelisted subtree nothing needs filtering; otherwise
    // each property is checked against the whitelist below.
    final filterChildren =
        visibility.isFiltering && !visibility.isSubtreeVisible(widget.path);

    // Collect properties from base schema + allOf (last-one-wins on conflict)
    final Map<String, JsonSchema> allProperties = {};
    final Set<String> allRequired = {};

    // Base properties
    allProperties.addAll(widget.schema.properties);
    if (widget.schema.requiredProperties != null) {
      allRequired.addAll(widget.schema.requiredProperties!);
    }

    // allOf properties (multi-source iteration, last-one-wins)
    for (final subSchema in widget.schema.allOf) {
      allProperties.addAll(subSchema.properties);
      if (subSchema.requiredProperties != null) {
        allRequired.addAll(subSchema.requiredProperties!);
      }
    }

    // Property dependencies: when key is present in _data, listed props become required
    final propertyDeps = widget.schema.propertyDependencies;
    for (final entry in propertyDeps.entries) {
      if (_data.containsKey(entry.key) && _data[entry.key] != null) {
        allRequired.addAll(entry.value);
      }
    }

    // Schema dependencies: when key is present in _data, render additional fields
    final schemaDeps = widget.schema.schemaDependencies;
    for (final entry in schemaDeps.entries) {
      if (_data.containsKey(entry.key) && _data[entry.key] != null) {
        allProperties.addAll(entry.value.properties);
        if (entry.value.requiredProperties != null) {
          allRequired.addAll(entry.value.requiredProperties!);
        }
      }
    }

    // if/then/else: merge pre-evaluated conditional properties (no mutations here)
    allProperties.addAll(_conditionalProperties);
    allRequired.addAll(_conditionalRequired);

    final children = <Widget>[];
    for (final entry in allProperties.entries) {
      final key = entry.key;
      final childSchema = entry.value;
      final childPath = widget.path.isEmpty ? key : '${widget.path}.$key';
      // Hidden properties are skipped at render time only — their values stay
      // in `_data` and are passed back up unchanged.
      if (filterChildren && !visibility.isVisible(childPath)) continue;
      final childValue = _data[key];
      final childRequired = allRequired.contains(key);
      final childNullable = SchemaUtils.isNullable(childSchema);

      children.add(
        SchemaResolver.resolve(
          schema: childSchema,
          path: childPath,
          value: childValue,
          onChanged: (newVal) => _onChildChanged(key, newVal),
          registry: registry,
          isRequired: childRequired,
          isNullable: childNullable,
          refDepth: widget.refDepth,
        ),
      );
    }

    // A nested section whose every field was filtered out has nothing to show —
    // drop its header and border rather than leaving an empty shell behind.
    if (children.isEmpty && filterChildren && widget.path.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // Add spacing between children
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(const SizedBox(height: 4));
      }
    }

    // Root object: flat column, no decoration
    if (widget.path.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: spacedChildren,
      );
    }

    // Nested object: left-border accent with section header
    final theme = Theme.of(context);
    final title = widget.schema.title ?? widget.path.split('.').last;
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title + (widget.isRequired ? ' *' : ''),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (widget.schema.description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.schema.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: spacedChildren,
          ),
        ),
      ],
    );
  }
}
