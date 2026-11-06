import 'package:material_ui/material_ui.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// A slider for a number, activated by `"x-format": "slider"` on an
/// `integer` or `number` schema:
///
/// ```json
/// {"type": "integer", "title": "Volume", "x-format": "slider",
///  "minimum": 0, "maximum": 10}
/// ```
///
/// The range is `minimum`/`exclusiveMinimum` to `maximum`/`exclusiveMaximum`
/// (default 0–100). Integers move in steps of `multipleOf` (default 1);
/// numbers move in steps of `multipleOf` when given, else freely (rounded to
/// two decimals). While the field is empty the thumb rests on the start of
/// the range and the value reads "—"; the first move sets it. A schema that
/// isn't numeric renders with the editor it would get without the
/// `x-format`.
class SliderEditor extends SchemaFieldEditor {
  const SliderEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<SliderEditor> createState() => _SliderEditorState();
}

class _SliderEditorState extends State<SliderEditor> {
  num get _min => widget.schema.minimum ?? widget.schema.exclusiveMinimum ?? 0;

  num get _max {
    final max = widget.schema.maximum ?? widget.schema.exclusiveMaximum;
    if (max != null && max > _min) return max;
    return _min + 100;
  }

  num? get _step {
    final multipleOf = widget.schema.multipleOf;
    if (multipleOf != null && multipleOf > 0) return multipleOf;
    return isIntegerSchema(widget.schema) ? 1 : null;
  }

  int? get _divisions {
    final step = _step;
    if (step == null) return null;
    final divisions = ((_max - _min) / step).floor();
    return divisions > 0 ? divisions : null;
  }

  num? get _current {
    final value = widget.value;
    if (value is num) return value.clamp(_min, _max);
    if (value is String) return num.tryParse(value)?.clamp(_min, _max);
    return null;
  }

  num _normalize(double raw) {
    final step = _step;
    final snapped = step == null
        ? raw
        : _min + ((raw - _min) / step).round() * step;
    final clamped = snapped.clamp(_min, _max);
    if (isIntegerSchema(widget.schema)) return clamped.round();
    // Avoid binary noise like 0.30000000000000004 from step arithmetic.
    return double.parse(clamped.toStringAsFixed(step == null ? 2 : 6));
  }

  String _format(num? value) {
    if (value == null) return '—';
    if (value is int || value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!isNumericSchema(widget.schema)) {
      return editorWithoutFormat(
        context,
        format: 'slider',
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
    final readOnly = widget.schema.readOnly == true;
    final current = _current;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      onClear: widget.isNullable && !readOnly && widget.value != null
          ? () => widget.onChanged(null)
          : null,
      child: Row(
        children: [
          Text(_format(_min), style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Slider(
              value: (current ?? _min).toDouble(),
              min: _min.toDouble(),
              max: _max.toDouble(),
              divisions: _divisions,
              label: _format(current),
              onChanged: readOnly
                  ? null
                  : (raw) {
                      final next = _normalize(raw);
                      if (next != widget.value) widget.onChanged(next);
                    },
            ),
          ),
          Text(_format(_max), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              _format(current),
              key: const ValueKey('slider-value'),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
