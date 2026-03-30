import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

/// An editor for time-only values (`x-format: "time"`).
///
/// Accepts and emits either:
/// - A **number** (seconds since midnight UTC, schema type `integer`/`number`)
/// - A **string** in ISO 8601 time format (`HH:mm:ss`, schema type `string`)
///
/// The value is always stored as UTC but displayed in the local timezone.
class TimeEditor extends SchemaFieldEditor {
  /// When `false`, the label and description are suppressed (used when
  /// embedded inside [DateTimeEditor]).
  final bool showHeader;

  const TimeEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
    this.showHeader = true,
  });

  @override
  State<TimeEditor> createState() => TimeEditorState();
}

class TimeEditorState extends State<TimeEditor> {
  /// The currently selected time in local timezone (for display / picker).
  TimeOfDay? _localTime;

  /// Whether the incoming value was numeric (seconds since midnight).
  bool _isNumericType = false;

  @override
  void initState() {
    super.initState();
    _isNumericType = _detectNumericType();
    _localTime = _parseValue(widget.value);
  }

  @override
  void didUpdateWidget(TimeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _isNumericType = _detectNumericType();
      _localTime = _parseValue(widget.value);
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

  TimeOfDay? _parseValue(dynamic value) {
    if (value == null) return null;

    // Use today's date for UTC↔local conversion so that the DST offset
    // is consistent with _emitValue (which also uses today).
    final now = DateTime.now();

    if (value is num) {
      // Seconds since midnight UTC → local TimeOfDay.
      final utcDt = DateTime.utc(now.year, now.month, now.day).add(
        Duration(seconds: value.toInt()),
      );
      final local = utcDt.toLocal();
      return TimeOfDay(hour: local.hour, minute: local.minute);
    }

    if (value is String && value.isNotEmpty) {
      // ISO 8601 time: "HH:mm:ss" or "HH:mm" (UTC).
      final parts = value.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          final utcDt =
              DateTime.utc(now.year, now.month, now.day, hour, minute);
          final local = utcDt.toLocal();
          return TimeOfDay(hour: local.hour, minute: local.minute);
        }
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Emission
  // ---------------------------------------------------------------------------

  void _emitValue(TimeOfDay? local) {
    if (local == null) {
      widget.onChanged(null);
      return;
    }

    // Convert local time back to UTC.
    final now = DateTime.now();
    final localDt =
        DateTime(now.year, now.month, now.day, local.hour, local.minute);
    final utcDt = localDt.toUtc();

    if (_isNumericType) {
      widget.onChanged(utcDt.hour * 3600 + utcDt.minute * 60);
    } else {
      final hh = utcDt.hour.toString().padLeft(2, '0');
      final mm = utcDt.minute.toString().padLeft(2, '0');
      const ss = '00';
      widget.onChanged('$hh:$mm:$ss');
    }
  }

  // ---------------------------------------------------------------------------
  // Interaction
  // ---------------------------------------------------------------------------

  void _onHourChanged(int? hour) {
    if (hour == null) return;
    final minute = _localTime?.minute ?? 0;
    final updated = TimeOfDay(hour: hour, minute: minute);
    setState(() => _localTime = updated);
    _emitValue(updated);
  }

  void _onMinuteChanged(int? minute) {
    if (minute == null) return;
    final hour = _localTime?.hour ?? 0;
    final updated = TimeOfDay(hour: hour, minute: minute);
    setState(() => _localTime = updated);
    _emitValue(updated);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  /// The local timezone abbreviation, e.g. "UTC+2" or "UTC-5".
  String get _timezoneLabel {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.abs() % 60;
    final sign = hours >= 0 ? '+' : '';
    if (minutes == 0) return 'UTC$sign$hours';
    return 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

  /// Builds only the time picker portion (no label/description). Used by
  /// [DateTimeEditor] to compose date + time.
  Widget buildTimePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Hour dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _localTime
                    ?.hour, // ignore deprecated_member_use: initialValue doesn't sync on rebuild
                decoration: InputDecoration(
                  labelText: widget.showHeader
                      ? JsonEditorL10n.of(context).hourLabel
                      : JsonEditorL10n.of(context).timeLabel,
                ),
                items: [
                  for (var h = 0; h < 24; h++)
                    DropdownMenuItem(
                      value: h,
                      child: Text(h.toString().padLeft(2, '0')),
                    ),
                ],
                onChanged: _onHourChanged,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(':', style: TextStyle(fontSize: 20)),
            ),
            // Minute dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _localTime
                    ?.minute, // ignore deprecated_member_use: initialValue doesn't sync on rebuild
                decoration: InputDecoration(
                  labelText: widget.showHeader
                      ? JsonEditorL10n.of(context).minuteLabel
                      : _timezoneLabel,
                ),
                items: [
                  for (var m = 0; m < 60; m++)
                    DropdownMenuItem(
                      value: m,
                      child: Text(m.toString().padLeft(2, '0')),
                    ),
                ],
                onChanged: _onMinuteChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showHeader) return buildTimePicker(context);

    final editorTheme = Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _buildLabel(),
            style: editorTheme.labelStyle ??
                Theme.of(context).textTheme.bodyMedium,
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
          buildTimePicker(context),
        ],
      ),
    );
  }
}
