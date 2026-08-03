/// Returns a copy of [data] with each value replaced by its human-readable
/// label when the corresponding property is a labeled single choice — a
/// `oneOf`/`anyOf` whose branches carry a scalar `const` (optionally annotated
/// with a `title`). Non-choice values (free text, booleans, numbers) and values
/// without a matching option are returned unchanged.
///
/// A stored record holds the raw `const` codes (e.g. `category: "heating_water"`),
/// so this is the bridge to a human-facing display such as an `x-template`
/// summary, where `{{category}}` should read "Heating & water", not the code.
Map<String, dynamic> labelledData(
  Map<String, dynamic> schemaMap,
  Map<String, dynamic> data,
) {
  final props = schemaMap['properties'];
  if (props is! Map) {
    return Map<String, dynamic>.from(data);
  }

  final result = <String, dynamic>{};
  data.forEach((key, value) {
    result[key] = _labelFor(props[key], value) ?? value;
  });
  return result;
}

/// The `title` of the `oneOf`/`anyOf` branch whose scalar `const` equals
/// [value], or null when [prop] is not a labeled choice / nothing matches.
String? _labelFor(dynamic prop, dynamic value) {
  if (prop is! Map || value == null) return null;

  final branches = prop['oneOf'] ?? prop['anyOf'];
  if (branches is! List) return null;

  for (final branch in branches) {
    if (branch is Map &&
        branch.containsKey('const') &&
        branch['const'] == value) {
      return (branch['title'] ?? branch['const']).toString();
    }
  }
  return null;
}
