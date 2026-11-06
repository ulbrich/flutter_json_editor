import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// The look of a [ScaleEditor].
enum ScaleVariant {
  /// Numbered buttons, `"x-format": "linear-scale"`.
  linear,

  /// Numbered buttons from 0 to 10 with the usual question's end labels,
  /// `"x-format": "nps"`.
  nps,

  /// Faces from unhappy to happy, `"x-format": "emoji-scale"`.
  emoji,
}

/// A row of buttons for a whole number on a short scale, as forms use for
/// opinion and satisfaction questions. Three formats on an `integer` schema:
///
/// ```json
/// {"type": "integer", "title": "How easy was it?", "x-format": "linear-scale",
///  "minimum": 1, "maximum": 5,
///  "x-min-label": "Very hard", "x-max-label": "Very easy"}
///
/// {"type": "integer", "title": "Would you recommend us?", "x-format": "nps"}
///
/// {"type": "integer", "title": "How do you feel?", "x-format": "emoji-scale",
///  "x-labels": ["Awful", "Bad", "Okay", "Good", "Great"]}
/// ```
///
/// - `linear-scale`: `minimum` to `maximum` (default 1–5, at most 11 steps),
///   with optional end labels `x-min-label` and `x-max-label`.
/// - `nps`: the Net Promoter Score question, 0–10, with localized end labels
///   unless the schema gives its own.
/// - `emoji-scale`: two to five faces (default 1–5), unhappy to happy.
///
/// `x-labels` names each step (shown as tooltip and below the scale for the
/// chosen one). Tapping the chosen step again clears it unless the field is
/// required. A schema that isn't an `integer`, or a range the format can't
/// show, renders with the editor it would get without the `x-format`.
class ScaleEditor extends SchemaFieldEditor {
  const ScaleEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
    this.variant = ScaleVariant.linear,
  });

  final ScaleVariant variant;

  /// The faces for a scale of two to five steps.
  static List<IconData> facesFor(int count) => switch (count) {
    2 => const [
      Icons.sentiment_dissatisfied_outlined,
      Icons.sentiment_satisfied_outlined,
    ],
    3 => const [
      Icons.sentiment_dissatisfied_outlined,
      Icons.sentiment_neutral_outlined,
      Icons.sentiment_satisfied_outlined,
    ],
    4 => const [
      Icons.sentiment_very_dissatisfied_outlined,
      Icons.sentiment_dissatisfied_outlined,
      Icons.sentiment_satisfied_outlined,
      Icons.sentiment_very_satisfied_outlined,
    ],
    5 => const [
      Icons.sentiment_very_dissatisfied_outlined,
      Icons.sentiment_dissatisfied_outlined,
      Icons.sentiment_neutral_outlined,
      Icons.sentiment_satisfied_outlined,
      Icons.sentiment_very_satisfied_outlined,
    ],
    _ => const [],
  };

  @override
  State<ScaleEditor> createState() => _ScaleEditorState();
}

class _ScaleEditorState extends State<ScaleEditor> {
  String get _format => switch (widget.variant) {
    ScaleVariant.linear => 'linear-scale',
    ScaleVariant.nps => 'nps',
    ScaleVariant.emoji => 'emoji-scale',
  };

  (int, int) get _range {
    final schema = widget.schema;
    final defaultMin = widget.variant == ScaleVariant.nps ? 0 : 1;
    final defaultMax = widget.variant == ScaleVariant.nps ? 10 : 5;
    final min =
        (schema.minimum ?? schema.exclusiveMinimum)?.ceil() ?? defaultMin;
    final max =
        (schema.maximum ?? schema.exclusiveMaximum)?.floor() ??
        (min + defaultMax - defaultMin);
    return (min, max);
  }

  String? _text(String key) {
    final value = widget.schema.schemaMap?[key];
    return value is String ? value : null;
  }

  List<String?> _labels(int count) {
    final raw = widget.schema.schemaMap?['x-labels'];
    return [
      for (var i = 0; i < count; i++)
        raw is List && i < raw.length && raw[i] != null ? '${raw[i]}' : null,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final (min, max) = _range;
    final count = max - min + 1;
    final emoji = widget.variant == ScaleVariant.emoji;
    final fits = emoji ? count >= 2 && count <= 5 : count >= 2 && count <= 11;
    if (!isIntegerSchema(widget.schema) || !fits) {
      return editorWithoutFormat(
        context,
        format: _format,
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
    final scheme = theme.colorScheme;
    final readOnly = widget.schema.readOnly == true;
    final value = widget.value is num ? (widget.value as num).round() : null;
    final labels = _labels(count);
    final faces = emoji ? ScaleEditor.facesFor(count) : const <IconData>[];
    final canClear = !widget.isRequired || widget.isNullable;

    final minLabel =
        _text('x-min-label') ??
        (widget.variant == ScaleVariant.nps ? l10n.npsLowLabel : null);
    final maxLabel =
        _text('x-max-label') ??
        (widget.variant == ScaleVariant.nps ? l10n.npsHighLabel : null);
    final chosenLabel = value != null && value >= min && value <= max
        ? labels[value - min]
        : null;

    void tap(int step) {
      if (step == value) {
        if (canClear) widget.onChanged(null);
      } else {
        widget.onChanged(step);
      }
    }

    Widget button(int index) {
      final step = min + index;
      final selected = step == value;
      final Widget content = emoji
          ? Icon(
              faces[index],
              size: 32,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            )
          : Text(
              '$step',
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            );
      Widget tile = Material(
        color: selected && !emoji
            ? scheme.primary
            : selected
            ? scheme.primaryContainer
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('scale-$step'),
          onTap: readOnly ? null : () => tap(step),
          child: SizedBox(
            height: emoji ? 52 : 40,
            child: Center(child: content),
          ),
        ),
      );
      final label = labels[index];
      if (label != null) tile = Tooltip(message: label, child: tile);
      return Semantics(
        selected: selected,
        button: true,
        label: label ?? '$step',
        child: tile,
      );
    }

    final captionStyle = editorTheme.helperStyle ?? theme.textTheme.bodySmall;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) SizedBox(width: count > 7 ? 4 : 8),
                Expanded(child: button(i)),
              ],
            ],
          ),
          if (minLabel != null || maxLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(child: Text(minLabel ?? '', style: captionStyle)),
                  Expanded(
                    child: Text(
                      maxLabel ?? '',
                      style: captionStyle,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          if (chosenLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                chosenLabel,
                key: const ValueKey('scale-label'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
