import 'package:flutter/widgets.dart';
import 'package:json_schema/json_schema.dart';

import 'diff_calculator.dart';
import 'editor_registry.dart';
import 'field_visibility.dart';
import 'l10n/generated/json_editor_localizations.dart';
import 'ref_lookup_provider.dart';
import 'schema_resolver.dart';

class JsonEditor extends StatefulWidget {
  final JsonSchema schema;
  final dynamic initialData;
  final void Function(dynamic fullData, dynamic diff)? onUpdate;
  final EditorRegistryData? registry;

  /// Called when a `$ref` is a URL (http/https). The callback should fetch the
  /// remote data and return the response. Returns null on failure.
  final Future<Map<String, dynamic>?> Function(
    String refUrl,
    String fieldPath,
    dynamic currentValue,
  )?
  onRefLookup;

  /// Minimum number of items in a remote enum before switching from dropdown
  /// to typeahead/autocomplete. Default: 10.
  final int minTypeAhead;

  /// Whitelist of field paths to render, e.g.
  /// `['name', 'address.zip', 'contacts[*].email']`. When null (the default)
  /// the whole schema is rendered.
  ///
  /// Only *rendering* is affected — [initialData] is kept in full and handed
  /// back unchanged by [onUpdate], so values behind hidden fields survive the
  /// round-trip. See [FieldVisibility] for the path syntax and matching rules.
  ///
  /// Ignored when [visibility] is given.
  final List<String>? visiblePaths;

  /// The visibility whitelist, for callers that want to build or reuse a
  /// [FieldVisibility] directly. Takes precedence over [visiblePaths].
  final FieldVisibility? visibility;

  const JsonEditor({
    super.key,
    required this.schema,
    this.initialData,
    this.onUpdate,
    this.registry,
    this.onRefLookup,
    this.minTypeAhead = 10,
    this.visiblePaths,
    this.visibility,
  });

  @override
  State<JsonEditor> createState() => JsonEditorState();
}

class JsonEditorState extends State<JsonEditor> {
  late dynamic _currentData;
  dynamic _previousData;

  dynamic get currentData {
    if (_currentData is Map) {
      return Map<String, dynamic>.unmodifiable(_currentData as Map);
    }
    if (_currentData is List) {
      return List.unmodifiable(_currentData as List);
    }
    return _currentData;
  }

  /// The effective whitelist: an explicit [JsonEditor.visibility] wins, then
  /// [JsonEditor.visiblePaths], else no filtering.
  FieldVisibility get _visibility {
    final explicit = widget.visibility;
    if (explicit != null) return explicit;
    final paths = widget.visiblePaths;
    if (paths == null) return const FieldVisibility.all();
    return FieldVisibility.whitelist(paths);
  }

  bool get _isArrayRoot =>
      widget.schema.type == SchemaType.array ||
      (widget.schema.typeList != null &&
          widget.schema.typeList!.contains(SchemaType.array));

  @override
  void initState() {
    super.initState();
    _currentData = _initData(widget.initialData);
  }

  dynamic _initData(dynamic source) {
    if (_isArrayRoot) {
      if (source is List) return List<dynamic>.from(source);
      return <dynamic>[];
    }
    if (source is Map) return Map<String, dynamic>.from(source);
    // Graceful handling: if a List is passed for an object schema, unwrap first item
    if (source is List && source.isNotEmpty && source.first is Map) {
      return Map<String, dynamic>.from(source.first as Map);
    }
    return <String, dynamic>{};
  }

  void _onRootChanged(dynamic value) {
    if (!mounted) return;
    setState(() {
      _previousData = _currentData is Map
          ? Map<String, dynamic>.from(_currentData as Map)
          : _currentData is List
          ? List<dynamic>.from(_currentData as List)
          : _currentData;
      if (value is Map) {
        _currentData = Map<String, dynamic>.from(value);
      } else if (value is List) {
        _currentData = List<dynamic>.from(value);
      } else {
        _currentData = value;
      }
      final diff = DiffCalculator.computeDiff(_previousData, _currentData);
      widget.onUpdate?.call(_currentData, diff);
    });
  }

  @override
  Widget build(BuildContext context) {
    final registry = widget.registry ?? EditorRegistry.of(context) ?? EditorRegistryData();

    Widget child = SchemaResolver.resolve(
      schema: widget.schema,
      path: '',
      value: _currentData,
      onChanged: _onRootChanged,
      registry: registry,
      isRequired: false,
    );

    child = EditorRegistry(data: registry, child: child);

    child = FieldVisibilityScope(visibility: _visibility, child: child);

    child = RefLookupProvider(
      onRefLookup: widget.onRefLookup,
      minTypeAhead: widget.minTypeAhead,
      child: child,
    );

    // Ensure JsonEditorLocalizations is always available — even when the
    // consuming app does not register the delegate itself.
    final hasL10n = Localizations.of<JsonEditorLocalizations>(
          context,
          JsonEditorLocalizations,
        ) !=
        null;
    if (!hasL10n) {
      child = Localizations.override(
        context: context,
        delegates: const [JsonEditorLocalizations.delegate],
        child: child,
      );
    }

    return child;
  }
}
