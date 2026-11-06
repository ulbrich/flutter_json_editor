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
      context,
      JsonEditorLocalizations,
    )!;
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
    Locale('en'),
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

  /// Placeholder of a picture choice field while nothing is chosen
  ///
  /// In en, this message translates to:
  /// **'Select…'**
  String get selectOptionLabel;

  /// Tooltip of the + button of a stepper field
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increaseTooltip;

  /// Tooltip of the − button of a stepper field
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decreaseTooltip;

  /// Tooltip of the button that removes the last stroke of a signature field
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoTooltip;

  /// Hint shown on an empty signature pad
  ///
  /// In en, this message translates to:
  /// **'Sign here'**
  String get signatureHint;

  /// Label of the hours field of a duration
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// Label of the minutes field of a duration
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// Error when a stored duration isn't an ISO 8601 duration the editor can read
  ///
  /// In en, this message translates to:
  /// **'Invalid duration'**
  String get invalidDurationFormat;

  /// Button of the image data editor that picks a picture from the photo library or a file
  ///
  /// In en, this message translates to:
  /// **'Choose picture'**
  String get choosePictureLabel;

  /// Button of the image data editor that takes a picture with the camera
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhotoLabel;

  /// Tooltip of the button that removes the picture of an image data field
  ///
  /// In en, this message translates to:
  /// **'Remove picture'**
  String get removeImageTooltip;

  /// Error when a stored value isn't a base64 string or data URI
  ///
  /// In en, this message translates to:
  /// **'Invalid image data'**
  String get invalidImageData;

  /// Error when picking or taking a picture failed, e.g. without camera permission
  ///
  /// In en, this message translates to:
  /// **'The picture could not be loaded'**
  String get imagePickFailed;

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

  /// Label under the lowest NPS score
  ///
  /// In en, this message translates to:
  /// **'Not at all likely'**
  String get npsLowLabel;

  /// Label under the highest NPS score
  ///
  /// In en, this message translates to:
  /// **'Extremely likely'**
  String get npsHighLabel;

  /// Tooltip of the button that moves a ranked choice up
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUpTooltip;

  /// Tooltip of the button that moves a ranked choice down
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDownTooltip;

  /// Hint above a ranking that hasn't been ordered yet
  ///
  /// In en, this message translates to:
  /// **'Drag or use the arrows to put the choices in order'**
  String get rankingHint;

  /// Label of the date range field
  ///
  /// In en, this message translates to:
  /// **'From – to'**
  String get dateRangeLabel;

  /// Label of the country menu of a phone number
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get phoneCountryLabel;

  /// Label of the number part of a phone number
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get phoneNumberLabel;

  /// Error for an invalid phone number
  ///
  /// In en, this message translates to:
  /// **'Not a valid phone number for this country'**
  String get invalidPhoneNumber;

  /// Button to the previous wizard page
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wizardBack;

  /// Button to the next wizard page
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get wizardNext;

  /// Button that submits the form on the last wizard page
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get wizardFinish;

  /// Error when going on from an incomplete wizard page
  ///
  /// In en, this message translates to:
  /// **'Please fill in the required fields on this page'**
  String get wizardStepIncomplete;

  /// Tooltip of the mark on a tab with missing or invalid answers
  ///
  /// In en, this message translates to:
  /// **'Some answers on this tab are missing or invalid'**
  String get tabIncomplete;

  /// Error on a calculated field whose formulas form a loop
  ///
  /// In en, this message translates to:
  /// **'This calculation depends on itself'**
  String get calcCycleError;

  /// Button that opens the file chooser
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFileLabel;

  /// Button that chooses another file in place of the current one
  ///
  /// In en, this message translates to:
  /// **'Replace file'**
  String get replaceFileLabel;

  /// Tooltip of the button that removes a file
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get removeFileTooltip;

  /// Name shown for a stored file without one
  ///
  /// In en, this message translates to:
  /// **'Unnamed file'**
  String get unnamedFile;

  /// Error when choosing a file failed
  ///
  /// In en, this message translates to:
  /// **'The file couldn\'t be read'**
  String get filePickFailed;

  /// Error when a stored file isn't valid base64
  ///
  /// In en, this message translates to:
  /// **'The stored file can\'t be read'**
  String get invalidFileData;

  /// Error when a required consent isn't given
  ///
  /// In en, this message translates to:
  /// **'Please agree to continue'**
  String get consentRequired;

  /// Number of days in a date range
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// Progress text of a wizard
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String wizardStep(int current, int total);

  /// Error for a file over the size limit
  ///
  /// In en, this message translates to:
  /// **'The file is larger than {size}'**
  String fileTooLarge(String size);

  /// Error for a file of a type not allowed
  ///
  /// In en, this message translates to:
  /// **'Only these are allowed: {types}'**
  String fileTypeNotAllowed(String types);

  /// Hint with the largest file allowed
  ///
  /// In en, this message translates to:
  /// **'Up to {size}'**
  String maxFileSizeHint(String size);

  /// Error when a masked text isn't complete
  ///
  /// In en, this message translates to:
  /// **'Please enter it as {pattern}'**
  String maskIncomplete(String pattern);
}

class _JsonEditorLocalizationsDelegate
    extends LocalizationsDelegate<JsonEditorLocalizations> {
  const _JsonEditorLocalizationsDelegate();

  @override
  Future<JsonEditorLocalizations> load(Locale locale) {
    return SynchronousFuture<JsonEditorLocalizations>(
      lookupJsonEditorLocalizations(locale),
    );
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
    'that was used.',
  );
}
