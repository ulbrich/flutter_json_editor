import 'package:flutter/material.dart';

class JsonEditorTheme extends ThemeExtension<JsonEditorTheme> {
  final double fieldSpacing;
  final double sectionSpacing;
  final EdgeInsets fieldPadding;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final Color? requiredIndicatorColor;

  const JsonEditorTheme({
    this.fieldSpacing = 4.0,
    this.sectionSpacing = 8.0,
    this.fieldPadding = const EdgeInsets.symmetric(
      horizontal: 0.0,
      vertical: 2.0,
    ),
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.requiredIndicatorColor,
  });

  @override
  JsonEditorTheme copyWith({
    double? fieldSpacing,
    double? sectionSpacing,
    EdgeInsets? fieldPadding,
    TextStyle? labelStyle,
    TextStyle? errorStyle,
    TextStyle? helperStyle,
    Color? requiredIndicatorColor,
  }) {
    return JsonEditorTheme(
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      fieldPadding: fieldPadding ?? this.fieldPadding,
      labelStyle: labelStyle ?? this.labelStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      helperStyle: helperStyle ?? this.helperStyle,
      requiredIndicatorColor:
          requiredIndicatorColor ?? this.requiredIndicatorColor,
    );
  }

  @override
  JsonEditorTheme lerp(JsonEditorTheme? other, double t) {
    if (other == null) return this;
    return JsonEditorTheme(
      fieldSpacing:
          lerpDouble(fieldSpacing, other.fieldSpacing, t) ?? fieldSpacing,
      sectionSpacing:
          lerpDouble(sectionSpacing, other.sectionSpacing, t) ?? sectionSpacing,
      fieldPadding:
          EdgeInsets.lerp(fieldPadding, other.fieldPadding, t) ?? fieldPadding,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      errorStyle: TextStyle.lerp(errorStyle, other.errorStyle, t),
      helperStyle: TextStyle.lerp(helperStyle, other.helperStyle, t),
      requiredIndicatorColor: Color.lerp(
        requiredIndicatorColor,
        other.requiredIndicatorColor,
        t,
      ),
    );
  }
}

double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}
