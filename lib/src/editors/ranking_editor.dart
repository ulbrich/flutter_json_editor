import 'package:material_ui/material_ui.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'const_choice_editor.dart';
import 'format_support.dart';

/// Puts choices in order of preference, activated by `"x-format": "ranking"`
/// on an `array` whose `items` are an `enum` or a `oneOf`/`anyOf` of
/// `const`s:
///
/// ```json
/// {"type": "array", "title": "Rank the topics", "x-format": "ranking",
///  "uniqueItems": true,
///  "items": {"type": "string", "enum": ["Salary", "Team", "Remote work"]}}
/// ```
///
/// The choices are dragged by their handle, or moved with the arrow
/// buttons; the value is the list of all choice values, most preferred
/// first. Until the first move the field is empty and the choices stand in
/// their schema order. Stored values the choices don't know are dropped;
/// choices missing from the stored order are appended. A schema without
/// such items renders with the editor it would get without the `x-format`.
class RankingEditor extends SchemaFieldEditor {
  const RankingEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// [choices] in the order of [stored]; choices it lacks come last.
  static List<ConstChoice> order(List<ConstChoice> choices, dynamic stored) {
    final values = stored is List ? stored : const [];
    final result = <ConstChoice>[];
    for (final v in values) {
      final index = choices.indexWhere((c) => c.value == v);
      if (index >= 0 && !result.contains(choices[index])) {
        result.add(choices[index]);
      }
    }
    for (final c in choices) {
      if (!result.contains(c)) result.add(c);
    }
    return result;
  }

  @override
  State<RankingEditor> createState() => _RankingEditorState();
}

class _RankingEditorState extends State<RankingEditor> {
  void _move(List<ConstChoice> ordered, int from, int to) {
    if (to < 0 || to >= ordered.length || from == to) return;
    final next = [...ordered];
    final item = next.removeAt(from);
    next.insert(to, item);
    widget.onChanged([for (final c in next) c.value]);
  }

  @override
  Widget build(BuildContext context) {
    final isArray = schemaTypeNames(widget.schema).contains('array');
    final choices = isArray ? choicesOf(widget.schema.items) : null;
    if (choices == null || choices.length < 2) {
      return editorWithoutFormat(
        context,
        format: 'ranking',
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
    final ranked = widget.value is List && (widget.value as List).isNotEmpty;
    final ordered = RankingEditor.order(choices, widget.value);

    Widget tile(int index) {
      final choice = ordered[index];
      return Padding(
        key: ValueKey('ranking-${choice.value}'),
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 13,
                backgroundColor: ranked
                    ? scheme.primary
                    : scheme.outlineVariant,
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ranked ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(choice.title, style: theme.textTheme.bodyLarge),
                ),
              ),
              if (!readOnly) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: l10n.moveUpTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: index == 0
                      ? null
                      : () => _move(ordered, index, index - 1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: l10n.moveDownTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: index == ordered.length - 1
                      ? null
                      : () => _move(ordered, index, index + 1),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      );
    }

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description:
          widget.schema.description ??
          (readOnly || ranked ? null : l10n.rankingHint),
      editorTheme: editorTheme,
      onClear: ranked && !readOnly && (!widget.isRequired || widget.isNullable)
          ? () => widget.onChanged(null)
          : null,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: ordered.length,
        itemBuilder: (context, index) => tile(index),
        onReorderItem: (from, to) => _move(ordered, from, to),
      ),
    );
  }
}
