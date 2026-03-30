import 'package:flutter/material.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

/// An editor for date-only values (`x-format: "date"`).
///
/// Accepts and emits either:
/// - A **number** (seconds since Unix epoch UTC, schema type `integer`/`number`)
/// - A **string** in ISO 8601 date format (`yyyy-MM-dd`, schema type `string`)
///
/// The value is always stored as UTC but displayed in the local timezone.
class DateEditor extends SchemaFieldEditor {
  /// When `false`, the label and description are suppressed (used when
  /// embedded inside [DateTimeEditor]).
  final bool showHeader;

  const DateEditor({
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
  State<DateEditor> createState() => DateEditorState();
}

class DateEditorState extends State<DateEditor> {
  /// The currently selected date in local timezone (for display / picker).
  DateTime? _localDate;

  /// Whether the incoming value was numeric (seconds since epoch).
  bool _isNumericType = false;

  @override
  void initState() {
    super.initState();
    _isNumericType = _detectNumericType();
    _localDate = _parseValue(widget.value);
  }

  @override
  void didUpdateWidget(DateEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _isNumericType = _detectNumericType();
      _localDate = _parseValue(widget.value);
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

  DateTime? _parseValue(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      // Seconds since epoch UTC → local DateTime.
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt() * 1000,
        isUtc: true,
      ).toLocal();
    }

    if (value is String && value.isNotEmpty) {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        // If the parsed DateTime is UTC (e.g. "2024-03-15"), convert to local.
        return dt.isUtc ? dt.toLocal() : dt;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Emission
  // ---------------------------------------------------------------------------

  void _emitValue(DateTime? local) {
    if (local == null) {
      widget.onChanged(null);
      return;
    }

    // Build a UTC date-only DateTime from the local date.
    final utcDt = DateTime.utc(local.year, local.month, local.day);

    if (_isNumericType) {
      widget.onChanged(utcDt.millisecondsSinceEpoch ~/ 1000);
    } else {
      final y = utcDt.year.toString().padLeft(4, '0');
      final m = utcDt.month.toString().padLeft(2, '0');
      final d = utcDt.day.toString().padLeft(2, '0');
      widget.onChanged('$y-$m-$d');
    }
  }

  // ---------------------------------------------------------------------------
  // Picker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _localDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _localDate = picked);
      _emitValue(picked);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  String _formatDisplay() {
    if (_localDate == null) return '';
    final d = _localDate!;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Builds only the date picker portion (no label/description). Used by
  /// [DateTimeEditor] to compose date + time.
  Widget buildDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 20),
              if (widget.isNullable && _localDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear',
                  onPressed: () {
                    setState(() => _localDate = null);
                    _emitValue(null);
                  },
                ),
            ],
          ),
        ),
        child: Text(
          _formatDisplay(),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showHeader) return buildDatePicker(context);

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
          buildDatePicker(context),
        ],
      ),
    );
  }
}
