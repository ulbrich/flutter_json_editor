import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../l10n/json_editor_l10n.dart';
import '../ref_lookup_provider.dart';
import 'remote_ref_editor.dart' show EnumSourceItem;

/// Renders a labeled single-choice editor from a pre-parsed `enumSource`
/// value/title list. The option `title` is shown while its `value` is stored.
///
/// This is the synchronous, in-schema counterpart to [RemoteRefEditor]: it is
/// used when a local `$ref` resolves to a `$defs`/`definitions` entry that
/// carries an `x-enum-source` block (see [parseEnumSource]).
class EnumSourceEditor extends StatelessWidget {
  final List<EnumSourceItem> items;
  final JsonSchema schema;
  final String path;
  final dynamic value;
  final void Function(dynamic) onChanged;
  final bool isRequired;
  final bool isNullable;

  const EnumSourceEditor({
    super.key,
    required this.items,
    required this.schema,
    required this.path,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    this.isNullable = false,
  });

  /// Parses an `enumSource` block into a flat list of [EnumSourceItem]s.
  ///
  /// Each entry may provide `value`/`title` templates (defaulting to
  /// `{{item.value}}` / `{{item.title}}`) and a `source` list of maps. This
  /// mirrors the remote-ref-lookup response parsing so both paths behave
  /// identically.
  static List<EnumSourceItem> parseEnumSource(List enumSources) {
    final items = <EnumSourceItem>[];
    for (final source in enumSources) {
      if (source is! Map) continue;
      final valueTemplate = source['value'] as String? ?? '{{item.value}}';
      final titleTemplate = source['title'] as String? ?? '{{item.title}}';
      final sourceList = source['source'] as List? ?? [];

      for (final item in sourceList) {
        if (item is Map) {
          items.add(EnumSourceItem(
            value: _resolveTemplate(valueTemplate, item),
            title: _resolveTemplate(titleTemplate, item),
          ));
        }
      }
    }
    return items;
  }

  /// Resolve templates like `{{item.value}}` or `{{item.nested.field}}`
  /// against a data map. Supports arbitrary dot-separated paths.
  static String _resolveTemplate(String template, Map item) {
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

  String _buildLabel(String base) => isRequired ? '$base *' : base;

  /// The stored value to preselect: the current value, or the schema default.
  String? get _selectedValue => (value ?? schema.defaultValue) as String?;

  @override
  Widget build(BuildContext context) {
    final labelText =
        _buildLabel(schema.title ?? path.split('.').last);
    final minTypeAhead = RefLookupProvider.of(context)?.minTypeAhead ?? 10;

    if (items.length >= minTypeAhead) {
      return _buildTypeAhead(context, labelText);
    }
    return _buildDropdown(context, labelText);
  }

  Widget _buildDropdown(BuildContext context, String labelText) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: schema.description,
      ),
      initialValue: _selectedValue,
      items: [
        if (!isRequired || isNullable)
          DropdownMenuItem<String>(
            value: null,
            child: Text(JsonEditorL10n.of(context).noneOptionLabel),
          ),
        ...items.map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            child: Text(item.title, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: schema.readOnly == true ? null : (val) => onChanged(val),
    );
  }

  Widget _buildTypeAhead(BuildContext context, String labelText) {
    final selected = _selectedValue;
    final currentTitle = items
        .where((item) => item.value == selected)
        .map((item) => item.title)
        .firstOrNull;

    return Autocomplete<EnumSourceItem>(
      initialValue: currentTitle != null
          ? TextEditingValue(text: currentTitle)
          : TextEditingValue.empty,
      displayStringForOption: (item) => item.title,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return items;
        final query = textEditingValue.text.toLowerCase();
        return items
            .where((item) => item.title.toLowerCase().contains(query));
      },
      onSelected: (item) => onChanged(item.value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            helperText: schema.description,
            suffixIcon: selected != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onChanged(null);
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
