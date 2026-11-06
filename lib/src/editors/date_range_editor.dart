import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// A period from one day to another, picked in one calendar, activated by
/// `"x-format": "date-range"`:
///
/// ```json
/// {"type": "object", "title": "Vacation", "x-format": "date-range",
///  "properties": {"start": {"type": "string", "format": "date"},
///                 "end": {"type": "string", "format": "date"}}}
///
/// {"type": "string", "title": "Vacation", "x-format": "date-range",
///  "x-min-date": "2026-01-01", "x-max-date": "2027-12-31"}
/// ```
///
/// An `object` stores `{"start": "2026-11-06", "end": "2026-11-10"}`; its
/// first two declared properties, when it has them, name the keys. A
/// `string` stores an ISO 8601 interval, `2026-11-06/2026-11-10`. The
/// calendar spans `x-min-date` to `x-max-date` (default 1900–2100). Other
/// schemas render with the editor they would get without the `x-format`.
class DateRangeEditor extends SchemaFieldEditor {
  const DateRangeEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// `yyyy-MM-dd` of [date].
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// The day of an ISO date (or date-time) string; null for anything else.
  static DateTime? parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  State<DateRangeEditor> createState() => _DateRangeEditorState();
}

class _DateRangeEditorState extends State<DateRangeEditor> {
  bool get _isObject => schemaTypeNames(widget.schema).contains('object');

  (String, String) get _keys {
    final keys = widget.schema.properties.keys.toList();
    return keys.length >= 2 ? (keys[0], keys[1]) : ('start', 'end');
  }

  DateTimeRange? get _range {
    DateTime? start, end;
    final value = widget.value;
    if (value is Map) {
      final (s, e) = _keys;
      start = DateRangeEditor.parseDate(value[s]);
      end = DateRangeEditor.parseDate(value[e]);
    } else if (value is String && value.contains('/')) {
      final parts = value.split('/');
      start = DateRangeEditor.parseDate(parts.first);
      end = DateRangeEditor.parseDate(parts.last);
    }
    if (start == null || end == null || end.isBefore(start)) return null;
    return DateTimeRange(start: start, end: end);
  }

  DateTime _limit(String key, DateTime fallback) =>
      DateRangeEditor.parseDate(widget.schema.schemaMap?[key]) ?? fallback;

  void _emit(DateTimeRange? range) {
    if (range == null) {
      widget.onChanged(null);
      return;
    }
    final start = DateRangeEditor.formatDate(range.start);
    final end = DateRangeEditor.formatDate(range.end);
    if (_isObject) {
      final (s, e) = _keys;
      widget.onChanged({
        if (widget.value is Map)
          ...Map<String, dynamic>.from(widget.value as Map),
        s: start,
        e: end,
      });
    } else {
      widget.onChanged('$start/$end');
    }
  }

  Future<void> _pick() async {
    final first = _limit('x-min-date', DateTime(1900));
    final last = _limit('x-max-date', DateTime(2100));
    final current = _range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange:
          current != null &&
              !current.start.isBefore(first) &&
              !current.end.isAfter(last)
          ? current
          : null,
    );
    if (picked != null && mounted) {
      _emit(
        DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = schemaTypeNames(widget.schema);
    if (!types.contains('object') && !types.contains('string')) {
      return editorWithoutFormat(
        context,
        format: 'date-range',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final theme = Theme.of(context);
    final readOnly = widget.schema.readOnly == true;
    final range = _range;
    final locale = Localizations.localeOf(context).toString();
    final format = intl.DateFormat.yMMMd(locale);
    final days = range == null
        ? 0
        : range.end.difference(range.start).inDays + 1;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      onClear:
          range != null &&
              !readOnly &&
              (!widget.isRequired || widget.isNullable)
          ? () => _emit(null)
          : null,
      child: InkWell(
        onTap: readOnly ? null : _pick,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.dateRangeLabel,
            suffixIcon: const Icon(Icons.date_range, size: 20),
            helperText: range == null ? null : l10n.dayCount(days),
            enabled: !readOnly,
          ),
          child: Text(
            range == null
                ? ''
                : '${format.format(range.start)} – ${format.format(range.end)}',
            key: const ValueKey('date-range-text'),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
