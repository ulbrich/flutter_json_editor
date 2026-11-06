import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// A pad to sign or sketch on with a finger, pen or mouse, activated by
/// `"x-format": "signature"` on a `string` schema:
///
/// ```json
/// {"type": "string", "title": "Signature", "x-format": "signature"}
/// ```
///
/// The drawing is stored as a small SVG document: black strokes on a
/// [SignatureEditor.viewBoxWidth] × [SignatureEditor.viewBoxHeight] view box,
/// one path whose subpaths are the strokes, so any SVG renderer can show it.
/// The pad keeps that 3:1 aspect ratio at every width. Undo removes the last
/// stroke; clear removes all. The pad reads back the SVG it wrote; other
/// SVG is shown as empty and replaced by the next stroke. A schema that
/// isn't a string renders with the editor it would get without the
/// `x-format`.
class SignatureEditor extends SchemaFieldEditor {
  const SignatureEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  static const double viewBoxWidth = 600;
  static const double viewBoxHeight = 200;
  static const double strokeWidth = 3;

  /// The strokes of an SVG written by [toSvg]; empty for anything else.
  static List<List<Offset>> parseSvg(String? svg) {
    if (svg == null) return [];
    final d = RegExp(r'\bd="([^"]*)"').firstMatch(svg)?.group(1);
    if (d == null) return [];
    final strokes = <List<Offset>>[];
    final tokens = RegExp(r'([ML])\s*(-?[\d.]+)[\s,]+(-?[\d.]+)').allMatches(d);
    for (final token in tokens) {
      final point = Offset(
        double.tryParse(token.group(2)!) ?? 0,
        double.tryParse(token.group(3)!) ?? 0,
      );
      if (token.group(1) == 'M' || strokes.isEmpty) {
        strokes.add([point]);
      } else {
        strokes.last.add(point);
      }
    }
    return strokes;
  }

  /// The SVG document for [strokes] (view-box coordinates); null when there
  /// are none.
  static String? toSvg(List<List<Offset>> strokes) {
    final visible = strokes.where((s) => s.isNotEmpty).toList();
    if (visible.isEmpty) return null;
    String n(double v) {
      final text = v.toStringAsFixed(1);
      return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
    }

    final d = StringBuffer();
    for (final stroke in visible) {
      // A single point (a tap) is drawn as a dot: a zero-length line with
      // round caps.
      final points = stroke.length == 1 ? [stroke.first, stroke.first] : stroke;
      for (var i = 0; i < points.length; i++) {
        if (d.isNotEmpty) d.write(' ');
        d.write('${i == 0 ? 'M' : 'L'}${n(points[i].dx)} ${n(points[i].dy)}');
      }
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 ${n(viewBoxWidth)} ${n(viewBoxHeight)}">'
        '<path d="$d" fill="none" stroke="#000000" '
        'stroke-width="${n(strokeWidth)}" stroke-linecap="round" '
        'stroke-linejoin="round"/></svg>';
  }

  @override
  State<SignatureEditor> createState() => _SignatureEditorState();
}

class _SignatureEditorState extends State<SignatureEditor> {
  List<List<Offset>> _strokes = [];

  /// The value this editor emitted last, so its own echo isn't parsed again.
  String? _emitted;

  @override
  void initState() {
    super.initState();
    _strokes = SignatureEditor.parseSvg(_text(widget.value));
  }

  @override
  void didUpdateWidget(SignatureEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _text(widget.value);
    if (incoming != _emitted && widget.value != oldWidget.value) {
      _strokes = SignatureEditor.parseSvg(incoming);
    }
  }

  String? _text(dynamic value) => value is String ? value : null;

  void _emit() {
    _emitted = SignatureEditor.toSvg(_strokes);
    widget.onChanged(_emitted);
  }

  Offset _toViewBox(Offset local, Size size) {
    final scale = SignatureEditor.viewBoxWidth / size.width;
    return Offset(
      (local.dx * scale).clamp(0, SignatureEditor.viewBoxWidth),
      (local.dy * scale).clamp(0, SignatureEditor.viewBoxHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!schemaTypeNames(widget.schema).contains('string')) {
      return editorWithoutFormat(
        context,
        format: 'signature',
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
    final readOnly = widget.schema.readOnly == true;
    final hasStrokes = _strokes.isNotEmpty;

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      trailing: readOnly
          ? null
          : [
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: l10n.undoTooltip,
                onPressed: hasStrokes
                    ? () {
                        setState(() => _strokes = [..._strokes]..removeLast());
                        _emit();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.clearTooltip,
                onPressed: hasStrokes
                    ? () {
                        setState(() => _strokes = []);
                        _emit();
                      }
                    : null,
              ),
            ],
      child: AspectRatio(
        aspectRatio:
            SignatureEditor.viewBoxWidth / SignatureEditor.viewBoxHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final pad = DecoratedBox(
              key: const ValueKey('signature-pad'),
              decoration: BoxDecoration(
                // Paper, in light and dark themes alike: the strokes are
                // stored black.
                color: Colors.white,
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: _SignaturePainter(
                    _strokes,
                    size.width / SignatureEditor.viewBoxWidth,
                  ),
                  child: hasStrokes
                      ? const SizedBox.expand()
                      : Center(
                          child: Text(
                            readOnly ? '' : l10n.signatureHint,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black45,
                            ),
                          ),
                        ),
                ),
              ),
            );
            if (readOnly) return pad;
            return RawGestureDetector(
              gestures: {
                _EagerPanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      _EagerPanGestureRecognizer
                    >(_EagerPanGestureRecognizer.new, (recognizer) {
                      recognizer.onStart = (details) {
                        setState(() {
                          _strokes = [
                            ..._strokes,
                            [_toViewBox(details.localPosition, size)],
                          ];
                        });
                      };
                      recognizer.onUpdate = (details) {
                        final point = _toViewBox(details.localPosition, size);
                        final last = _strokes.last;
                        // Skip points too close to draw a visible segment.
                        if ((point - last.last).distance < 1.5) return;
                        setState(() => last.add(point));
                      };
                      recognizer.onEnd = (_) => _emit();
                      recognizer.onCancel = _emit;
                    }),
              },
              child: pad,
            );
          },
        ),
      ),
    );
  }
}

/// Wins the gesture arena at once, so drawing on the pad doesn't scroll the
/// surrounding form.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes, this.scale);

  final List<List<Offset>> strokes;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = SignatureEditor.strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * scale, stroke.first.dy * scale);
      if (stroke.length == 1) {
        path.lineTo(stroke.first.dx * scale, stroke.first.dy * scale);
      }
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * scale, point.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  // The stroke lists are mutated in place while drawing.
  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
