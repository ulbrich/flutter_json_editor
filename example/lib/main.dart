import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_json_editor/flutter_json_editor.dart';
// import 'package:http/http.dart' as http;
import 'package:json_schema/json_schema.dart';

import 'schemas/example_schema.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Editor Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final JsonSchema _schema;
  final _editorKey = GlobalKey<JsonEditorState>();
  dynamic _currentData = {};
  dynamic _lastDiff = {};

  @override
  void initState() {
    super.initState();
    _schema = SchemaUtils.createSchema(
      Map<String, dynamic>.from(exampleSchemaMap),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSON Editor Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form editor with key bindinng and callbacks to process the data
            // and e.g. $ref lookups. Custom editors can be injected via the
            // registry, either globally or for specific paths and formats.
            JsonEditor(
              key: _editorKey,
              schema: _schema,
              // registry: EditorRegistryData(
              //   pathOverrides: {
              //     'someProperty': ({
              //       required JsonSchema schema,
              //       required String path,
              //       required dynamic value,
              //       required void Function(dynamic value) onChanged,
              //       required bool isRequired,
              //       bool isNullable = false,
              //     }) =>
              //         SomeEditor(
              //           schema: schema,
              //           path: path,
              //           value: value,
              //           onChanged: onChanged,
              //           isRequired: isRequired,
              //           isNullable: isNullable,
              //         ),
              //   },
              //   formatOverrides: {
              //     'someFormat': ({
              //       required JsonSchema schema,
              //       required String path,
              //       required dynamic value,
              //       required void Function(dynamic value) onChanged,
              //       required bool isRequired,
              //       bool isNullable = false,
              //     }) =>
              //         AnotherEditor(
              //           schema: schema,
              //           path: path,
              //           value: value,
              //           onChanged: onChanged,
              //           isRequired: isRequired,
              //           isNullable: isNullable,
              //         ),
              //   },
              // ),
              onRefLookup: (refUrl, fieldPath, currentValue) async {
                // Add your logic here to fetch data based on the `refUrl`. You
                // might want to add headers for authentication or e.g. replace
                // placeholders in the URL with other context information. For
                // example you could replace `{postId}` in an URL like
                // `https://example.com/api/posts/{postId}/comments`.
                //
                // final token = 'your_api_token_here';
                // final postId = '21ed40f5-d8e6-4a9a-92b7-e5a3d4834447';
                //
                // final response = await http.get(
                //   Uri.parse(refUrl.replaceAll('{postId }', postId)),
                //   headers: {'Authorization': 'Bearer $token'},
                // );
                // final data = jsonDecode(response.body) as Map<String, dynamic>;

                if (refUrl == 'https://example.com/api/hobbies') {
                  return exampleSchemaHobbyRefLookupResponse;
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

            // Buttons — external, below the form
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Cancelled')));
                  },
                  child: const Text('Cancel'),
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
                      SnackBar(content: Text('Saved: $count items')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Data preview below the buttons
            ExpansionTile(
              title: const Text('Current Data'),
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
              title: const Text('Last Diff'),
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
