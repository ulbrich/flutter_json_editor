import 'catalog/editor_catalog.dart';

/// How bad a [LintIssue] is.
enum LintSeverity {
  /// The field won't render as intended (it falls back to a default editor,
  /// or a calculation can't run).
  error,

  /// It works, but likely not as meant.
  warning,
}

/// One finding of [SchemaLint.check].
class LintIssue {
  const LintIssue({
    required this.path,
    required this.code,
    required this.message,
    required this.severity,
  });

  /// JSON Pointer to the schema node, `/properties/order/properties/qty`.
  final String path;

  /// A stable id of the rule, `format-type`.
  final String code;

  /// What's wrong and how to fix it, written for people and LLMs alike.
  final String message;

  final LintSeverity severity;

  Map<String, dynamic> toJson() => {
    'path': path,
    'code': code,
    'severity': severity.name,
    'message': message,
  };

  @override
  String toString() => '${severity.name} $path: $message';
}

/// Finds what makes a schema render differently than its author meant:
/// unknown `x-format`s, editors on the wrong type or without choices,
/// scales out of range, misplaced keywords, calculations reading missing
/// fields or depending on themselves, piped answers that don't exist and
/// base64 data without limits.
///
/// Works on the plain JSON map (no Flutter needed), so servers can run the
/// same checks; the rules are driven by [EditorCatalog].
class SchemaLint {
  SchemaLint._();

  /// Keywords the editor writes itself while reading a schema.
  static const _internalKeywords = {'x-enum-source', 'x-remote-ref'};

  /// The issues of [schema], sorted by path. [formats] are `x-format`s the
  /// app registers itself; [keywords] are other `x-` keywords it uses.
  static List<LintIssue> check(
    Map<String, dynamic> schema, {
    Set<String> formats = const {},
    Set<String> keywords = const {},
  }) {
    final run = _Run(schema, formats, keywords);
    run.node(schema, '', const [], null);
    run.cycles();
    run.issues.sort((a, b) {
      final byPath = a.path.compareTo(b.path);
      if (byPath != 0) return byPath;
      final byCode = a.code.compareTo(b.code);
      return byCode != 0 ? byCode : a.message.compareTo(b.message);
    });
    return run.issues;
  }

  /// Only the errors of [check].
  static List<LintIssue> errors(
    Map<String, dynamic> schema, {
    Set<String> formats = const {},
    Set<String> keywords = const {},
  }) => [
    for (final i in check(schema, formats: formats, keywords: keywords))
      if (i.severity == LintSeverity.error) i,
  ];
}

/// The result of following a data path through the schema.
sealed class _Resolved {
  const _Resolved();
}

class _Found extends _Resolved {
  const _Found(this.path);

  /// The canonical data path, array indices as `*`.
  final List<String> path;
}

/// The path leads through something the lint can't follow (a remote
/// `$ref`, `additionalProperties`): assume it's fine.
class _Unknown extends _Resolved {
  const _Unknown();
}

class _Missing extends _Resolved {
  const _Missing();
}

class _Run {
  _Run(this.root, this.formats, this.keywords);

  final Map<String, dynamic> root;
  final Set<String> formats;
  final Set<String> keywords;
  final issues = <LintIssue>[];

  /// Calculated fields by canonical data path, with the paths they read.
  final calcs = <String, ({String pointer, Set<String> reads})>{};

  void error(String path, String code, String message) => issues.add(
    LintIssue(
      path: path,
      code: code,
      message: message,
      severity: LintSeverity.error,
    ),
  );

  void warning(String path, String code, String message) => issues.add(
    LintIssue(
      path: path,
      code: code,
      message: message,
      severity: LintSeverity.warning,
    ),
  );

  static String _escape(String key) =>
      key.replaceAll('~', '~0').replaceAll('/', '~1');

  static Set<String> typesOf(Map node) {
    final type = node['type'];
    final types = <String>{
      if (type is String) type,
      if (type is List) ...type.whereType<String>(),
    };
    if (types.isEmpty && node['properties'] is Map) types.add('object');
    return types;
  }

  static bool hasConstBranches(Map node) {
    for (final key in const ['oneOf', 'anyOf']) {
      final branches = node[key];
      if (branches is List &&
          branches.isNotEmpty &&
          branches.every((b) => b is Map && b.containsKey('const'))) {
        return true;
      }
    }
    return false;
  }

  static bool hasChoices(dynamic node) {
    if (node is! Map) return false;
    if (node.containsKey(r'$ref')) return true;
    final values = node['enum'];
    return (values is List && values.isNotEmpty) || hasConstBranches(node);
  }

  static String quoted(Iterable<String> names, String last) {
    final list = [for (final n in names) '"$n"'];
    if (list.length < 2) return list.join();
    return '${list.sublist(0, list.length - 1).join(', ')} $last ${list.last}';
  }

  static String plural(int n, String word) =>
      '$n ${n == 1
          ? word
          : word.endsWith('y')
          ? '${word.substring(0, word.length - 1)}ies'
          : '${word}s'}';

  /// Walks [node] at JSON Pointer [pointer]. [data] is its canonical data
  /// path (null inside definitions); [holder] that of the object holding
  /// it, for `{"var": ".x"}` and `{{.x}}`.
  void node(
    dynamic node,
    String pointer,
    List<String>? data,
    List<String>? holder,
  ) {
    if (node is! Map<String, dynamic>) return;
    final editor = checkFormat(node, pointer);
    checkKeywords(node, pointer, editor);
    checkLayout(node, pointer, editor);
    checkCalc(node, pointer, data, holder);
    checkPiping(node, pointer, data, holder);

    final properties = node['properties'];
    if (properties is Map<String, dynamic>) {
      for (final e in properties.entries) {
        this.node(
          e.value,
          '$pointer/properties/${_escape(e.key)}',
          data == null ? null : [...data, e.key],
          data,
        );
      }
    }
    final items = node['items'];
    if (items is Map<String, dynamic>) {
      this.node(
        items,
        '$pointer/items',
        data == null ? null : [...data, '*'],
        data,
      );
    } else if (items is List) {
      for (var i = 0; i < items.length; i++) {
        this.node(
          items[i],
          '$pointer/items/$i',
          data == null ? null : [...data, '*'],
          data,
        );
      }
    }
    for (final key in const ['allOf', 'anyOf', 'oneOf']) {
      final list = node[key];
      if (list is List) {
        for (var i = 0; i < list.length; i++) {
          this.node(list[i], '$pointer/$key/$i', data, holder);
        }
      }
    }
    for (final key in const ['if', 'then', 'else', 'not']) {
      this.node(node[key], '$pointer/$key', data, holder);
    }
    final dependencies = node['dependencies'];
    if (dependencies is Map<String, dynamic>) {
      for (final e in dependencies.entries) {
        this.node(
          e.value,
          '$pointer/dependencies/${_escape(e.key)}',
          data,
          holder,
        );
      }
    }
    for (final key in const ['definitions', r'$defs']) {
      final defs = node[key];
      if (defs is Map<String, dynamic>) {
        for (final e in defs.entries) {
          this.node(e.value, '$pointer/$key/${_escape(e.key)}', null, null);
        }
      }
    }
  }

  /// Checks the editor `x-format` (or a standard `format` with an editor)
  /// picks; returns the editor's name: the format, or `text`, `number`,
  /// `object`, `array`, `boolean` for fields without one.
  String? checkFormat(Map<String, dynamic> node, String pointer) {
    final types = typesOf(node);
    final xFormat = node['x-format'];
    String? name;
    if (xFormat is String) {
      if (EditorCatalog.byName(xFormat) != null &&
          !EditorCatalog.layouts.any((l) => l.name == xFormat)) {
        name = xFormat;
      } else if (formats.contains(xFormat)) {
        return xFormat;
      } else {
        error(
          pointer,
          'unknown-format',
          'Unknown "x-format" "$xFormat"; the field falls back to its '
              'default editor. Known formats: '
              '${EditorCatalog.formatNames.join(', ')}.',
        );
      }
    }
    if (name == null && xFormat is! String) {
      final std = node['format'];
      if (std is String &&
          EditorCatalog.formats.any(
            (d) => d.name == std || d.aliases.contains(std),
          )) {
        name = std;
      }
    }
    if (name == null) {
      if (types.contains('object')) return 'object';
      if (types.contains('array')) return 'array';
      if (types.contains('string')) return 'text';
      if (types.contains('number') || types.contains('integer')) {
        return 'number';
      }
      if (types.contains('boolean')) return 'boolean';
      return null;
    }

    final d = EditorCatalog.byName(name)!;
    const fallback = 'the field falls back to its default editor.';
    final wanted = d.types;
    if (wanted != null && !wanted.any(types.contains)) {
      error(
        pointer,
        'format-type',
        '"$name" needs "type": ${quoted(wanted, 'or')}; $fallback',
      );
      return null;
    }
    switch (d.requires) {
      case EditorRequirement.choices when !hasChoices(node):
        error(
          pointer,
          'format-choices',
          '"$name" needs choices: an "enum", or a "oneOf" of '
              '{"const", "title"} branches; $fallback',
        );
      case EditorRequirement.itemChoices when !hasChoices(node['items']):
        error(
          pointer,
          'format-choices',
          '"$name" needs choices on "items": an "enum", or a "oneOf" of '
              '{"const", "title"} branches; $fallback',
        );
      case EditorRequirement.rowChoices when !hasRows(node):
        error(
          pointer,
          'format-choices',
          '"$name" needs "properties" with choices (an "enum", or a "oneOf" '
              'of {"const", "title"} branches), one per row; $fallback',
        );
      case EditorRequirement.constChoices
          when !node.containsKey(r'$ref') && !hasConstBranches(node):
        error(
          pointer,
          'format-choices',
          '"$name" needs a "oneOf" of {"const", "title", "x-image"} '
              'branches; $fallback',
        );
      case EditorRequirement.svgAsset
          when node['x-svg-asset'] is! String ||
              (node['x-svg-asset'] as String).isEmpty:
        error(
          pointer,
          'format-choices',
          '"$name" needs an "x-svg-asset"; $fallback',
        );
      default:
        break;
    }
    final steps = d.steps;
    if (steps != null) {
      final min =
          _ceil(node['minimum'] ?? node['exclusiveMinimum']) ??
          steps.defaultMin;
      final max =
          _floor(node['maximum'] ?? node['exclusiveMaximum']) ??
          steps.defaultMax;
      final count = max - min + 1;
      if (count < steps.min || count > steps.max) {
        error(
          pointer,
          'scale-range',
          '"$name" shows ${steps.min} to ${steps.max} steps, not $count '
              '($min to $max); $fallback',
        );
        return null;
      }
      final labels = node['x-labels'];
      if (labels is List && labels.length != count) {
        warning(
          pointer,
          'scale-labels',
          '"x-labels" has ${plural(labels.length, 'label')} for '
              '${plural(count, 'step')}.',
        );
      }
    }
    if (d.largeData) {
      if (types.contains('array') && node['maxItems'] is! int) {
        warning(
          pointer,
          'large-data',
          'An array of "$name" without "maxItems": every file is stored in '
              'the data as base64.',
        );
      }
      if (name == 'image-data' &&
          node['x-max-width'] == null &&
          node['x-max-height'] == null) {
        warning(
          pointer,
          'large-data',
          '"image-data" without "x-max-width" or "x-max-height" stores '
              'photos at full size, megabytes each.',
        );
      }
    }
    return name;
  }

  static int? _ceil(dynamic n) => n is num ? n.ceil() : null;
  static int? _floor(dynamic n) => n is num ? n.floor() : null;

  static bool hasRows(Map node) {
    final properties = node['properties'];
    if (properties is! Map) return false;
    for (final row in properties.values) {
      if (row is! Map) continue;
      if (hasChoices(row)) return true;
      if (typesOf(row).contains('array') && hasChoices(row['items'])) {
        return true;
      }
    }
    return false;
  }

  static bool _ofType(dynamic value, KeywordType type) => switch (type) {
    KeywordType.string => value is String,
    KeywordType.boolean => value is bool,
    KeywordType.integer =>
      value is int || (value is double && value == value.roundToDouble()),
    KeywordType.number => value is num,
    KeywordType.stringList => value is List && value.every((v) => v is String),
    KeywordType.any => true,
  };

  static const _typeWords = {
    'string': 'a string',
    'boolean': 'true or false',
    'integer': 'an integer',
    'number': 'a number',
    'string[]': 'an array of strings',
  };

  static const _editorWords = {
    'text': 'text fields',
    'number': 'number fields',
    'object': 'objects',
  };

  void checkKeywords(
    Map<String, dynamic> node,
    String pointer,
    String? editor,
  ) {
    for (final key in node.keys) {
      if (!key.startsWith('x-')) continue;
      final k = EditorCatalog.keyword(key);
      if (k == null) {
        if (!SchemaLint._internalKeywords.contains(key) &&
            !keywords.contains(key)) {
          warning(
            pointer,
            'unknown-keyword',
            'Unknown keyword "$key"; the editor ignores it.',
          );
        }
        continue;
      }
      if (!_ofType(node[key], k.type)) {
        error(
          pointer,
          'keyword-type',
          '"$key" must be ${_typeWords[k.typeName]}.',
        );
        continue;
      }
      if (key == 'x-layout' || key == 'x-format') continue;
      final on = k.on;
      if (on != null && (editor == null || !on.contains(editor))) {
        final where = [for (final e in on) _editorWords[e] ?? '"$e"'];
        warning(
          pointer,
          'keyword-unused',
          '"$key" has no effect here; it works on ${where.join(', ')}.',
        );
        continue;
      }
      final layouts = k.layouts;
      if (layouts != null && !layouts.contains(node['x-layout'])) {
        warning(
          pointer,
          'keyword-unused',
          '"$key" has no effect here; it works on "x-layout": '
              '${quoted(layouts, 'or')}.',
        );
        continue;
      }
      final needs = k.needs;
      if (needs != null && !node.containsKey(needs)) {
        warning(
          pointer,
          'keyword-unused',
          '"$key" has no effect without "$needs".',
        );
      }
    }
  }

  void checkLayout(Map<String, dynamic> node, String pointer, String? editor) {
    final layout = node['x-layout'];
    if (layout is! String) return;
    final names = [for (final d in EditorCatalog.layouts) d.name];
    if (!names.contains(layout)) {
      error(
        pointer,
        'layout-value',
        'Unknown "x-layout" "$layout"; use ${quoted(names, 'or')}.',
      );
      return;
    }
    if (editor != 'object') {
      error(pointer, 'layout-type', '"x-layout" works on objects only.');
      return;
    }
    final properties = node['properties'];
    final count = properties is Map ? properties.length : 0;
    if ((layout == 'wizard' || layout == 'tabs') && count < 2) {
      final page = layout == 'wizard' ? 'step' : 'tab';
      warning(
        pointer,
        'layout-pages',
        '"$layout" with ${plural(count, 'property')}: every property is a '
            '$page, so give it at least two.',
      );
    }
  }

  void checkCalc(
    Map<String, dynamic> node,
    String pointer,
    List<String>? data,
    List<String>? holder,
  ) {
    if (!node.containsKey('x-calc')) return;
    final rule = node['x-calc'];
    final unknown = <String>{};
    final vars = <String>[];
    void walk(dynamic r, bool scoped) {
      if (r is List) {
        for (final x in r) {
          walk(x, scoped);
        }
        return;
      }
      if (r is! Map || r.length != 1) return;
      final op = r.keys.first as String;
      final args = r.values.first;
      if (!EditorCatalog.calcOperators.contains(op)) unknown.add(op);
      if (op == 'var') {
        final path = args is List ? (args.isEmpty ? null : args.first) : args;
        if (!scoped && path != null) vars.add('$path');
        if (args is List && args.length > 1) walk(args.sublist(1), scoped);
        return;
      }
      const iterating = {'map', 'filter', 'reduce', 'all', 'none', 'some'};
      if (iterating.contains(op) && args is List) {
        if (args.isNotEmpty) walk(args.first, scoped);
        if (args.length > 1) walk(args.sublist(1), true);
        return;
      }
      walk(args, scoped);
    }

    walk(rule, false);
    for (final op in unknown.toList()..sort()) {
      error(
        pointer,
        'calc-operator',
        '"x-calc" uses the unknown operator "$op"; the field stays empty. '
            'Known: ${EditorCatalog.calcOperators.join(' ')}.',
      );
    }
    final reads = <String>{};
    for (final v in vars) {
      if (v.isEmpty) continue;
      final resolved = resolveRef(v, holder);
      switch (resolved) {
        case _Found(:final path):
          reads.add(path.join('.'));
        case _Missing():
          warning(
            pointer,
            'calc-var',
            '"x-calc" reads "$v", which isn\'t a field of the form.',
          );
        case _Unknown():
          break;
      }
    }
    if (data != null) {
      calcs[data.join('.')] = (pointer: pointer, reads: reads);
    }
  }

  void checkPiping(
    Map<String, dynamic> node,
    String pointer,
    List<String>? data,
    List<String>? holder,
  ) {
    final pattern = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');
    for (final key in const ['title', 'description']) {
      final text = node[key];
      if (text is! String) continue;
      for (final m in pattern.allMatches(text)) {
        final ref = m.group(1)!;
        if (resolveRef(ref, holder) is _Missing) {
          warning(
            pointer,
            'pipe-unknown',
            '"$key" shows "{{$ref}}", which isn\'t a field of the form.',
          );
        }
      }
    }
  }

  /// Resolves a `var`/piping path: from the root, or from [holder] when it
  /// starts with a dot.
  _Resolved resolveRef(String ref, List<String>? holder) {
    if (ref.startsWith('.')) {
      if (holder == null) return const _Unknown();
      final base = resolvePath(holder);
      if (base is! _Found) return base;
      final rest = resolveFrom(nodeAt(holder), ref.substring(1).split('.'));
      return switch (rest) {
        _Found(:final path) => _Found([...holder, ...path]),
        _ => rest,
      };
    }
    return resolvePath(ref.split('.'));
  }

  _Resolved resolvePath(List<String> segments) => resolveFrom(root, segments);

  /// The schema node at canonical data path [path] (assumed found).
  dynamic nodeAt(List<String> path) {
    dynamic node = root;
    for (final seg in path) {
      node = deref(node);
      if (seg == '*') {
        node = node is Map ? node['items'] : null;
      } else {
        node = node is Map ? propertyOf(node, seg) : null;
      }
    }
    return node;
  }

  _Resolved resolveFrom(dynamic start, List<String> segments) {
    dynamic node = start;
    final out = <String>[];
    for (final seg in segments) {
      if (seg.isEmpty) return const _Missing();
      node = deref(node);
      if (node == null) return const _Unknown();
      if (node is! Map) return const _Missing();
      final items = node['items'];
      if (items != null && (int.tryParse(seg) != null || seg == '*')) {
        if (items is! Map) return const _Unknown();
        node = items;
        out.add('*');
        continue;
      }
      final child = propertyOf(node, seg);
      if (child != null) {
        node = child;
        out.add(seg);
        continue;
      }
      if (open(node)) return const _Unknown();
      return const _Missing();
    }
    return _Found(out);
  }

  /// Follows a local `$ref`; null for one the lint can't follow.
  dynamic deref(dynamic node) {
    var depth = 0;
    while (node is Map && node[r'$ref'] is String && depth++ < 16) {
      final ref = node[r'$ref'] as String;
      if (!ref.startsWith('#')) return null;
      dynamic target = root;
      for (final raw
          in ref.substring(1).split('/').where((s) => s.isNotEmpty)) {
        final seg = raw.replaceAll('~1', '/').replaceAll('~0', '~');
        if (target is Map) {
          target = target[seg];
        } else if (target is List && int.tryParse(seg) != null) {
          final i = int.parse(seg);
          target = i < target.length ? target[i] : null;
        } else {
          target = null;
        }
      }
      if (target == null) return null;
      node = target;
    }
    return node;
  }

  /// The schema of property [key] of an object, in its own properties or
  /// in those of its branches.
  dynamic propertyOf(Map node, String key) {
    final seen = <Map>{};
    dynamic find(dynamic n) {
      n = deref(n);
      if (n is! Map || !seen.add(n)) return null;
      final properties = n['properties'];
      if (properties is Map && properties.containsKey(key)) {
        return properties[key];
      }
      for (final k in const ['allOf', 'anyOf', 'oneOf']) {
        final list = n[k];
        if (list is List) {
          for (final b in list) {
            final hit = find(b);
            if (hit != null) return hit;
          }
        }
      }
      for (final k in const ['then', 'else']) {
        final hit = find(n[k]);
        if (hit != null) return hit;
      }
      final deps = n['dependencies'];
      if (deps is Map) {
        for (final d in deps.values) {
          final hit = find(d);
          if (hit != null) return hit;
        }
      }
      return null;
    }

    return find(node);
  }

  /// Whether an object takes properties it doesn't name.
  static bool open(Map node) {
    final extra = node['additionalProperties'];
    return extra is Map || node['patternProperties'] is Map;
  }

  /// Reports calculated fields that depend on themselves.
  void cycles() {
    for (final entry in calcs.entries) {
      final start = entry.key;
      final seen = <String>{};
      final queue = [...entry.value.reads];
      var cyclic = false;
      while (queue.isNotEmpty) {
        final next = queue.removeLast();
        if (next == start) {
          cyclic = true;
          break;
        }
        if (!seen.add(next)) continue;
        final calc = calcs[next];
        if (calc != null) queue.addAll(calc.reads);
      }
      if (cyclic) {
        error(
          entry.value.pointer,
          'calc-cycle',
          '"x-calc" of "$start" depends on its own value; it keeps its '
              'last value.',
        );
      }
    }
  }
}
