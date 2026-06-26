import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'json_editor_localizations_de.dart';
import 'json_editor_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of JsonEditorLocalizations
/// returned by `JsonEditorLocalizations.of(context)`.
///
/// Applications need to include `JsonEditorLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/json_editor_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: JsonEditorLocalizations.localizationsDelegates,
///   supportedLocales: JsonEditorLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the JsonEditorLocalizations.supportedLocales
/// property.
abstract class JsonEditorLocalizations {
  JsonEditorLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static JsonEditorLocalizations of(BuildContext context) {
    return Localizations.of<JsonEditorLocalizations>(
        context, JsonEditorLocalizations)!;
  }

  static const LocalizationsDelegate<JsonEditorLocalizations> delegate =
      _JsonEditorLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Tooltip for buttons that clear a nullable field to null
  ///
  /// In en, this message translates to:
  /// **'Clear to null'**
  String get clearToNullTooltip;

  /// Short tooltip for clear buttons
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTooltip;

  /// Tooltip for the add-item button in array editors
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTooltip;

  /// Tooltip for the add-entry button in map editors
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntryTooltip;

  /// Label for map entry key fields
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyLabel;

  /// Label for date picker fields
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Label for the hour dropdown
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hourLabel;

  /// Label for the minute dropdown
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minuteLabel;

  /// Label for time picker fields
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// Label for the clear-selection button in image pickers
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelectionLabel;

  /// Shown when an image picker has no images to display
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailableLabel;

  /// Placeholder option in dropdowns where no value is selected
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get noneOptionLabel;

  /// Label fragment for oneOf composition
  ///
  /// In en, this message translates to:
  /// **'one of'**
  String get oneOfLabel;

  /// Label fragment for anyOf composition
  ///
  /// In en, this message translates to:
  /// **'any of'**
  String get anyOfLabel;

  /// Default label for a composition option at the given 1-based index
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String compositionOptionLabel(int index);

  /// Error message when a number field contains non-numeric text
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get invalidNumberFormat;

  /// Validation error when a value does not match the email/idn-email format
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmailFormat;

  /// Validation error when a value does not match a uri/iri format
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUriFormat;

  /// Validation error when a value does not match the date format
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDateFormat;

  /// Validation error when a value does not match the date-time format
  ///
  /// In en, this message translates to:
  /// **'Invalid date and time'**
  String get invalidDateTimeFormat;

  /// Validation error when a value does not match the time format
  ///
  /// In en, this message translates to:
  /// **'Invalid time'**
  String get invalidTimeFormat;

  /// Generic validation error when a value does not match a named format
  ///
  /// In en, this message translates to:
  /// **'Invalid format: {format}'**
  String invalidFormatError(String format);

  /// Error when no onRefLookup callback was provided but a ref was found
  ///
  /// In en, this message translates to:
  /// **'No onRefLookup callback provided'**
  String get noRefLookupCallbackError;

  /// Error when remote data could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Remote data unavailable'**
  String get remoteDataUnavailableError;

  /// Error when a remote schema could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Remote schema unavailable'**
  String get remoteSchemaUnavailableError;

  /// Error when the remote response contains no enumSource
  ///
  /// In en, this message translates to:
  /// **'No enumSource in response'**
  String get noEnumSourceError;

  /// Generic failed-to-load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {details}'**
  String failedToLoadError(String details);

  /// Error when no x-svg-asset path is specified in the schema
  ///
  /// In en, this message translates to:
  /// **'No SVG asset path specified (x-svg-asset).'**
  String get noSvgAssetPathError;

  /// Error when the SVG file could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load SVG: {details}'**
  String failedToLoadSvgError(String details);

  /// Shown when the SVG string is null or unavailable
  ///
  /// In en, this message translates to:
  /// **'SVG not available.'**
  String get svgNotAvailableError;

  /// Hint about IDs preserved from other SVGs
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{} =1{+ one not displayed ID (preserved)} other{+ {count} not displayed IDs (preserved)}}'**
  String preservedIdsHint(int count);

  /// Placeholder text for an unresolved editor
  ///
  /// In en, this message translates to:
  /// **'Editor for {type} at {path}'**
  String editorPlaceholder(String type, String path);

  /// Button label to add a nested object/array
  ///
  /// In en, this message translates to:
  /// **'Add nested {typeName}'**
  String addNestedLabel(String typeName);
}

class _JsonEditorLocalizationsDelegate
    extends LocalizationsDelegate<JsonEditorLocalizations> {
  const _JsonEditorLocalizationsDelegate();

  @override
  Future<JsonEditorLocalizations> load(Locale locale) {
    return SynchronousFuture<JsonEditorLocalizations>(
        lookupJsonEditorLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_JsonEditorLocalizationsDelegate old) => false;
}

JsonEditorLocalizations lookupJsonEditorLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return JsonEditorLocalizationsDe();
    case 'en':
      return JsonEditorLocalizationsEn();
  }

  throw FlutterError(
      'JsonEditorLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
