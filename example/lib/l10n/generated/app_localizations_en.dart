// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JSON Editor Demo';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelledMessage => 'Cancelled';

  @override
  String savedMessage(int count) {
    return 'Saved: $count items';
  }

  @override
  String get currentDataTitle => 'Current Data';

  @override
  String get lastDiffTitle => 'Last Diff';
}
