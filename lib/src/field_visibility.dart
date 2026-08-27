import 'package:flutter/widgets.dart';

/// A whitelist of field paths controlling which parts of a form are rendered.
///
/// Rendering only. Data is never filtered: the editor keeps the full object it
/// was handed and returns it in full from `onUpdate`, so values behind hidden
/// fields survive a round-trip untouched.
///
/// The intended use case is a large schema of which only a small slice is
/// relevant right now — e.g. an agent that inspected a partially filled object,
/// decided which fields are still missing, and wants to show just those.
///
/// ## Path syntax
///
/// Paths use the same notation the editors build internally: dot-separated
/// property names with bracketed array indices.
///
/// ```
/// name                  // top-level property
/// address.zip           // nested property
/// contacts[0].email     // a specific array item's property
/// contacts[*].email     // that property in every array item
/// tags[*]               // every item of a scalar array
/// address.*             // every direct child of `address`
/// ```
///
/// JSON Pointer (`/address/zip`, `/contacts/0/email`) is accepted too and
/// normalized on construction, so paths coming straight out of a validator can
/// be passed through.
///
/// ## Matching rules
///
/// A node is rendered when its path is a whitelist entry, a **descendant** of
/// one, or an **ancestor** of one:
///
/// * descendant-or-self — the whole subtree is shown, unfiltered. Whitelisting
///   `address` shows every field of the address object.
/// * ancestor — the container is shown, but only as a shell for the whitelisted
///   descendants; its other children stay hidden. Whitelisting `address.zip`
///   renders the address section containing only the zip field.
///
/// Containers that end up with no visible children render nothing at all, and
/// arrays/maps that are only partially visible hide their add, delete, and
/// reorder controls — structural edits there would move fields out from under
/// the whitelist.
@immutable
class FieldVisibility {
  /// Whitelist entries, pre-parsed into segments. `null` means "no filtering".
  final List<List<String>>? _entries;

  /// Everything is visible. This is the default when no whitelist is given.
  const FieldVisibility.all() : _entries = null;

  const FieldVisibility._(this._entries);

  /// Renders only [paths] (plus the containers needed to reach them).
  ///
  /// An empty [paths] list yields a form that renders nothing — pass
  /// [FieldVisibility.all] instead if you mean "no filtering".
  factory FieldVisibility.whitelist(Iterable<String> paths) {
    return FieldVisibility._(
      paths.map(parsePath).where((segments) => segments.isNotEmpty).toList(
            growable: false,
          ),
    );
  }

  /// Whether this instance filters anything at all.
  bool get isFiltering => _entries != null;

  /// Whether the node at [path] should be rendered — either because it is
  /// inside the whitelist, or because it is a container on the way to a
  /// whitelisted descendant.
  bool isVisible(String path) {
    final entries = _entries;
    if (entries == null) return true;
    final segments = parsePath(path);
    // The root is always an ancestor of every entry.
    if (segments.isEmpty) return entries.isNotEmpty;
    for (final entry in entries) {
      if (_isPrefix(entry, segments) || _isPrefix(segments, entry)) return true;
    }
    return false;
  }

  /// Whether the node at [path] and its **entire subtree** are visible, so its
  /// children need no further filtering and its structural controls (add,
  /// delete, reorder) can stay enabled.
  bool isSubtreeVisible(String path) {
    final entries = _entries;
    if (entries == null) return true;
    final segments = parsePath(path);
    if (segments.isEmpty) return false;
    for (final entry in entries) {
      if (_isPrefix(entry, segments)) return true;
    }
    return false;
  }

  /// Whether the collection at [path] may be structurally edited — items added,
  /// removed, or reordered.
  ///
  /// True when the collection is fully visible, or when the whitelist only ever
  /// reaches into it through a wildcard index (`items[*].name`), in which case
  /// every item — including one added later — is rendered the same way. False
  /// when a concrete index is whitelisted (`items[0].name`), since adding or
  /// reordering would shuffle fields out from under the whitelist.
  bool allowsStructuralEdits(String path) {
    final entries = _entries;
    if (entries == null) return true;
    final segments = parsePath(path);
    if (segments.isEmpty) return false;
    var reached = false;
    for (final entry in entries) {
      if (_isPrefix(entry, segments)) return true;
      if (!_isPrefix(segments, entry)) continue;
      reached = true;
      final next = entry[segments.length];
      if (next != '[*]' && next != '*') return false;
    }
    return reached;
  }

  /// Whether [prefix] matches the leading segments of [path].
  static bool _isPrefix(List<String> prefix, List<String> path) {
    if (prefix.length > path.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (!_segmentsMatch(prefix[i], path[i])) return false;
    }
    return true;
  }

  /// A whitelist segment matches a concrete one literally, or as a wildcard.
  /// `*` matches any property name, `[*]` any array index.
  static bool _segmentsMatch(String pattern, String segment) {
    if (pattern == segment) return true;
    if (pattern == '*') return true;
    if (pattern == '[*]') return segment.startsWith('[');
    return false;
  }

  /// Splits a field path into segments: property names as-is, array indices as
  /// bracketed tokens (`[0]`, `[*]`).
  ///
  /// Accepts both the dotted form the editors use (`contacts[0].email`) and
  /// JSON Pointer (`/contacts/0/email`).
  static List<String> parsePath(String path) {
    var normalized = path.trim();
    if (normalized.startsWith(r'$')) normalized = normalized.substring(1);
    if (normalized.contains('/')) {
      normalized = _fromJsonPointer(normalized);
    }
    normalized = normalized.replaceAll('[', '.[');

    final segments = <String>[];
    for (final raw in normalized.split('.')) {
      final segment = raw.trim();
      if (segment.isEmpty) continue;
      segments.add(segment);
    }
    return segments;
  }

  /// Rewrites `/contacts/0/email` as `contacts[0].email`. Numeric and `*`
  /// segments become indices; `~1`/`~0` escapes are unescaped.
  static String _fromJsonPointer(String pointer) {
    final out = StringBuffer();
    for (final raw in pointer.split('/')) {
      final segment = raw.replaceAll('~1', '/').replaceAll('~0', '~');
      if (segment.isEmpty) continue;
      final isIndex = segment == '*' ||
          (segment.isNotEmpty && int.tryParse(segment) != null);
      if (isIndex) {
        out.write('[$segment]');
      } else {
        if (out.isNotEmpty) out.write('.');
        out.write(segment);
      }
    }
    return out.toString();
  }

  @override
  bool operator ==(Object other) {
    if (other is! FieldVisibility) return false;
    final a = _entries;
    final b = other._entries;
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (var j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    final entries = _entries;
    if (entries == null) return 0;
    return Object.hashAll(entries.map((e) => Object.hashAll(e)));
  }

  @override
  String toString() {
    final entries = _entries;
    if (entries == null) return 'FieldVisibility.all()';
    return 'FieldVisibility.whitelist('
        '${entries.map((e) => e.join('.')).toList()})';
  }
}

/// Makes a [FieldVisibility] available to every editor below it.
///
/// [JsonEditor] installs this automatically from its `visiblePaths` /
/// `visibility` arguments; editors read it via [FieldVisibilityScope.of].
class FieldVisibilityScope extends InheritedWidget {
  final FieldVisibility visibility;

  const FieldVisibilityScope({
    super.key,
    required this.visibility,
    required super.child,
  });

  /// The nearest visibility whitelist, or [FieldVisibility.all] when none is
  /// installed — so editors used standalone keep rendering everything.
  static FieldVisibility of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<FieldVisibilityScope>()
            ?.visibility ??
        const FieldVisibility.all();
  }

  @override
  bool updateShouldNotify(FieldVisibilityScope oldWidget) {
    return visibility != oldWidget.visibility;
  }
}
