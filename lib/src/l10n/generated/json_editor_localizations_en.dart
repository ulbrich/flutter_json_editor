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
  String get selectOptionLabel => 'Select…';

  @override
  String get increaseTooltip => 'Increase';

  @override
  String get decreaseTooltip => 'Decrease';

  @override
  String get undoTooltip => 'Undo';

  @override
  String get signatureHint => 'Sign here';

  @override
  String get hoursLabel => 'Hours';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get invalidDurationFormat => 'Invalid duration';

  @override
  String get choosePictureLabel => 'Choose picture';

  @override
  String get takePhotoLabel => 'Take photo';

  @override
  String get removeImageTooltip => 'Remove picture';

  @override
  String get invalidImageData => 'Invalid image data';

  @override
  String get imagePickFailed => 'The picture could not be loaded';

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
  String get invalidEmailFormat => 'Invalid email address';

  @override
  String get invalidUriFormat => 'Invalid URL';

  @override
  String get invalidDateFormat => 'Invalid date';

  @override
  String get invalidDateTimeFormat => 'Invalid date and time';

  @override
  String get invalidTimeFormat => 'Invalid time';

  @override
  String invalidFormatError(String format) {
    return 'Invalid format: $format';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count not displayed IDs (preserved)',
      one: '+ one not displayed ID (preserved)',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String editorPlaceholder(String type, String path) {
    return 'Editor for $type at $path';
  }

  @override
  String addNestedLabel(String typeName) {
    return 'Add nested $typeName';
  }

  @override
  String get npsLowLabel => 'Not at all likely';

  @override
  String get npsHighLabel => 'Extremely likely';

  @override
  String get moveUpTooltip => 'Move up';

  @override
  String get moveDownTooltip => 'Move down';

  @override
  String get rankingHint =>
      'Drag or use the arrows to put the choices in order';

  @override
  String get dateRangeLabel => 'From – to';

  @override
  String get phoneCountryLabel => 'Country';

  @override
  String get phoneNumberLabel => 'Number';

  @override
  String get invalidPhoneNumber => 'Not a valid phone number for this country';

  @override
  String get wizardBack => 'Back';

  @override
  String get wizardNext => 'Next';

  @override
  String get wizardFinish => 'Finish';

  @override
  String get wizardStepIncomplete =>
      'Please fill in the required fields on this page';

  @override
  String get tabIncomplete => 'Some answers on this tab are missing or invalid';

  @override
  String get calcCycleError => 'This calculation depends on itself';

  @override
  String get chooseFileLabel => 'Choose file';

  @override
  String get replaceFileLabel => 'Replace file';

  @override
  String get removeFileTooltip => 'Remove file';

  @override
  String get unnamedFile => 'Unnamed file';

  @override
  String get filePickFailed => 'The file couldn\'t be read';

  @override
  String get invalidFileData => 'The stored file can\'t be read';

  @override
  String get consentRequired => 'Please agree to continue';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String wizardStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String fileTooLarge(String size) {
    return 'The file is larger than $size';
  }

  @override
  String fileTypeNotAllowed(String types) {
    return 'Only these are allowed: $types';
  }

  @override
  String maxFileSizeHint(String size) {
    return 'Up to $size';
  }

  @override
  String maskIncomplete(String pattern) {
    return 'Please enter it as $pattern';
  }
}
