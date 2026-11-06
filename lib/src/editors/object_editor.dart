import 'package:material_ui/material_ui.dart';
import 'package:json_schema/json_schema.dart';

import '../editor_registry.dart';
import '../field_visibility.dart';
import '../form_logic.dart';
import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../schema_resolver.dart';
import '../schema_utils.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'format_support.dart' show schemaTypeNames;

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

  /// The wizard's current step (for `"x-layout": "wizard"`).
  int _page = 0;

  /// Whether the wizard tried to leave an incomplete step.
  bool _showStepError = false;

  /// The tabs the user has left (for `"x-layout": "tabs"`): only those show
  /// that answers are missing.
  final Set<String> _leftTabs = {};

  /// Schemas with piped title/description, by path, so a rebuild with the
  /// same texts reuses them.
  final Map<String, (String, JsonSchema)> _piped = {};

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

    final formScope = FormScope.of(context);
    final rootData = formScope?.data ?? _data;
    final cyclic = formScope?.cyclicPaths ?? const <String>{};

    final keys = <String>[];
    final children = <Widget>[];
    for (final entry in allProperties.entries) {
      final key = entry.key;
      final childPath = widget.path.isEmpty ? key : '${widget.path}.$key';
      // Hidden properties are skipped at render time only — their values stay
      // in `_data` and are passed back up unchanged.
      if (filterChildren && !visibility.isVisible(childPath)) continue;
      if (isHiddenField(SchemaUtils.resolveRef(entry.value))) continue;
      final childSchema = _pipe(entry.value, childPath, rootData);
      final childValue = _data[key];
      final childRequired = allRequired.contains(key);
      final childNullable = SchemaUtils.isNullable(childSchema);

      Widget child = SchemaResolver.resolve(
        schema: childSchema,
        path: childPath,
        value: childValue,
        onChanged: (newVal) => _onChildChanged(key, newVal),
        registry: registry,
        isRequired: childRequired,
        isNullable: childNullable,
        refDepth: widget.refDepth,
      );
      if (cyclic.contains(childPath)) {
        child = _withError(
          context,
          child,
          JsonEditorL10n.of(context).calcCycleError,
        );
      }
      keys.add(key);
      children.add(child);
    }

    // Add spacing between children
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(const SizedBox(height: 4));
      }
    }

    final layout = widget.schema.schemaMap?['x-layout'];
    if (layout == 'wizard' && children.isNotEmpty) {
      return _wizard(
        context,
        keys,
        children,
        allProperties,
        allRequired,
        formScope?.onSubmit,
      );
    }
    if (layout == 'tabs' && children.isNotEmpty) {
      return _tabs(context, keys, children, allProperties, allRequired);
    }

    // Root object, "x-layout": "plain" or a tab's page: flat column, no
    // decoration
    if (widget.path.isEmpty ||
        layout == 'plain' ||
        _TabPage.isPage(context, widget.path)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: spacedChildren,
      );
    }

    // Nested object: left-border accent with section header
    final theme = Theme.of(context);
    final title = widget.schema.title ?? widget.path.split('.').last;
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.4);
    final heading = title + (widget.isRequired ? ' *' : '');
    final description = widget.schema.description;

    if (layout == 'card') {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: theme.textTheme.titleMedium),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ...spacedChildren,
            ],
          ),
        ),
      );
    }

    if (layout == 'collapsible') {
      return ExpansionTile(
        key: ValueKey('section:${widget.path}'),
        initiallyExpanded: widget.schema.schemaMap?['x-collapsed'] != true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 10, bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          heading,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: description == null
            ? null
            : Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        children: spacedChildren,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            heading,
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
            border: Border(left: BorderSide(color: borderColor, width: 1)),
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

  /// [schema] with `{{…}}` answers piped into its title and description.
  JsonSchema _pipe(JsonSchema schema, String path, dynamic rootData) {
    final map = schema.schemaMap;
    final title = map?['title'];
    final description = map?['description'];
    final pipes = (title is String && title.contains('{{')) ||
        (description is String && description.contains('{{'));
    if (map == null || !pipes) return schema;
    final newTitle = title is String ? pipeText(title, rootData, _data) : null;
    final newDescription =
        description is String ? pipeText(description, rootData, _data) : null;
    final cacheKey = '$newTitle\u0000$newDescription';
    final cached = _piped[path];
    if (cached != null && cached.$1 == cacheKey) return cached.$2;
    final copy = Map<String, dynamic>.from(map);
    if (newTitle != null) copy['title'] = newTitle;
    if (newDescription != null) copy['description'] = newDescription;
    // Keep local $refs resolvable in the copy.
    final rootMap = schema.root?.schemaMap;
    for (final key in const ['definitions', r'$defs']) {
      if (rootMap?[key] != null && !copy.containsKey(key)) {
        copy[key] = rootMap![key];
      }
    }
    JsonSchema piped;
    try {
      piped = SchemaUtils.createSchema(copy);
    } catch (_) {
      piped = schema;
    }
    _piped[path] = (cacheKey, piped);
    return piped;
  }

  Widget _withError(BuildContext context, Widget child, String message) {
    final theme = Theme.of(context);
    final editorTheme = theme.extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            message,
            style: editorTheme.errorStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
          ),
        ),
      ],
    );
  }

  /// Whether the wizard step for [key] may be left: required answers given
  /// and the value valid against its schema.
  bool _stepComplete(
    String key,
    Map<String, JsonSchema> properties,
    Set<String> required,
  ) {
    final value = _data[key];
    if (required.contains(key) && (value == null || value == '')) return false;
    final schema = properties[key];
    if (schema == null || value == null) return true;
    return ValidationHelper.validateField(
      SchemaUtils.resolveRef(schema),
      value,
    ).isEmpty;
  }

  String _childPath(String key) =>
      widget.path.isEmpty ? key : '${widget.path}.$key';

  /// One property per tab; the tab's label is the property's title, so an
  /// object on a tab renders without its own header. A tab the user left
  /// with missing or invalid answers is marked.
  Widget _tabs(
    BuildContext context,
    List<String> keys,
    List<Widget> pages,
    Map<String, JsonSchema> properties,
    Set<String> required,
  ) {
    final theme = Theme.of(context);
    final l10n = JsonEditorL10n.of(context);
    final page = _page.clamp(0, pages.length - 1);
    final rootData = FormScope.of(context)?.data ?? _data;

    Widget label(int i) {
      final key = keys[i];
      final schema = _pipe(properties[key]!, _childPath(key), rootData);
      final title = SchemaUtils.resolveRef(schema).title ?? key;
      final text = title + (required.contains(key) ? ' *' : '');
      final marked =
          _leftTabs.contains(key) &&
          i != page &&
          !_stepComplete(key, properties, required);
      return Tab(
        key: ValueKey('tab:$key'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
            if (marked) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.tabIncomplete,
                child: Icon(
                  Icons.error_outline,
                  key: ValueKey('tab-error:$key'),
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // An object page renders headerless, so its description goes here.
    final pageSchema = SchemaUtils.resolveRef(properties[keys[page]]!);
    final description = schemaTypeNames(pageSchema).contains('object')
        ? pageSchema.description
        : null;

    return DefaultTabController(
      key: ValueKey('tabs:${widget.path}:${pages.length}'),
      length: pages.length,
      initialIndex: page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            isScrollable: pages.length > 3,
            tabAlignment: pages.length > 3 ? TabAlignment.start : null,
            onTap: (i) => setState(() {
              _leftTabs.add(keys[page]);
              _page = i;
            }),
            tabs: [for (var i = 0; i < pages.length; i++) label(i)],
          ),
          const SizedBox(height: 12),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          _TabPage(
            path: _childPath(keys[page]),
            child: KeyedSubtree(
              key: ValueKey('tab-page:${keys[page]}'),
              child: pages[page],
            ),
          ),
        ],
      ),
    );
  }

  /// One property per step, with a progress bar and back/next buttons;
  /// "next" stays on a step until it is complete.
  Widget _wizard(
    BuildContext context,
    List<String> keys,
    List<Widget> pages,
    Map<String, JsonSchema> properties,
    Set<String> required,
    VoidCallback? onSubmit,
  ) {
    final theme = Theme.of(context);
    final l10n = JsonEditorL10n.of(context);
    final page = _page.clamp(0, pages.length - 1);
    final last = page == pages.length - 1;
    final complete = _stepComplete(keys[page], properties, required);

    void go(int to) {
      if (to > page && !complete) {
        setState(() => _showStepError = true);
        return;
      }
      setState(() {
        _page = to;
        _showStepError = false;
      });
    }

    return Column(
      key: ValueKey('wizard:${widget.path}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (page + 1) / pages.length,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.wizardStep(page + 1, pages.length),
              key: const ValueKey('wizard-step'),
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: ValueKey('wizard-page:${keys[page]}'),
          child: pages[page],
        ),
        if (_showStepError && !complete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.wizardStepIncomplete,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (page > 0)
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.wizardBack),
                onPressed: () => go(page - 1),
              ),
            const Spacer(),
            if (!last)
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.wizardNext),
                onPressed: () => go(page + 1),
              )
            else if (onSubmit != null)
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(l10n.wizardFinish),
                onPressed: () {
                  if (!complete) {
                    setState(() => _showStepError = true);
                    return;
                  }
                  onSubmit();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Marks the object at [path] as a tab's page, which renders without its
/// own header (the tab shows the title).
class _TabPage extends InheritedWidget {
  const _TabPage({required this.path, required super.child});

  final String path;

  static bool isPage(BuildContext context, String path) =>
      context.dependOnInheritedWidgetOfExactType<_TabPage>()?.path == path;

  @override
  bool updateShouldNotify(_TabPage oldWidget) => path != oldWidget.path;
}
