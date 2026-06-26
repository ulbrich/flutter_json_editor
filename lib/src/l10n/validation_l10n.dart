import 'generated/json_editor_localizations.dart';

/// Translates raw validation messages produced by the `json_schema` package
/// into localized, user-facing strings.
///
/// The package emits English-only messages such as
/// `"email" format not accepted foo@`. These messages are not localized by
/// the library, so we recognise the known patterns here and map them onto the
/// translatable strings in the ARB files. Unrecognised messages are returned
/// unchanged so nothing is ever swallowed.
String localizeValidationError(JsonEditorLocalizations l10n, String rawMessage) {
  final formatMatch =
      RegExp(r'^"(.+?)" format not accepted').firstMatch(rawMessage);
  if (formatMatch != null) {
    final format = formatMatch.group(1)!;
    switch (format) {
      case 'email':
      case 'idn-email':
        return l10n.invalidEmailFormat;
      case 'uri':
      case 'uri-reference':
      case 'iri':
      case 'iri-reference':
        return l10n.invalidUriFormat;
      case 'date':
        return l10n.invalidDateFormat;
      case 'date-time':
        return l10n.invalidDateTimeFormat;
      case 'time':
        return l10n.invalidTimeFormat;
      default:
        return l10n.invalidFormatError(format);
    }
  }
  return rawMessage;
}

/// Localizes the first error in [errors], or returns `null` when there is none.
String? localizeFirstValidationError(
  JsonEditorLocalizations l10n,
  List<String> errors,
) {
  if (errors.isEmpty) return null;
  return localizeValidationError(l10n, errors.first);
}
