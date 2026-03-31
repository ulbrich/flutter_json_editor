// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'JSON-Editor Demo';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get saveButton => 'Speichern';

  @override
  String get cancelledMessage => 'Abgebrochen';

  @override
  String savedMessage(int count) {
    return 'Gespeichert: $count Einträge';
  }

  @override
  String get currentDataTitle => 'Aktuelle Daten';

  @override
  String get lastDiffTitle => 'Letzte Änderung';
}
