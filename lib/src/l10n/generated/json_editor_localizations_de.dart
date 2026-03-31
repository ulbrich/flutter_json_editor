// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'json_editor_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class JsonEditorLocalizationsDe extends JsonEditorLocalizations {
  JsonEditorLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get clearToNullTooltip => 'Leeren';

  @override
  String get clearTooltip => 'Leeren';

  @override
  String get addItemTooltip => 'Eintrag hinzufügen';

  @override
  String get addEntryTooltip => 'Eintrag hinzufügen';

  @override
  String get keyLabel => 'Schlüssel';

  @override
  String get dateLabel => 'Datum';

  @override
  String get hourLabel => 'Stunde';

  @override
  String get minuteLabel => 'Minute';

  @override
  String get timeLabel => 'Uhrzeit';

  @override
  String get clearSelectionLabel => 'Auswahl aufheben';

  @override
  String get noImagesAvailableLabel => 'Keine Bilder verfügbar';

  @override
  String get noneOptionLabel => '— Keine Auswahl —';

  @override
  String get oneOfLabel => 'eines von';

  @override
  String get anyOfLabel => 'beliebig aus';

  @override
  String compositionOptionLabel(int index) {
    return 'Option $index';
  }

  @override
  String get invalidNumberFormat => 'Ungültiges Zahlenformat';

  @override
  String get noRefLookupCallbackError => 'Kein onRefLookup-Callback angegeben';

  @override
  String get remoteDataUnavailableError => 'Remote-Daten nicht verfügbar';

  @override
  String get remoteSchemaUnavailableError => 'Remote-Schema nicht verfügbar';

  @override
  String get noEnumSourceError => 'Keine enumSource in der Antwort';

  @override
  String failedToLoadError(String details) {
    return 'Laden fehlgeschlagen: $details';
  }

  @override
  String get noSvgAssetPathError => 'Kein SVG-Pfad angegeben (x-svg-asset).';

  @override
  String failedToLoadSvgError(String details) {
    return 'SVG konnte nicht geladen werden: $details';
  }

  @override
  String get svgNotAvailableError => 'SVG nicht verfügbar.';

  @override
  String preservedIdsHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count nicht dargestellte IDs (beibehalten)',
      one: '+ eine nicht dargestellte ID (beibehalten)',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String editorPlaceholder(String type, String path) {
    return 'Editor für $type bei $path';
  }

  @override
  String addNestedLabel(String typeName) {
    return '$typeName hinzufügen';
  }
}
