import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'format_support.dart';

/// An international phone number: a country (with its calling code) and
/// the number within it, activated by `"x-format": "phone"` on a `string`:
///
/// ```json
/// {"type": "string", "title": "Mobile", "x-format": "phone",
///  "x-default-country": "DE", "x-countries": ["DE", "AT", "CH"]}
/// ```
///
/// The value is the number in E.164 form, `+4915112345678`, whatever spaces
/// or leading zero were typed. Numbers that don't exist in the chosen
/// country (by the numbering plans of `phone_numbers_parser`) show an
/// error. The country starts as the stored number's, else
/// `x-default-country`, else the app's locale's; `x-countries` limits the
/// list. A schema that isn't a string renders with the editor it would get
/// without the `x-format`.
class PhoneEditor extends SchemaFieldEditor {
  const PhoneEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// The calling code of [country], without the plus.
  static String callingCode(IsoCode country) =>
      PhoneNumber(isoCode: country, nsn: '').countryCode;

  /// [number] parsed as E.164 (or as a national number of [country]); null
  /// when it can't be.
  static PhoneNumber? parse(String? number, {IsoCode? country}) {
    if (number == null || number.trim().isEmpty) return null;
    try {
      return PhoneNumber.parse(number, destinationCountry: country);
    } catch (_) {
      return null;
    }
  }

  @override
  State<PhoneEditor> createState() => _PhoneEditorState();
}

class _PhoneEditorState extends State<PhoneEditor> {
  final TextEditingController _controller = TextEditingController();
  IsoCode? _country;

  /// The value this editor emitted last, so its own echo isn't parsed again.
  String? _emitted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_country == null) _load(widget.value);
  }

  @override
  void didUpdateWidget(PhoneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _emitted) {
      _load(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<IsoCode> get _countries {
    final raw = widget.schema.schemaMap?['x-countries'];
    final allowed = raw is List
        ? {
            for (final c in raw)
              for (final code in IsoCode.values)
                if (code.name == '$c'.toUpperCase()) code,
          }
        : null;
    final list = allowed == null || allowed.isEmpty
        ? IsoCode.values.toList()
        : allowed.toList();
    return list..sort((a, b) => a.name.compareTo(b.name));
  }

  IsoCode? _code(dynamic name) {
    if (name is! String) return null;
    for (final code in IsoCode.values) {
      if (code.name == name.toUpperCase()) return code;
    }
    return null;
  }

  IsoCode _defaultCountry() {
    final countries = _countries;
    final candidates = [
      _code(widget.schema.schemaMap?['x-default-country']),
      _code(Localizations.maybeLocaleOf(context)?.countryCode),
    ];
    for (final c in candidates) {
      if (c != null && countries.contains(c)) return c;
    }
    return countries.contains(IsoCode.US) ? IsoCode.US : countries.first;
  }

  void _load(dynamic value) {
    final parsed = PhoneEditor.parse(value is String ? value : null);
    _country = parsed?.isoCode ?? _country ?? _defaultCountry();
    final text = parsed == null
        ? (value is String ? value : '')
        : parsed.formatNsn();
    if (_controller.text != text) _controller.text = text;
  }

  void _emit() {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      _emitted = null;
      widget.onChanged(null);
      return;
    }
    final country = _country ?? _defaultCountry();
    final parsed = digits.startsWith('+')
        ? PhoneEditor.parse(digits)
        : PhoneEditor.parse(digits, country: country);
    _emitted =
        parsed?.international ??
        '+${PhoneEditor.callingCode(country)}${digits.replaceAll('+', '')}';
    widget.onChanged(_emitted);
  }

  @override
  Widget build(BuildContext context) {
    if (!schemaTypeNames(widget.schema).contains('string')) {
      return editorWithoutFormat(
        context,
        format: 'phone',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final readOnly = widget.schema.readOnly == true;
    final country = _country ?? _defaultCountry();
    final value = widget.value is String ? widget.value as String : null;
    final parsed = PhoneEditor.parse(value);
    final invalid =
        value != null &&
        value.isNotEmpty &&
        (parsed == null || !parsed.isValid());
    final errors = value == null
        ? const <String>[]
        : ValidationHelper.validateField(widget.schema, value);

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      errorText: invalid
          ? l10n.invalidPhoneNumber
          : localizeFirstValidationError(l10n, errors),
      onClear: value != null && !readOnly && widget.isNullable
          ? () {
              _controller.clear();
              _emitted = null;
              widget.onChanged(null);
            }
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownMenu<IsoCode>(
            key: const ValueKey('phone-country'),
            width: 132,
            enabled: !readOnly,
            initialSelection: country,
            enableFilter: true,
            requestFocusOnTap: true,
            menuHeight: 320,
            label: Text(l10n.phoneCountryLabel),
            dropdownMenuEntries: [
              for (final c in _countries)
                DropdownMenuEntry<IsoCode>(
                  value: c,
                  label: '${c.name} +${PhoneEditor.callingCode(c)}',
                ),
            ],
            onSelected: (c) {
              if (c == null) return;
              setState(() => _country = c);
              if (_controller.text.isNotEmpty) _emit();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('phone-number'),
              controller: _controller,
              enabled: !readOnly,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s/]')),
              ],
              decoration: InputDecoration(labelText: l10n.phoneNumberLabel),
              onChanged: (_) => _emit(),
            ),
          ),
        ],
      ),
    );
  }
}
