import 'dart:math' as math;

/// A [JSON Logic](https://jsonlogic.com) evaluator for the `x-calc` rules of
/// calculated fields.
///
/// A rule is plain JSON: `{"operator": [arguments…]}`, or a value that stands
/// for itself. Rules are data, not code: they can't loop forever or reach
/// anything but the data they are given.
///
/// Supported operators: `var`, `missing`, `missing_some`, `if` (and its
/// alias `?:`), `==`, `===`, `!=`, `!==`, `!`, `!!`, `or`, `and`, `>`, `>=`,
/// `<`, `<=` (also as "between" with three arguments), `max`, `min`, `+`,
/// `-`, `*`, `/`, `%`, `map`, `filter`, `reduce`, `all`, `none`, `some`,
/// `merge`, `in`, `cat`, `substr`, and two additions beyond the standard:
/// `round` (`{"round": [value, digits]}`) and `count`
/// (`{"count": [array]}`, the number of items that aren't null).
///
/// `var` paths are dotted (`order.items.0.price`) and read from the data the
/// rule is applied to. [JsonLogic.apply] also takes a [local] object: paths
/// starting with a dot (`.price`) read from it instead, wherever in the rule
/// they appear — the form uses that for the object holding the field.
class JsonLogic {
  JsonLogic._();

  /// The result of [rule] for [data]; [local] answers `var` paths starting
  /// with a dot. Throws a [JsonLogicException] for an unknown operator.
  static dynamic apply(dynamic rule, dynamic data, {dynamic local}) =>
      _Evaluator(local).eval(rule, data);

  /// The `var` paths [rule] reads, as written (with the leading dot of local
  /// paths).
  static Set<String> variables(dynamic rule) {
    final result = <String>{};
    void walk(dynamic node) {
      if (node is List) {
        node.forEach(walk);
      } else if (node is Map) {
        for (final entry in node.entries) {
          if (entry.key == 'var') {
            final arg = entry.value;
            final path = arg is List ? (arg.isEmpty ? null : arg.first) : arg;
            if (path is String || path is num) result.add(path.toString());
          }
          walk(entry.value);
        }
      }
    }

    walk(rule);
    return result;
  }

  /// JSON Logic truthiness: `0`, `""`, `[]`, `null` and `false` are false.
  static bool truthy(dynamic value) {
    if (value == null || value == false) return false;
    if (value is num) return value != 0 && !value.isNaN;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  /// The value at the dotted [path] of [data]; null when there is none.
  static dynamic lookup(dynamic data, String path) {
    if (path.isEmpty) return data;
    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is Map) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
      if (current == null) return null;
    }
    return current;
  }
}

/// Thrown for a rule that can't be evaluated, e.g. with an unknown operator.
class JsonLogicException implements Exception {
  JsonLogicException(this.message);
  final String message;
  @override
  String toString() => 'JsonLogicException: $message';
}

class _Evaluator {
  _Evaluator(this.local);

  final dynamic local;

  dynamic eval(dynamic rule, dynamic data) {
    if (rule is List) return [for (final r in rule) eval(r, data)];
    if (rule is! Map || rule.length != 1) return rule;
    final op = rule.keys.first as String;
    final raw = rule.values.first;
    final args = raw is List ? raw : [raw];

    // Operators that decide themselves which arguments to evaluate.
    switch (op) {
      case 'if':
      case '?:':
        var i = 0;
        for (; i + 1 < args.length; i += 2) {
          if (JsonLogic.truthy(eval(args[i], data))) {
            return eval(args[i + 1], data);
          }
        }
        return i < args.length ? eval(args[i], data) : null;
      case 'and':
        dynamic value;
        for (final a in args) {
          value = eval(a, data);
          if (!JsonLogic.truthy(value)) return value;
        }
        return value;
      case 'or':
        dynamic value;
        for (final a in args) {
          value = eval(a, data);
          if (JsonLogic.truthy(value)) return value;
        }
        return value;
      case 'map':
      case 'filter':
      case 'all':
      case 'none':
      case 'some':
        final list = _list(eval(args.isEmpty ? null : args[0], data));
        final body = args.length > 1 ? args[1] : null;
        switch (op) {
          case 'map':
            return [for (final item in list) eval(body, item)];
          case 'filter':
            return [
              for (final item in list)
                if (JsonLogic.truthy(eval(body, item))) item,
            ];
          case 'all':
            return list.isNotEmpty &&
                list.every((item) => JsonLogic.truthy(eval(body, item)));
          case 'none':
            return !list.any((item) => JsonLogic.truthy(eval(body, item)));
          default:
            return list.any((item) => JsonLogic.truthy(eval(body, item)));
        }
      case 'reduce':
        final list = _list(eval(args.isEmpty ? null : args[0], data));
        final body = args.length > 1 ? args[1] : null;
        dynamic acc = args.length > 2 ? eval(args[2], data) : null;
        for (final item in list) {
          acc = eval(body, {'current': item, 'accumulator': acc});
        }
        return acc;
    }

    final values = [for (final a in args) eval(a, data)];
    dynamic at(int i) => i < values.length ? values[i] : null;

    switch (op) {
      case 'var':
        final path = at(0);
        final fallback = at(1);
        dynamic result;
        if (path == null || path == '') {
          result = data;
        } else {
          final text = path.toString();
          result = text.startsWith('.')
              ? JsonLogic.lookup(local, text.substring(1))
              : JsonLogic.lookup(data, text);
        }
        return result ?? fallback;
      case 'missing':
        final keys = values.length == 1 && values.first is List
            ? values.first as List
            : values;
        return [
          for (final key in keys)
            if (_isMissing(eval({'var': key}, data))) key,
        ];
      case 'missing_some':
        final need = _number(at(0))?.toInt() ?? 0;
        final keys = _list(at(1));
        final missing = [
          for (final key in keys)
            if (_isMissing(eval({'var': key}, data))) key,
        ];
        return keys.length - missing.length >= need ? <dynamic>[] : missing;
      case '==':
        return _looseEquals(at(0), at(1));
      case '!=':
        return !_looseEquals(at(0), at(1));
      case '===':
        return _strictEquals(at(0), at(1));
      case '!==':
        return !_strictEquals(at(0), at(1));
      case '!':
        return !JsonLogic.truthy(at(0));
      case '!!':
        return JsonLogic.truthy(at(0));
      case '<':
      case '<=':
      case '>':
      case '>=':
        bool compare(dynamic a, dynamic b) {
          final x = _number(a), y = _number(b);
          if (x != null && y != null) {
            return switch (op) {
              '<' => x < y,
              '<=' => x <= y,
              '>' => x > y,
              _ => x >= y,
            };
          }
          if (a is String && b is String) {
            final c = a.compareTo(b);
            return switch (op) {
              '<' => c < 0,
              '<=' => c <= 0,
              '>' => c > 0,
              _ => c >= 0,
            };
          }
          return false;
        }
        if (values.length == 3 && (op == '<' || op == '<=')) {
          return compare(at(0), at(1)) && compare(at(1), at(2));
        }
        return compare(at(0), at(1));
      case 'max':
      case 'min':
        final numbers = values.map(_number).toList();
        if (numbers.isEmpty || numbers.contains(null)) return null;
        return _tidy(
          numbers.cast<num>().reduce(op == 'max' ? math.max : math.min),
        );
      case '+':
        num sum = 0;
        for (final v in values) {
          final n = _number(v);
          if (n == null) return null;
          sum += n;
        }
        return _tidy(sum);
      case '*':
        if (values.isEmpty) return null;
        num product = 1;
        for (final v in values) {
          final n = _number(v);
          if (n == null) return null;
          product *= n;
        }
        return _tidy(product);
      case '-':
        final a = _number(at(0));
        if (a == null) return null;
        if (values.length == 1) return _tidy(-a);
        final b = _number(at(1));
        return b == null ? null : _tidy(a - b);
      case '/':
        final a = _number(at(0)), b = _number(at(1));
        if (a == null || b == null || b == 0) return null;
        return _tidy(a / b);
      case '%':
        final a = _number(at(0)), b = _number(at(1));
        if (a == null || b == null || b == 0) return null;
        return _tidy(a.remainder(b));
      case 'round':
        final a = _number(at(0));
        if (a == null) return null;
        final digits = (_number(at(1)) ?? 0).toInt().clamp(0, 12);
        final factor = math.pow(10, digits);
        return _tidy((a * factor).round() / factor);
      case 'count':
        return _list(at(0)).where((v) => v != null).length;
      case 'merge':
        return [
          for (final v in values)
            if (v is List) ...v else v,
        ];
      case 'in':
        final haystack = at(1);
        if (haystack is List) return haystack.contains(at(0));
        if (haystack is String) {
          return haystack.contains(_text(at(0)));
        }
        return false;
      case 'cat':
        return values.map(_text).join();
      case 'substr':
        final text = _text(at(0));
        var start = (_number(at(1)) ?? 0).toInt();
        if (start < 0) start = math.max(0, text.length + start);
        start = math.min(start, text.length);
        final length = _number(at(2))?.toInt();
        if (length == null) return text.substring(start);
        final end = length < 0
            ? math.max(start, text.length + length)
            : math.min(text.length, start + length);
        return text.substring(start, end);
      case 'log':
        return at(0);
    }
    throw JsonLogicException('Unknown operator "$op"');
  }

  static bool _isMissing(dynamic value) => value == null || value == '';

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  /// A number from a number, a numeric string or a boolean; null otherwise.
  static num? _number(dynamic value) {
    if (value is num) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  /// Whole doubles as ints, so `2 * 1.5` stores `3` and floating-point noise
  /// such as `0.1 + 0.2` is rounded away.
  static num _tidy(num value) {
    if (value is int || value.isNaN || value.isInfinite) return value;
    final rounded = double.parse(value.toStringAsPrecision(12));
    if (rounded == rounded.truncateToDouble() && rounded.abs() < 1e15) {
      return rounded.toInt();
    }
    return rounded;
  }

  static String _text(dynamic value) {
    if (value == null) return '';
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static bool _strictEquals(dynamic a, dynamic b) {
    if (a is num && b is num) return a == b;
    return a.runtimeType == b.runtimeType && a == b;
  }

  static bool _looseEquals(dynamic a, dynamic b) {
    if (a == null || b == null) return a == b;
    if (a is num || b is num || a is bool || b is bool) {
      final x = _number(a), y = _number(b);
      if (x != null && y != null) return x == y;
    }
    return a.toString() == b.toString();
  }
}
