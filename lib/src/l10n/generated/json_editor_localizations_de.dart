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
  String get selectOptionLabel => 'Auswählen…';

  @override
  String get increaseTooltip => 'Erhöhen';

  @override
  String get decreaseTooltip => 'Verringern';

  @override
  String get undoTooltip => 'Rückgängig';

  @override
  String get signatureHint => 'Hier unterschreiben';

  @override
  String get hoursLabel => 'Stunden';

  @override
  String get minutesLabel => 'Minuten';

  @override
  String get invalidDurationFormat => 'Ungültige Dauer';

  @override
  String get choosePictureLabel => 'Bild auswählen';

  @override
  String get takePhotoLabel => 'Foto aufnehmen';

  @override
  String get removeImageTooltip => 'Bild entfernen';

  @override
  String get invalidImageData => 'Ungültige Bilddaten';

  @override
  String get imagePickFailed => 'Das Bild konnte nicht geladen werden';

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
  String get invalidEmailFormat => 'Ungültige E-Mail-Adresse';

  @override
  String get invalidUriFormat => 'Ungültige URL';

  @override
  String get invalidDateFormat => 'Ungültiges Datum';

  @override
  String get invalidDateTimeFormat => 'Ungültiges Datum mit Uhrzeit';

  @override
  String get invalidTimeFormat => 'Ungültige Uhrzeit';

  @override
  String invalidFormatError(String format) {
    return 'Ungültiges Format: $format';
  }

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

  @override
  String get npsLowLabel => 'Sehr unwahrscheinlich';

  @override
  String get npsHighLabel => 'Sehr wahrscheinlich';

  @override
  String get moveUpTooltip => 'Nach oben';

  @override
  String get moveDownTooltip => 'Nach unten';

  @override
  String get rankingHint => 'Zum Sortieren ziehen oder die Pfeile nutzen';

  @override
  String get dateRangeLabel => 'Von – bis';

  @override
  String get phoneCountryLabel => 'Land';

  @override
  String get phoneNumberLabel => 'Nummer';

  @override
  String get invalidPhoneNumber =>
      'Keine gültige Telefonnummer für dieses Land';

  @override
  String get wizardBack => 'Zurück';

  @override
  String get wizardNext => 'Weiter';

  @override
  String get wizardFinish => 'Fertig';

  @override
  String get wizardStepIncomplete =>
      'Bitte fülle die Pflichtfelder auf dieser Seite aus';

  @override
  String get tabIncomplete =>
      'Auf diesem Tab fehlen Angaben oder sind ungültig';

  @override
  String get calcCycleError => 'Diese Berechnung hängt von sich selbst ab';

  @override
  String get chooseFileLabel => 'Datei wählen';

  @override
  String get replaceFileLabel => 'Datei ersetzen';

  @override
  String get removeFileTooltip => 'Datei entfernen';

  @override
  String get unnamedFile => 'Unbenannte Datei';

  @override
  String get filePickFailed => 'Die Datei konnte nicht gelesen werden';

  @override
  String get invalidFileData => 'Die gespeicherte Datei ist nicht lesbar';

  @override
  String get consentRequired => 'Bitte stimme zu, um fortzufahren';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String wizardStep(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String fileTooLarge(String size) {
    return 'Die Datei ist größer als $size';
  }

  @override
  String fileTypeNotAllowed(String types) {
    return 'Erlaubt sind nur: $types';
  }

  @override
  String maxFileSizeHint(String size) {
    return 'Höchstens $size';
  }

  @override
  String maskIncomplete(String pattern) {
    return 'Bitte im Format $pattern eingeben';
  }
}
