import 'package:flutter/widgets.dart';

import 'generated/json_editor_localizations.dart';
import 'generated/json_editor_localizations_en.dart';

/// Safe accessor for [JsonEditorLocalizations].
///
/// Falls back to [JsonEditorLocalizationsEn] when no delegate is registered
/// (e.g. in tests or when the consuming app hasn't added the delegate).
/// Use this instead of [JsonEditorLocalizations.of] in all editor code.
class JsonEditorL10n {
  JsonEditorL10n._();

  static JsonEditorLocalizations of(BuildContext context) {
    return Localizations.of<JsonEditorLocalizations>(
          context,
          JsonEditorLocalizations,
        ) ??
        JsonEditorLocalizationsEn();
  }
}
