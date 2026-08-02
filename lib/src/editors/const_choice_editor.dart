import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../l10n/json_editor_l10n.dart';

/// A single labeled choice extracted from a `const` sub-schema of a
/// `oneOf`/`anyOf` composition.
class ConstChoice {
  final dynamic value;
  final String title;

  const ConstChoice({required this.value, required this.title});
}

/// Renders a labeled single-choice dropdown from a `oneOf`/`anyOf` whose
/// branches are all scalar `const`s (each optionally annotated with a
/// `title`). The branch `title` is shown while the typed `const` value is
/// stored — the standards-compliant, self-validating counterpart to the
/// json-editor `enumSource` block (which stays supported).
///
/// Heterogeneous compositions (branches that are objects, differing types,
/// etc.) are NOT handled here — see [tryExtract], which returns null so the
/// resolver falls back to the variant `CompositionEditor`.
class ConstChoiceEditor extends StatelessWidget {
  final List<ConstChoice> choices;
  final JsonSchema schema;
  final String path;
  final dynamic value;
  final void Function(dynamic) onChanged;
  final bool isRequired;
  final bool isNullable;

  const ConstChoiceEditor({
    super.key,
    required this.choices,
    required this.schema,
    required this.path,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    this.isNullable = false,
  });

  /// Extracts labeled choices from a composition schema IFF every `oneOf`
  /// (or, failing that, `anyOf`) branch carries a scalar `const`. Returns null
  /// when the composition is empty or heterogeneous, so the caller can fall
  /// back to the variant `CompositionEditor`.
  static List<ConstChoice>? tryExtract(JsonSchema schema) {
    final branches = schema.oneOf.isNotEmpty
        ? schema.oneOf
        : (schema.anyOf.isNotEmpty ? schema.anyOf : const <JsonSchema>[]);
    if (branches.isEmpty) return null;

    final result = <ConstChoice>[];
    for (final branch in branches) {
      final map = branch.schemaMap;
      if (map == null || !map.containsKey('const')) return null;
      final constValue = map['const'];
      // Only scalar consts render as a dropdown option.
      if (constValue is Map || constValue is List) return null;
      final title =
          (map['title'] as String?) ?? branch.title ?? constValue.toString();
      result.add(ConstChoice(value: constValue, title: title));
    }
    return result;
  }

  bool get _includeNull => !isRequired || isNullable;

  String get _label {
    final base = schema.title ?? path.split('.').last;
    return isRequired ? '$base *' : base;
  }

  dynamic get _selected {
    final values = choices.map((c) => c.value).toSet();
    final candidate = value ?? schema.defaultValue;
    return values.contains(candidate) ? candidate : null;
  }

  @override
  Widget build(BuildContext context) {
    // If the stored value is no longer among the options — e.g. a conditional
    // (if/then) parent field changed the allowed set — clear it after this
    // frame so an invalid value can't be silently kept.
    if (value != null && !choices.any((c) => c.value == value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
    }
    return DropdownButtonFormField<Object?>(
      // Reset the form-field state when the option set changes, so a value from
      // the previous set doesn't linger (and doesn't trip the dropdown's
      // "value must match exactly one item" assertion).
      key: ValueKey(choices.map((c) => c.value).join('')),
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyLarge,
      initialValue: _selected,
      decoration: InputDecoration(
        labelText: _label,
        helperText: schema.description,
      ),
      items: [
        if (_includeNull)
          DropdownMenuItem<Object?>(
            value: null,
            child: Text(JsonEditorL10n.of(context).noneOptionLabel),
          ),
        ...choices.map(
          (choice) => DropdownMenuItem<Object?>(
            value: choice.value,
            child: Text(choice.title, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: schema.readOnly == true ? null : (v) => onChanged(v),
    );
  }
}
