import 'package:flutter/material.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'date_editor.dart';
import 'time_editor.dart';

/// An editor for combined date-time values (`x-format: "date-time"`).
///
/// Composes a [DateEditor] and a [TimeEditor] side by side. Accepts and emits
/// either:
/// - A **number** (seconds since Unix epoch UTC, schema type `integer`/`number`)
/// - A **string** in ISO 8601 format (`yyyy-MM-ddTHH:mm:ssZ`, schema type `string`)
///
/// The value is always stored as UTC but displayed in the local timezone.
class DateTimeEditor extends SchemaFieldEditor {
  const DateTimeEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<DateTimeEditor> createState() => _DateTimeEditorState();
}

class _DateTimeEditorState extends State<DateTimeEditor> {
  final _dateKey = GlobalKey<DateEditorState>();
  final _timeKey = GlobalKey<TimeEditorState>();

  /// Whether the incoming value was numeric (seconds since epoch).
  bool _isNumericType = false;

  /// The current local date (kept in sync from sub-editors).
  DateTime? _localDate;

  /// The current local time (kept in sync from sub-editors).
  TimeOfDay? _localTime;

  @override
  void initState() {
    super.initState();
    _isNumericType = _detectNumericType();
    _parseValue(widget.value);
  }

  @override
  void didUpdateWidget(DateTimeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _isNumericType = _detectNumericType();
      _parseValue(widget.value);
    }
  }

  // ---------------------------------------------------------------------------
  // Type detection
  // ---------------------------------------------------------------------------

  bool _detectNumericType() {
    if (widget.value is num) return true;
    final type = widget.schema.type;
    if (type != null) {
      final t = type.toString();
      return t == 'integer' || t == 'number';
    }
    final typeList = widget.schema.typeList;
    if (typeList != null) {
      return typeList.any(
        (t) => t.toString() == 'integer' || t.toString() == 'number',
      );
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  void _parseValue(dynamic value) {
    if (value == null) {
      _localDate = null;
      _localTime = null;
      return;
    }

    DateTime? utc;
    if (value is num) {
      utc = DateTime.fromMillisecondsSinceEpoch(
        value.toInt() * 1000,
        isUtc: true,
      );
    } else if (value is String && value.isNotEmpty) {
      utc = DateTime.tryParse(value);
    }

    if (utc != null) {
      final local = utc.isUtc ? utc.toLocal() : utc;
      _localDate = DateTime(local.year, local.month, local.day);
      _localTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
  }

  // ---------------------------------------------------------------------------
  // Emission
  // ---------------------------------------------------------------------------

  void _emitCombined() {
    if (_localDate == null && _localTime == null) {
      widget.onChanged(null);
      return;
    }

    final date = _localDate ?? DateTime.now();
    final time = _localTime ?? const TimeOfDay(hour: 0, minute: 0);

    final localDt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final utcDt = localDt.toUtc();

    if (_isNumericType) {
      widget.onChanged(utcDt.millisecondsSinceEpoch ~/ 1000);
    } else {
      widget.onChanged(utcDt.toIso8601String());
    }
  }

  // ---------------------------------------------------------------------------
  // Sub-editor callbacks
  // ---------------------------------------------------------------------------

  void _onDateChanged(dynamic dateValue) {
    // The DateEditor emits in its own format — we re-parse to extract the
    // local date and combine with the current time.
    if (dateValue == null) {
      setState(() => _localDate = null);
    } else if (dateValue is num) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        dateValue.toInt() * 1000,
        isUtc: true,
      ).toLocal();
      setState(() => _localDate = DateTime(dt.year, dt.month, dt.day));
    } else if (dateValue is String) {
      final dt = DateTime.tryParse(dateValue);
      if (dt != null) {
        final local = dt.isUtc ? dt.toLocal() : dt;
        setState(
            () => _localDate = DateTime(local.year, local.month, local.day));
      }
    }
    _emitCombined();
  }

  void _onTimeChanged(dynamic timeValue) {
    // The TimeEditor emits in its own format — we re-parse to extract the
    // local time and combine with the current date.
    // Use the selected date for DST-consistent UTC↔local conversion.
    final ref = _localDate ?? DateTime.now();

    if (timeValue == null) {
      setState(() => _localTime = null);
    } else if (timeValue is num) {
      final utcDt = DateTime.utc(ref.year, ref.month, ref.day).add(
        Duration(seconds: timeValue.toInt()),
      );
      final local = utcDt.toLocal();
      setState(
          () => _localTime = TimeOfDay(hour: local.hour, minute: local.minute));
    } else if (timeValue is String) {
      final parts = timeValue.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          final utcDt = DateTime.utc(ref.year, ref.month, ref.day, h, m);
          final local = utcDt.toLocal();
          setState(
            () =>
                _localTime = TimeOfDay(hour: local.hour, minute: local.minute),
          );
        }
      }
    }
    _emitCombined();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  /// Produce the value that the DateEditor sub-widget should receive.
  dynamic get _dateSubValue {
    if (widget.value == null) return null;
    if (_localDate == null) return null;
    final utc =
        DateTime.utc(_localDate!.year, _localDate!.month, _localDate!.day);
    if (_isNumericType) return utc.millisecondsSinceEpoch ~/ 1000;
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Produce the value that the TimeEditor sub-widget should receive.
  dynamic get _timeSubValue {
    if (widget.value == null) return null;
    if (_localTime == null) return null;
    // Convert local time to UTC for the sub-editor.
    // Use the selected date for DST-consistent conversion.
    final ref = _localDate ?? DateTime.now();
    final localDt = DateTime(
      ref.year,
      ref.month,
      ref.day,
      _localTime!.hour,
      _localTime!.minute,
    );
    final utcDt = localDt.toUtc();
    if (_isNumericType) return utcDt.hour * 3600 + utcDt.minute * 60;
    final hh = utcDt.hour.toString().padLeft(2, '0');
    final mm = utcDt.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Expanded(
                child: Text(
                  _buildLabel(),
                  style: editorTheme.labelStyle ??
                      Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (widget.isNullable && widget.value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear to null',
                  onPressed: () => widget.onChanged(null),
                ),
            ],
          ),
          if (widget.schema.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.schema.description!,
                style: editorTheme.helperStyle ??
                    Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),

          // Date + Time side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: DateEditor(
                  key: _dateKey,
                  schema: widget.schema,
                  path: widget.path,
                  value: _dateSubValue,
                  onChanged: _onDateChanged,
                  isRequired: widget.isRequired,
                  isNullable: widget.isNullable,
                  showHeader: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TimeEditor(
                  key: _timeKey,
                  schema: widget.schema,
                  path: widget.path,
                  value: _timeSubValue,
                  onChanged: _onTimeChanged,
                  isRequired: widget.isRequired,
                  isNullable: widget.isNullable,
                  showHeader: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
