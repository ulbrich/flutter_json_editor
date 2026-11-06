import 'package:material_ui/material_ui.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// A row of segments for a single choice, activated by
/// `"x-format": "segmented"` on an `enum` or on a `oneOf`/`anyOf` of
/// `const`s (the branch `title`s label the segments):
///
/// ```json
/// {"type": "string", "title": "Priority", "x-format": "segmented",
///  "oneOf": [{"const": "low", "title": "Low"},
///            {"const": "normal", "title": "Normal"},
///            {"const": "high", "title": "High"}]}
/// ```
///
/// Best for two to five short options; more scroll sideways. Tapping the
/// chosen segment again clears the field unless it is required. A schema
/// without such choices renders with the editor it would get without the
/// `x-format`.
class SegmentedEditor extends SchemaFieldEditor {
  const SegmentedEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<SegmentedEditor> createState() => _SegmentedEditorState();
}

class _SegmentedEditorState extends State<SegmentedEditor> {
  @override
  Widget build(BuildContext context) {
    final choices = choicesOf(widget.schema);
    if (choices == null) {
      return editorWithoutFormat(
        context,
        format: 'segmented',
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
    final selected = choices.indexWhere((c) => c.value == widget.value);
    final canClear = !widget.isRequired || widget.isNullable;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          segments: [
            for (var i = 0; i < choices.length; i++)
              ButtonSegment<int>(
                value: i,
                label: Text(choices[i].title),
                tooltip: choices[i].description,
                enabled: !readOnly,
              ),
          ],
          selected: {if (selected >= 0) selected},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          onSelectionChanged: readOnly
              ? null
              : (selection) {
                  if (selection.isEmpty) {
                    if (canClear) widget.onChanged(null);
                    return;
                  }
                  widget.onChanged(choices[selection.first].value);
                },
        ),
      ),
    );
  }
}
