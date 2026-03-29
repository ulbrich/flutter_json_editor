import 'package:flutter/widgets.dart';

class RefLookupProvider extends InheritedWidget {
  final Future<Map<String, dynamic>?> Function(
    String refUrl,
    String fieldPath,
    dynamic currentValue,
  )? onRefLookup;
  final int minTypeAhead;
  final Map<String, Map<String, dynamic>> _cache = {};

  RefLookupProvider({
    super.key,
    required this.onRefLookup,
    required this.minTypeAhead,
    required super.child,
  });

  /// Cached lookup — keyed by [refUrl] only, since the same URL always returns
  /// the same enum list regardless of which field uses it.
  Future<Map<String, dynamic>?> lookup(
    String refUrl,
    String fieldPath,
    dynamic currentValue,
  ) async {
    if (_cache.containsKey(refUrl)) return _cache[refUrl];
    final result = await onRefLookup?.call(refUrl, fieldPath, currentValue);
    if (result != null) _cache[refUrl] = result;
    return result;
  }

  static RefLookupProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RefLookupProvider>();

  @override
  bool updateShouldNotify(RefLookupProvider oldWidget) =>
      onRefLookup != oldWidget.onRefLookup ||
      minTypeAhead != oldWidget.minTypeAhead;
}
