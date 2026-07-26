import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema/json_schema.dart';

import 'l10n/generated/app_localizations.dart';

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

  /// Locale-keyed raw schema maps, loaded from JSON assets at startup.
  final Map<String, Map<String, dynamic>> _rawSchemas = {};

  /// The avatar `$ref` lookup response, loaded from a JSON asset. Avatar is a
  /// remote-style `$ref`; hobby now resolves locally via `#/$defs/hobby`.
  Map<String, dynamic>? _avatarLookup;

  @override
  void initState() {
    super.initState();
    _loadSchemas();
  }

  Future<void> _loadSchemas() async {
    Future<Map<String, dynamic>> load(String path) async =>
        jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;

    final en = await load('assets/schemas/en.json');
    final de = await load('assets/schemas/de.json');

    final avatar = await load('assets/schemas/avatar_lookup.json');

    if (!mounted) return;
    setState(() {
      _rawSchemas
        ..['en'] = en
        ..['de'] = de;
      _avatarLookup = avatar;
      _rebuildSchema();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildSchema();
  }

  /// (Re)builds [_schema] for the active locale once the assets are loaded.
  void _rebuildSchema() {
    if (_rawSchemas.isEmpty) return;
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == _schemaLocale && _schema != null) return;
    _schemaLocale = locale;
    final schemaData = _rawSchemas[locale] ?? _rawSchemas['en']!;
    _schema = SchemaUtils.createSchema(Map<String, dynamic>.from(schemaData));
  }

  @override
  Widget build(BuildContext context) {
    if (_schema == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                // Avatar is served from a bundled JSON asset (a static list
                // of dicebear avatars). A real app would fetch this data from
                // your own API.
                if (refUrl == 'https://example.com/api/avatars') {
                  return _avatarLookup;
                }

                // Generic fallback: fetch any real http(s) ref and return the
                // decoded JSON body. The widget itself performs no networking —
                // it relies on this callback to resolve $ref URLs.
                if (refUrl.startsWith('http')) {
                  try {
                    final response = await http.get(Uri.parse(refUrl));
                    if (response.statusCode == 200) {
                      return jsonDecode(response.body) as Map<String, dynamic>;
                    }
                  } catch (_) {
                    // Fall through to null so the editor shows its
                    // "remote schema unavailable" state.
                  }
                  return null;
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
