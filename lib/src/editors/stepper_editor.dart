import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// A counter with − and + buttons, activated by `"x-format": "stepper"` on
/// an `integer` or `number` schema:
///
/// ```json
/// {"type": "integer", "title": "Guests", "x-format": "stepper",
///  "minimum": 1, "maximum": 12}
/// ```
///
/// Each press moves by `multipleOf` (default 1) and stays within
/// `minimum`/`maximum` (or their exclusive variants, moved one step inward).
/// While the field is empty it reads "—"; the first press starts from the
/// `default`, else the `minimum`, else 0. A schema that isn't numeric renders
/// with the editor it would get without the `x-format`.
class StepperEditor extends SchemaFieldEditor {
  const StepperEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<StepperEditor> createState() => _StepperEditorState();
}

class _StepperEditorState extends State<StepperEditor> {
  num get _step {
    final multipleOf = widget.schema.multipleOf;
    return multipleOf != null && multipleOf > 0 ? multipleOf : 1;
  }

  num? get _min {
    final schema = widget.schema;
    if (schema.minimum != null) return schema.minimum;
    final exclusive = schema.exclusiveMinimum;
    return exclusive == null ? null : exclusive + _step;
  }

  num? get _max {
    final schema = widget.schema;
    if (schema.maximum != null) return schema.maximum;
    final exclusive = schema.exclusiveMaximum;
    return exclusive == null ? null : exclusive - _step;
  }

  num? get _current {
    final value = widget.value;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  num get _start {
    final fallback = widget.schema.defaultValue;
    if (fallback is num) return fallback;
    return _min ?? 0;
  }

  num _tidy(num value) {
    if (isIntegerSchema(widget.schema)) return value.round();
    return double.parse(value.toStringAsFixed(6));
  }

  bool _canMove(int direction) {
    final current = _current;
    if (current == null) return true;
    if (direction < 0) return _min == null || current - _step >= _min!;
    return _max == null || current + _step <= _max!;
  }

  void _move(int direction) {
    final current = _current;
    final next = current == null ? _start : current + direction * _step;
    var bounded = next;
    if (_min != null && bounded < _min!) bounded = _min!;
    if (_max != null && bounded > _max!) bounded = _max!;
    widget.onChanged(_tidy(bounded));
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
        format: 'stepper',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final editorTheme = Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final readOnly = widget.schema.readOnly == true;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      onClear: widget.isNullable && !readOnly && widget.value != null
          ? () => widget.onChanged(null)
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            icon: const Icon(Icons.remove),
            tooltip: l10n.decreaseTooltip,
            onPressed: !readOnly && _canMove(-1) ? () => _move(-1) : null,
          ),
          SizedBox(
            width: 72,
            child: Text(
              _format(_current),
              key: const ValueKey('stepper-value'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            icon: const Icon(Icons.add),
            tooltip: l10n.increaseTooltip,
            onPressed: !readOnly && _canMove(1) ? () => _move(1) : null,
          ),
        ],
      ),
    );
  }
}
