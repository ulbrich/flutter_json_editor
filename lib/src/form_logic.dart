import 'package:flutter/widgets.dart';
import 'package:json_schema/json_schema.dart';

import 'json_logic.dart';
import 'schema_utils.dart';

/// The properties an object schema shows for [data]: its own, those of its
/// `allOf` branches, of active `dependencies` and of active `if`/`then`/
/// `else` branches (also inside `allOf`) — the same set the object editor
/// renders.
Map<String, JsonSchema> effectiveProperties(
  JsonSchema schema,
  Map<dynamic, dynamic> data,
) {
  final result = <String, JsonSchema>{...schema.properties};
  for (final sub in schema.allOf) {
    result.addAll(sub.properties);
  }
  for (final entry in schema.schemaDependencies.entries) {
    if (data[entry.key] != null) result.addAll(entry.value.properties);
  }
  for (final cond in [
    if (schema.ifSchema != null) schema,
    ...schema.allOf.where((s) => s.ifSchema != null),
  ]) {
    final valid = cond.ifSchema!.validate(data).isValid;
    final branch = valid ? cond.thenSchema : cond.elseSchema;
    if (branch != null) result.addAll(branch.properties);
  }
  return result;
}

/// The `x-calc` rule of [schema], if it has one.
dynamic calcRule(JsonSchema schema) => schema.schemaMap?['x-calc'];

/// Whether [schema] is marked `"x-hidden": true`: kept in the data, never
/// shown.
bool isHiddenField(JsonSchema schema) => schema.schemaMap?['x-hidden'] == true;

/// Calculated fields: every property with an `x-calc` [JsonLogic] rule gets
/// the rule's result, read from the whole form (`{"var": "order.total"}`)
/// or, for paths starting with a dot, from the object holding the field
/// (`{"var": ".price"}`, handy inside array items).
class FormCalculator {
  FormCalculator._();

  /// [data] with every calculated field up to date, and the paths of fields
  /// whose rules depend on each other in a circle (left as they were in the
  /// last round). Rules that fail (an unknown operator) give null.
  static ({dynamic data, Set<String> cyclic}) apply(
    JsonSchema schema,
    dynamic data,
  ) {
    var current = _copy(data);
    var limit = 1;
    var changed = <String>{};
    for (var round = 0; round <= limit; round++) {
      changed = <String>{};
      var count = 0;
      _walk(schema, current, current, '', (path) => changed.add(path), () {
        count++;
      });
      // A chain of n rules settles in at most n rounds.
      limit = count;
      if (changed.isEmpty) return (data: current, cyclic: const <String>{});
    }
    return (data: current, cyclic: changed);
  }

  /// Whether the schema has any calculated field (so callers can skip the
  /// work for plain forms).
  static bool hasCalculations(JsonSchema schema) {
    final seen = <JsonSchema>{};
    bool visit(JsonSchema? s, int depth) {
      if (s == null || depth > 32) return false;
      s = SchemaUtils.resolveRef(s);
      if (!seen.add(s)) return false;
      if (calcRule(s) != null) return true;
      if (s.properties.values.any((p) => visit(p, depth + 1))) return true;
      if (s.allOf.any((a) => visit(a, depth + 1))) return true;
      if (visit(s.thenSchema, depth + 1) || visit(s.elseSchema, depth + 1)) {
        return true;
      }
      if (s.schemaDependencies.values.any((d) => visit(d, depth + 1))) {
        return true;
      }
      return visit(s.items, depth + 1);
    }

    return visit(schema, 0);
  }

  static void _walk(
    JsonSchema schema,
    dynamic value,
    dynamic root,
    String path,
    void Function(String path) onChanged,
    void Function() onRule,
  ) {
    schema = SchemaUtils.resolveRef(schema);
    if (value is Map) {
      final properties = effectiveProperties(schema, value);
      for (final entry in properties.entries) {
        final key = entry.key;
        final child = SchemaUtils.resolveRef(entry.value);
        final childPath = path.isEmpty ? key : '$path.$key';
        final rule = calcRule(child);
        if (rule != null) {
          onRule();
          dynamic result;
          try {
            result = _fit(child, JsonLogic.apply(rule, root, local: value));
          } on JsonLogicException {
            result = null;
          }
          if (!_deepEquals(result, value[key])) {
            if (result == null) {
              value.remove(key);
            } else {
              value[key] = result;
            }
            onChanged(childPath);
          }
        }
        final childValue = value[key];
        if (childValue is Map || childValue is List) {
          _walk(child, childValue, root, childPath, onChanged, onRule);
        }
      }
    } else if (value is List && schema.items != null) {
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map || item is List) {
          _walk(schema.items!, item, root, '$path[$i]', onChanged, onRule);
        }
      }
    }
  }

  /// [result] in the shape of [schema]: whole numbers for `integer`, text
  /// for `string`, null for what doesn't fit.
  static dynamic _fit(JsonSchema schema, dynamic result) {
    final type = SchemaUtils.detectType(schema);
    if (result == null || type == null) return result;
    if (type == SchemaType.integer) {
      return result is num && result.isFinite ? result.round() : null;
    }
    if (type == SchemaType.number) {
      return result is num && result.isFinite ? result : null;
    }
    if (type == SchemaType.string) {
      return result is String ? result : result.toString();
    }
    if (type == SchemaType.boolean) return JsonLogic.truthy(result);
    return result;
  }

  static dynamic _copy(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final e in value.entries) e.key.toString(): _copy(e.value),
      };
    }
    if (value is List) return [for (final v in value) _copy(v)];
    return value;
  }
}

bool _deepEquals(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Answer piping: `{{path}}` in a text is replaced by the answer at that
/// path of the whole form, `{{.key}}` by the one in [local] (the object
/// holding the field). Missing answers become [placeholder].
String pipeText(
  String text,
  dynamic root,
  dynamic local, {
  String placeholder = '…',
}) {
  if (!text.contains('{{')) return text;
  return text.replaceAllMapped(RegExp(r'\{\{\s*([^{}]+?)\s*\}\}'), (m) {
    final path = m.group(1)!;
    final value = path.startsWith('.')
        ? JsonLogic.lookup(local, path.substring(1))
        : JsonLogic.lookup(root, path);
    if (value == null || value == '') return placeholder;
    if (value is List) return value.join(', ');
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  });
}

/// The whole form's data and the calculated fields that are stuck in a
/// circle, for editors deep in the tree (answer piping, error display).
class FormScope extends InheritedWidget {
  const FormScope({
    super.key,
    required this.data,
    required this.cyclicPaths,
    required this.onSubmit,
    required super.child,
  });

  final dynamic data;
  final Set<String> cyclicPaths;

  /// [JsonEditor.onSubmit], for the wizard's finish button.
  final VoidCallback? onSubmit;

  static FormScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormScope>();

  @override
  bool updateShouldNotify(FormScope oldWidget) =>
      !identical(data, oldWidget.data) ||
      cyclicPaths.length != oldWidget.cyclicPaths.length ||
      !cyclicPaths.containsAll(oldWidget.cyclicPaths) ||
      (onSubmit == null) != (oldWidget.onSubmit == null);
}
