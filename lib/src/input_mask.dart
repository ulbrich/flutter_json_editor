import 'package:flutter/services.dart';

/// A fixed pattern for typed text, from a schema's `x-mask`: `0` takes a
/// digit, `A` a letter, `*` a letter or digit, and every other character
/// is written as is. `+49 000 0000000`, `AA-0000`, `0000 0000 0000 0000`.
///
/// Literals appear as soon as the slot after them is typed; characters that
/// don't fit their slot are skipped.
class InputMask {
  const InputMask(this.pattern);

  final String pattern;

  static bool _isSlot(String c) => c == '0' || c == 'A' || c == '*';

  static bool _fits(String slot, String c) {
    final code = c.codeUnitAt(0);
    final digit = code >= 48 && code <= 57;
    final letter = c.toLowerCase() != c.toUpperCase();
    return switch (slot) {
      '0' => digit,
      'A' => letter,
      _ => digit || letter,
    };
  }

  /// The number of characters the user types for a full value.
  int get slotCount => pattern.split('').where(_isSlot).length;

  /// [input], typed or stored, laid out by the pattern.
  String apply(String input) {
    final out = StringBuffer();
    var i = 0;
    for (final m in pattern.split('')) {
      if (i >= input.length) break;
      if (_isSlot(m)) {
        while (i < input.length && !_fits(m, input[i])) {
          i++;
        }
        if (i >= input.length) break;
        out.write(input[i]);
        i++;
      } else {
        out.write(m);
        if (input[i] == m) i++;
      }
    }
    return out.toString();
  }

  /// The typed characters of a [formatted] text, without the literals.
  String raw(String formatted) {
    final out = StringBuffer();
    final text = apply(formatted);
    for (var i = 0; i < text.length && i < pattern.length; i++) {
      if (_isSlot(pattern[i])) out.write(text[i]);
    }
    return out.toString();
  }

  /// Whether [formatted] fills every slot.
  bool isComplete(String formatted) => raw(formatted).length == slotCount;

  /// The pattern as a hint, slots shown as `_`.
  String get hint => pattern.split('').map((c) => _isSlot(c) ? '_' : c).join();

  /// A [TextInputFormatter] that keeps the text in the pattern.
  TextInputFormatter get formatter => _MaskFormatter(this);
}

class _MaskFormatter extends TextInputFormatter {
  _MaskFormatter(this.mask);

  final InputMask mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = mask.apply(newValue.text);
    // Deleting just a literal would put it straight back: drop the slot
    // before it too.
    if (newValue.text.length < oldValue.text.length && text == oldValue.text) {
      // The old text is laid out by the pattern, so its slots line up.
      final old = oldValue.text;
      final cut = newValue.selection.baseOffset.clamp(0, old.length);
      var drop = -1;
      for (var i = 0; i < cut && i < mask.pattern.length; i++) {
        if (InputMask._isSlot(mask.pattern[i])) drop = i;
      }
      final kept = StringBuffer();
      for (var i = 0; i < old.length && i < mask.pattern.length; i++) {
        if (i != drop && InputMask._isSlot(mask.pattern[i])) kept.write(old[i]);
      }
      text = mask.apply(kept.toString());
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
