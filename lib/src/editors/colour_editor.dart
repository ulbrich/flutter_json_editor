import 'dart:math';

import 'package:flutter/material.dart';
import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

/// A custom editor widget that renders a colour wheel for picking colours.
///
/// The colour value is stored and reported as a hex string in `#rrggbb` format
/// (e.g. `#ff0000` for red).
class ColourEditor extends SchemaFieldEditor {
  const ColourEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<ColourEditor> createState() => _ColourEditorState();
}

class _ColourEditorState extends State<ColourEditor> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = _parseHexToHsv(widget.value as String?);
  }

  @override
  void didUpdateWidget(ColourEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update from the parent when the value genuinely changed externally.
    // Comparing against the current hex avoids resetting _hsvColor on the
    // rebuild triggered by our own onChanged (HSV→hex→HSV round-trip loses
    // precision, so comparing oldWidget.value alone would always re-parse).
    final currentHex = _hsvToHex(_hsvColor);
    if (widget.value != currentHex) {
      _hsvColor = _parseHexToHsv(widget.value as String?);
    }
  }

  HSVColor _parseHexToHsv(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);
    }
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) {
      return const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);
    }
    final intValue = int.tryParse(clean, radix: 16);
    if (intValue == null) {
      return const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0);
    }
    final color = Color(0xFF000000 | intValue);
    return HSVColor.fromColor(color);
  }

  String _hsvToHex(HSVColor hsv) {
    final color = hsv.toColor();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  void _onWheelPan(Offset localPosition, double radius) {
    final center = Offset(radius, radius);
    final diff = localPosition - center;
    final dist = diff.distance.clamp(0.0, radius);
    final angle = (atan2(diff.dy, diff.dx) * 180 / pi + 360) % 360;

    setState(() {
      _hsvColor = HSVColor.fromAHSV(
        1.0,
        angle,
        dist / radius,
        _hsvColor.value,
      );
    });
    widget.onChanged(_hsvToHex(_hsvColor));
  }

  void _onBrightnessChanged(double value) {
    setState(() {
      _hsvColor = _hsvColor.withValue(value);
    });
    widget.onChanged(_hsvToHex(_hsvColor));
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
    final hexString = _hsvToHex(_hsvColor);
    const wheelSize = 180.0;
    const wheelRadius = wheelSize / 2;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Text(
                _buildLabel(),
                style: editorTheme.labelStyle ??
                    Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              // Colour preview swatch
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hsvColor.toColor(),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hexString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
          const SizedBox(height: 12),
          // Colour wheel
          Center(
            child: SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: Listener(
                onPointerDown: (details) =>
                    _onWheelPan(details.localPosition, wheelRadius),
                onPointerMove: (details) =>
                    _onWheelPan(details.localPosition, wheelRadius),
                child: CustomPaint(
                  size: const Size(wheelSize, wheelSize),
                  painter: _ColourWheelPainter(
                    brightness: _hsvColor.value,
                    selectedHue: _hsvColor.hue,
                    selectedSaturation: _hsvColor.saturation,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Brightness slider
          Row(
            children: [
              const Icon(Icons.brightness_low, size: 18),
              Expanded(
                child: Slider(
                  value: _hsvColor.value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: _onBrightnessChanged,
                ),
              ),
              const Icon(Icons.brightness_high, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColourWheelPainter extends CustomPainter {
  final double brightness;
  final double selectedHue;
  final double selectedSaturation;

  _ColourWheelPainter({
    required this.brightness,
    required this.selectedHue,
    required this.selectedSaturation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the colour wheel pixel-by-pixel using a sweep gradient for hue
    // and a radial gradient for saturation.
    for (var angle = 0.0; angle < 360.0; angle += 1.0) {
      final radians = angle * pi / 180;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            HSVColor.fromAHSV(1.0, angle, 0.0, brightness).toColor(),
            HSVColor.fromAHSV(1.0, angle, 1.0, brightness).toColor(),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2 * pi * radius / 360) + 1;

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(radians),
          center.dy + radius * sin(radians),
        ),
        paint,
      );
    }

    // Draw selection indicator
    final selectorAngle = selectedHue * pi / 180;
    final selectorDist = selectedSaturation * radius;
    final selectorPos = Offset(
      center.dx + selectorDist * cos(selectorAngle),
      center.dy + selectorDist * sin(selectorAngle),
    );

    // Outer ring (white)
    canvas.drawCircle(
      selectorPos,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Inner ring (black)
    canvas.drawCircle(
      selectorPos,
      8,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ColourWheelPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.selectedHue != selectedHue ||
      oldDelegate.selectedSaturation != selectedSaturation;
}
