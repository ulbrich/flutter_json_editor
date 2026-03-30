// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'json_editor_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class JsonEditorLocalizationsEn extends JsonEditorLocalizations {
  JsonEditorLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get clearToNullTooltip => 'Clear to null';

  @override
  String get clearTooltip => 'Clear';

  @override
  String get addItemTooltip => 'Add item';

  @override
  String get addEntryTooltip => 'Add entry';

  @override
  String get keyLabel => 'Key';

  @override
  String get dateLabel => 'Date';

  @override
  String get hourLabel => 'Hour';

  @override
  String get minuteLabel => 'Minute';

  @override
  String get timeLabel => 'Time';

  @override
  String get clearSelectionLabel => 'Clear selection';

  @override
  String get noImagesAvailableLabel => 'No images available';

  @override
  String get noneOptionLabel => '— None —';

  @override
  String get oneOfLabel => 'one of';

  @override
  String get anyOfLabel => 'any of';

  @override
  String compositionOptionLabel(int index) {
    return 'Option $index';
  }

  @override
  String get invalidNumberFormat => 'Invalid number format';

  @override
  String get noRefLookupCallbackError => 'No onRefLookup callback provided';

  @override
  String get remoteDataUnavailableError => 'Remote data unavailable';

  @override
  String get remoteSchemaUnavailableError => 'Remote schema unavailable';

  @override
  String get noEnumSourceError => 'No enumSource in response';

  @override
  String failedToLoadError(String details) {
    return 'Failed to load: $details';
  }

  @override
  String get noSvgAssetPathError =>
      'No SVG asset path specified (x-svg-asset).';

  @override
  String failedToLoadSvgError(String details) {
    return 'Failed to load SVG: $details';
  }

  @override
  String get svgNotAvailableError => 'SVG not available.';

  @override
  String preservedIdsHint(int count) {
    return '+ $count ID(s) not in this SVG (preserved)';
  }

  @override
  String editorPlaceholder(String type, String path) {
    return 'Editor for $type at $path';
  }

  @override
  String addNestedLabel(String typeName) {
    return 'Add nested $typeName';
  }
}
