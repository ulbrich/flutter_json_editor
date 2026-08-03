/// A required property that is missing (empty) from a data map.
class MissingRequiredField {
  const MissingRequiredField({required this.key, required this.title});

  /// The property name in the schema's `properties`.
  final String key;

  /// The property's `title` (falls back to [key] when untitled), for surfacing
  /// the field to the user.
  final String title;

  @override
  bool operator ==(Object other) =>
      other is MissingRequiredField && other.key == key && other.title == title;

  @override
  int get hashCode => Object.hash(key, title);

  @override
  String toString() => 'MissingRequiredField($key)';
}

/// Returns the required properties of [schemaMap] that are absent or empty in
/// [data].
///
/// A property is considered *required* when it is listed in the schema's
/// top-level `required`, or in the `then.required` of any `allOf` branch whose
/// `if` currently matches [data] (the same const-condition model
/// [ObjectEditor] uses to render conditional fields). A property is considered
/// *filled* when its value is non-null and not a blank/whitespace string, or
/// when it declares a schema `default` (so defaulted fields never report as
/// missing).
///
/// This is a pure function over the raw schema map and data, so it works the
/// same whether the data came from a live editor or a stored record, and it is
/// straightforward to unit test.
List<MissingRequiredField> findMissingRequired(
  Map<String, dynamic> schemaMap,
  Map<String, dynamic> data,
) {
  final props = schemaMap['properties'];
  if (props is! Map) {
    return const <MissingRequiredField>[];
  }

  final missing = <MissingRequiredField>[];
  for (final key in _effectiveRequired(schemaMap, data)) {
    final prop = props[key];
    final hasDefault = prop is Map && prop.containsKey('default');
    final value = data[key];
    final filled = value != null && !(value is String && value.trim().isEmpty);

    if (!filled && !hasDefault) {
      final title = (prop is Map ? prop['title'] : null)?.toString() ?? key;
      missing.add(MissingRequiredField(key: key, title: title));
    }
  }
  return missing;
}

/// The effective required-key set: the base `required` plus the `then.required`
/// of every `allOf` branch whose `if` matches [data].
Set<String> _effectiveRequired(
  Map<String, dynamic> schemaMap,
  Map<String, dynamic> data,
) {
  final result = <String>{};

  final base = schemaMap['required'];
  if (base is List) {
    result.addAll(base.map((key) => key.toString()));
  }

  final allOf = schemaMap['allOf'];
  if (allOf is List) {
    for (final entry in allOf) {
      if (entry is Map && _ifMatches(entry['if'], data)) {
        final then = entry['then'];
        final thenRequired = then is Map ? then['required'] : null;
        if (thenRequired is List) {
          result.addAll(thenRequired.map((key) => key.toString()));
        }
      }
    }
  }

  return result;
}

/// Whether an `if` sub-schema's `const` property conditions all hold in [data].
bool _ifMatches(dynamic ifSchema, Map<String, dynamic> data) {
  if (ifSchema is! Map) return false;
  final ifProps = ifSchema['properties'];
  if (ifProps is! Map) return false;

  for (final entry in ifProps.entries) {
    final condition = entry.value;
    if (condition is Map && condition.containsKey('const')) {
      if (data[entry.key] != condition['const']) {
        return false;
      }
    }
  }
  return true;
}
