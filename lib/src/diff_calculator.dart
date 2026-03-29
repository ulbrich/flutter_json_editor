class DiffCalculator {
  /// Returns only the changed paths between [previous] and [current].
  ///
  /// - Additions: key present in [current] but not in [previous]
  /// - Removals: key present in [previous] but not in [current] → value is null in diff
  /// - Modifications: same key, different value
  /// - Nested maps: recursed into
  /// - Lists: if different, includes the full new list
  static Map<String, dynamic> diff(
    Map<String, dynamic>? previous,
    Map<String, dynamic>? current,
  ) {
    final prev = previous ?? {};
    final curr = current ?? {};
    return _diffMaps(prev, curr);
  }

  /// Generic diff that handles both Map and List roots.
  /// Returns the diff representation, or null if equal.
  static dynamic computeDiff(dynamic previous, dynamic current) {
    if (previous is Map<String, dynamic> && current is Map<String, dynamic>) {
      return _diffMaps(previous, current);
    }
    if (previous is List && current is List) {
      if (_deepEqual(previous, current)) return <String, dynamic>{};
      // For lists, return the full new list as the diff
      return current;
    }
    // Fallback: map-based diff if both are maps, otherwise return current
    if (previous is Map && current is Map) {
      return _diffMaps(
        Map<String, dynamic>.from(previous),
        Map<String, dynamic>.from(current),
      );
    }
    return current;
  }

  static Map<String, dynamic> _diffMaps(
    Map<String, dynamic> previous,
    Map<String, dynamic> current,
  ) {
    final result = <String, dynamic>{};

    // Check for removals and modifications
    for (final key in previous.keys) {
      if (!current.containsKey(key)) {
        result[key] = null;
      } else {
        final prevVal = previous[key];
        final currVal = current[key];
        final nested = _diffValues(prevVal, currVal);
        if (nested != null) {
          result[key] = nested;
        }
      }
    }

    // Check for additions
    for (final key in current.keys) {
      if (!previous.containsKey(key)) {
        result[key] = current[key];
      }
    }

    return result;
  }

  /// Returns the diff value if [prev] and [curr] differ, or null if equal.
  static dynamic _diffValues(dynamic prev, dynamic curr) {
    if (prev is Map<String, dynamic> && curr is Map<String, dynamic>) {
      final nested = _diffMaps(prev, curr);
      return nested.isEmpty ? null : nested;
    }

    if (_deepEqual(prev, curr)) return null;

    return curr;
  }

  static bool _deepEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
  }
}
