import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

/// A custom editor widget that renders a clickable 0–5 star rating.
///
/// Works with both string and integer schema types:
/// - For `type: "integer"`, values are stored as `int` (e.g. `3`).
/// - For `type: "string"`, values are stored as `String` (e.g. `"3"`).
///
/// Clicking a star sets the rating to that star's position (1–5).
/// Clicking the same star again (i.e. the current rating) resets to 0.
class StarRatingEditor extends SchemaFieldEditor {
  const StarRatingEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<StarRatingEditor> createState() => _StarRatingEditorState();
}

class _StarRatingEditorState extends State<StarRatingEditor> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = _parseRating(widget.value);
  }

  @override
  void didUpdateWidget(StarRatingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _parseRating(widget.value);
    if (incoming != _rating) {
      _rating = incoming;
    }
  }

  int _parseRating(dynamic value) {
    if (value is int) return value.clamp(0, 5);
    if (value is num) return value.toInt().clamp(0, 5);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed.clamp(0, 5);
    }
    return 0;
  }

  bool get _isIntegerType {
    final type = widget.schema.type;
    if (type != null) return type.toString() == 'integer';
    final typeList = widget.schema.typeList;
    if (typeList != null) {
      return typeList.any((t) => t.toString() == 'integer');
    }
    return false;
  }

  void _emitValue(int rating) {
    if (_isIntegerType) {
      widget.onChanged(rating);
    } else {
      widget.onChanged(rating.toString());
    }
  }

  void _onStarTapped(int starIndex) {
    setState(() {
      if (_rating == starIndex) {
        _rating = 0;
      } else {
        _rating = starIndex;
      }
    });
    _emitValue(_rating);
  }

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _buildLabel(),
                style: editorTheme.labelStyle ??
                    Theme.of(context).textTheme.bodyMedium,
              ),
              if (widget.isNullable && widget.value != null) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: JsonEditorL10n.of(context).clearToNullTooltip,
                  onPressed: () => widget.onChanged(null),
                ),
              ],
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
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => _onStarTapped(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      size: 32,
                      color: i <= _rating
                          ? Colors.amber
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '$_rating / 5',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
