import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// Hours and minutes of a duration, activated by `"x-format": "duration"`
/// or the standard `"format": "duration"`:
///
/// ```json
/// {"type": "string", "title": "Effort", "format": "duration"}
/// {"type": "integer", "title": "Break", "x-format": "duration"}
/// ```
///
/// A `string` stores an ISO 8601 duration (`PT1H30M`); an `integer` or
/// `number` stores seconds (`5400`). Reading accepts weeks, days, hours,
/// minutes and seconds (`P1DT2H` shows as 26 hours); years and months are
/// ambiguous and read as empty. Minutes above 59 carry over into the hours
/// when stored. Seconds of an existing value are kept, but not edited.
/// Clearing both fields clears the value.
class DurationEditor extends SchemaFieldEditor {
  const DurationEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// Parses an ISO 8601 duration (`P[nW][nD][T[nH][nM][nS]]`) to seconds;
  /// null for anything else, including years and months.
  static int? parseIso8601(String text) {
    final match = _iso.firstMatch(text.trim().toUpperCase());
    if (match == null || text.trim().length <= 1) return null;
    if (text.toUpperCase().endsWith('T')) return null;
    int part(int group) => int.tryParse(match.group(group) ?? '') ?? 0;
    final seconds = double.tryParse(match.group(5) ?? '') ?? 0;
    return part(1) * 604800 +
        part(2) * 86400 +
        part(3) * 3600 +
        part(4) * 60 +
        seconds.round();
  }

  /// Formats [seconds] as an ISO 8601 duration in hours, minutes and
  /// seconds (`PT1H30M`); zero is `PT0M`.
  static String formatIso8601(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    final buffer = StringBuffer('PT');
    if (hours > 0) buffer.write('${hours}H');
    if (minutes > 0 || (hours == 0 && rest == 0)) buffer.write('${minutes}M');
    if (rest > 0) buffer.write('${rest}S');
    return buffer.toString();
  }

  static final RegExp _iso = RegExp(
    r'^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)?$',
  );

  @override
  State<DurationEditor> createState() => _DurationEditorState();
}

class _DurationEditorState extends State<DurationEditor> {
  late final TextEditingController _hours;
  late final TextEditingController _minutes;

  /// The value this editor emitted last, so its own echo doesn't rewrite the
  /// fields while typing.
  dynamic _emitted;

  bool get _storesSeconds => isNumericSchema(widget.schema);

  int? _secondsOf(dynamic value) {
    if (value is num) return value.round();
    if (value is String) return DurationEditor.parseIso8601(value);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _hours = TextEditingController();
    _minutes = TextEditingController();
    _fill(widget.value);
  }

  @override
  void didUpdateWidget(DurationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _emitted && widget.value != oldWidget.value) {
      _fill(widget.value);
    }
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _fill(dynamic value) {
    final seconds = _secondsOf(value);
    if (seconds == null) {
      _hours.text = '';
      _minutes.text = '';
      return;
    }
    _hours.text = '${seconds ~/ 3600}';
    _minutes.text = '${(seconds % 3600) ~/ 60}';
  }

  void _changed(String _) {
    if (_hours.text.isEmpty && _minutes.text.isEmpty) {
      _emit(null);
      return;
    }
    final keptSeconds = (_secondsOf(widget.value) ?? 0) % 60;
    final total =
        (int.tryParse(_hours.text) ?? 0) * 3600 +
        (int.tryParse(_minutes.text) ?? 0) * 60 +
        keptSeconds;
    _emit(_storesSeconds ? total : DurationEditor.formatIso8601(total));
  }

  void _emit(dynamic value) {
    _emitted = value;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final readOnly = widget.schema.readOnly == true;
    final invalid = widget.value is String && _secondsOf(widget.value) == null;

    Widget field(TextEditingController controller, String label) => SizedBox(
      width: 96,
      child: TextField(
        controller: controller,
        enabled: !readOnly,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: _changed,
      ),
    );

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      errorText: invalid ? l10n.invalidDurationFormat : null,
      editorTheme: editorTheme,
      onClear: widget.isNullable && !readOnly && widget.value != null
          ? () {
              _hours.clear();
              _minutes.clear();
              _emit(null);
            }
          : null,
      child: Row(
        children: [
          field(_hours, l10n.hoursLabel),
          const SizedBox(width: 12),
          field(_minutes, l10n.minutesLabel),
        ],
      ),
    );
  }
}
