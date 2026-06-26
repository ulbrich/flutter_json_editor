import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../l10n/json_editor_l10n.dart';
import '../ref_lookup_provider.dart';

class EnumSourceItem {
  final String value;
  final String title;
  const EnumSourceItem({required this.value, required this.title});
}

class RemoteRefEditor extends StatefulWidget {
  final String refUrl;
  final JsonSchema schema;
  final String path;
  final dynamic value;
  final void Function(dynamic) onChanged;
  final bool isRequired;
  final bool isNullable;

  const RemoteRefEditor({
    super.key,
    required this.refUrl,
    required this.schema,
    required this.path,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    required this.isNullable,
  });

  @override
  State<RemoteRefEditor> createState() => _RemoteRefEditorState();
}

class _RemoteRefEditorState extends State<RemoteRefEditor> {
  List<EnumSourceItem>? _items;
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadRemoteData();
    }
  }

  Future<void> _loadRemoteData() async {
    final provider = RefLookupProvider.of(context);
    if (provider?.onRefLookup == null) {
      setState(() {
        _loading = false;
        _error = JsonEditorL10n.of(context).noRefLookupCallbackError;
      });
      return;
    }

    try {
      final result =
          await provider!.lookup(widget.refUrl, widget.path, widget.value);
      if (result == null) {
        setState(() {
          _loading = false;
          _error = JsonEditorL10n.of(context).remoteSchemaUnavailableError;
        });
        return;
      }
      _parseEnumSource(result);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = JsonEditorL10n.of(context).failedToLoadError(e.toString());
      });
    }
  }

  void _parseEnumSource(Map<String, dynamic> data) {
    final enumSources = data['enumSource'] as List?;
    if (enumSources == null || enumSources.isEmpty) {
      setState(() {
        _loading = false;
        _error = JsonEditorL10n.of(context).noEnumSourceError;
      });
      return;
    }

    final items = <EnumSourceItem>[];
    for (final source in enumSources) {
      if (source is! Map) continue;
      final valueTemplate =
          source['value'] as String? ?? '{{item.value}}';
      final titleTemplate =
          source['title'] as String? ?? '{{item.title}}';
      final sourceList = source['source'] as List? ?? [];

      for (final item in sourceList) {
        if (item is Map) {
          final resolvedValue = _resolveTemplate(valueTemplate, item);
          final resolvedTitle = _resolveTemplate(titleTemplate, item);
          items.add(EnumSourceItem(value: resolvedValue, title: resolvedTitle));
        }
      }
    }

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// Resolve templates like `{{item.value}}` or `{{item.nested.field}}`
  /// against a data map. Supports arbitrary dot-separated paths.
  String _resolveTemplate(String template, Map item) {
    return template.replaceAllMapped(
      RegExp(r'\{\{item\.([^}]+)\}\}'),
      (match) {
        final path = match.group(1)!;
        dynamic current = item;
        for (final segment in path.split('.')) {
          if (current is Map) {
            current = current[segment];
          } else {
            return match.group(0)!; // unresolved — return template as-is
          }
        }
        return current?.toString() ?? '';
      },
    );
  }

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    final labelText = _buildLabel();

    // Loading state
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: InputDecoration(labelText: labelText, enabled: false),
            child: const LinearProgressIndicator(),
          ),
        ],
      );
    }

    // Error state — disabled field with message
    if (_error != null || _items == null) {
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: labelText,
          errorText: _error ?? JsonEditorL10n.of(context).remoteSchemaUnavailableError,
        ),
      );
    }

    final provider = RefLookupProvider.of(context);
    final minTypeAhead = provider?.minTypeAhead ?? 10;

    // Find the display title for the current stored value
    final currentTitle = _items!
        .where((item) => item.value == widget.value)
        .map((item) => item.title)
        .firstOrNull;

    if (_items!.length >= minTypeAhead) {
      return _buildTypeAhead(labelText, currentTitle);
    } else {
      return _buildDropdown(labelText);
    }
  }

  Widget _buildDropdown(String labelText) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      // Match the dropdown text size to the text-input fields.
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: widget.schema.description,
      ),
      initialValue: widget.value as String?,
      items: [
        if (!widget.isRequired || widget.isNullable)
          DropdownMenuItem<String>(
            value: null,
            child: Text(JsonEditorL10n.of(context).noneOptionLabel),
          ),
        ..._items!.map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            child: Text(item.title, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (val) => widget.onChanged(val),
    );
  }

  Widget _buildTypeAhead(String labelText, String? currentTitle) {
    return Autocomplete<EnumSourceItem>(
      initialValue: currentTitle != null
          ? TextEditingValue(text: currentTitle)
          : TextEditingValue.empty,
      displayStringForOption: (item) => item.title,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return _items!;
        final query = textEditingValue.text.toLowerCase();
        return _items!
            .where((item) => item.title.toLowerCase().contains(query));
      },
      onSelected: (item) => widget.onChanged(item.value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            helperText: widget.schema.description,
            suffixIcon: widget.value != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged(null);
                    },
                  )
                : null,
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }
}
