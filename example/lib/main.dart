import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_json_editor/flutter_json_editor.dart';
// import 'package:http/http.dart' as http;
import 'package:json_schema/json_schema.dart';

import 'l10n/generated/app_localizations.dart';
import 'schemas/example_schema.dart';

/// The locales available in this example app.
const availableLocales = AppLocalizations.supportedLocales;

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Locale _locale = availableLocales.first;

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Editor Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      locale: _locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        JsonEditorLocalizations.delegate,
      ],
      supportedLocales: availableLocales,
      home: EditorPage(
        locale: _locale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}

class EditorPage extends StatefulWidget {
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  const EditorPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  JsonSchema? _schema;
  String? _schemaLocale;
  final _editorKey = GlobalKey<JsonEditorState>();
  dynamic _currentData = {};
  dynamic _lastDiff = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (locale != _schemaLocale) {
      _schemaLocale = locale;
      final schemaData = exampleSchemaMap[locale] ?? exampleSchemaMap['en']!;
      _schema = SchemaUtils.createSchema(
        Map<String, dynamic>.from(schemaData),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_schema == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        actions: [
          DropdownButton<Locale>(
            value: widget.locale,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.language),
            items: [
              for (final loc in availableLocales)
                DropdownMenuItem(
                  value: loc,
                  child: Text(loc.languageCode.toUpperCase()),
                ),
            ],
            onChanged: (loc) {
              if (loc != null) widget.onLocaleChanged(loc);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JsonEditor(
              key: _editorKey,
              schema: _schema!,
              onRefLookup: (refUrl, fieldPath, currentValue) async {
                if (refUrl == 'https://example.com/api/hobbies') {
                  return exampleSchemaHobbyRefLookupResponse[locale] ??
                      exampleSchemaHobbyRefLookupResponse['en']!;
                }

                if (refUrl == 'https://example.com/api/avatars') {
                  return exampleSchemaAvatarRefLookupResponse;
                }

                return null;
              },
              initialData: const {
                'firstName': 'Jane',
                'lastName': 'Doe',
                'favouriteColour': '#ff0000',
                'seating': 'office-a-desk-a5,office-b-desk-c1',
                'contractStartDate': '2023-06-15',
                'lastCheckIn': '2026-03-29T08:30:00Z',
                'preferredMeetingTime': '09:00:00',
                'notes':
                    'This is some Markdown formatted text the user **can not edit**, but might be useful to show in the form... :-)',
              },
              onUpdate: (fullData, diff) {
                setState(() {
                  _currentData = fullData;
                  _lastDiff = diff;
                });
              },
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              AppLocalizations.of(context).cancelledMessage)),
                    );
                  },
                  child: Text(AppLocalizations.of(context).cancelButton),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () {
                    final data = _editorKey.currentState?.currentData;
                    final count = data is Map
                        ? data.length
                        : data is List
                            ? data.length
                            : 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)
                              .savedMessage(count))),
                    );
                  },
                  child: Text(AppLocalizations.of(context).saveButton),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Data preview
            ExpansionTile(
              title: Text(AppLocalizations.of(context).currentDataTitle),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(_currentData),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: Text(AppLocalizations.of(context).lastDiffTitle),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(_lastDiff),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
