import 'dart:convert';

import 'editor_catalog.dart';

/// The generated documents for LLMs (and people): the meta-schema,
/// `doc/llm-guide.md` and `llms.txt`. `test/llm_docs_test.dart` writes them
/// (`UPDATE_LLM_DOCS=1`) and fails when they are stale.
class LlmDocs {
  LlmDocs._();

  static const metaSchemaId =
      'https://github.com/safenow/flutter_json_editor/schema/flutter_json_editor.schema.json';

  static const _json = JsonEncoder.withIndent('  ');

  static String _pretty(dynamic value) => _json.convert(value);

  static Map<String, dynamic> _keywordSchema(KeywordDescriptor k) {
    final description = k.description;
    if (k.name == 'x-format') {
      return {
        'description': description,
        'type': 'string',
        'enum': EditorCatalog.formatNames,
      };
    }
    if (k.name == 'x-layout') {
      return {
        'description': description,
        'enum': [for (final d in EditorCatalog.layouts) d.name],
      };
    }
    return {
      'description': description,
      ...switch (k.type) {
        KeywordType.string => {'type': 'string'},
        KeywordType.boolean => {'type': 'boolean'},
        KeywordType.integer => {'type': 'integer'},
        KeywordType.number => {'type': 'number'},
        KeywordType.stringList => {
          'type': 'array',
          'items': {'type': 'string'},
        },
        KeywordType.any => <String, dynamic>{},
      },
    };
  }

  /// A draft-07 schema that validates form schemas: the standard keywords
  /// these editors read, recursively, and every `x-` keyword with its type
  /// and what it does. `x-catalog` holds the rules [SchemaLint] uses, for
  /// linters in other languages.
  static Map<String, dynamic> metaSchema() {
    const node = {r'$ref': '#/definitions/node'};
    const nodes = {'type': 'array', 'items': node};
    const nodeMap = {'type': 'object', 'additionalProperties': node};
    return {
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      r'$id': metaSchemaId,
      'title': 'flutter_json_editor form schema',
      'description':
          'A JSON Schema (draft-07) that flutter_json_editor renders as a '
          'form. The root is an object; `type` and `x-format` pick each '
          'field\'s editor, `x-layout` lays out objects. See '
          'doc/llm-guide.md. Validating against this schema checks keyword '
          'types; SchemaLint also checks that editors fit their fields.',
      'allOf': [node],
      'definitions': {
        'node': {
          'type': ['object', 'boolean'],
          'properties': {
            'type': {
              'anyOf': [
                {r'$ref': '#/definitions/typeName'},
                {
                  'type': 'array',
                  'items': {r'$ref': '#/definitions/typeName'},
                },
              ],
            },
            'title': {
              'type': 'string',
              'description': 'The label. `{{path}}` shows an answer (piping).',
            },
            'description': {
              'type': 'string',
              'description': 'Help text under the field. Piping works.',
            },
            'properties': nodeMap,
            'required': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'items': {
              'anyOf': [node, nodes],
            },
            'enum': {'type': 'array'},
            'allOf': nodes,
            'anyOf': nodes,
            'oneOf': nodes,
            'not': node,
            'if': node,
            'then': node,
            'else': node,
            'dependencies': {
              'type': 'object',
              'additionalProperties': {
                'anyOf': [
                  node,
                  {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                ],
              },
            },
            'additionalProperties': node,
            'definitions': nodeMap,
            r'$defs': nodeMap,
            'readOnly': {'type': 'boolean'},
            for (final k in EditorCatalog.keywords) k.name: _keywordSchema(k),
          },
        },
        'typeName': {
          'enum': [
            'string',
            'number',
            'integer',
            'boolean',
            'object',
            'array',
            'null',
          ],
        },
      },
      'x-catalog': EditorCatalog.toJson(),
    };
  }

  /// [metaSchema] as the file's text.
  static String metaSchemaText() => '${_pretty(metaSchema())}\n';

  static String _types(EditorDescriptor d) =>
      d.types == null ? 'any type' : d.types!.map((t) => '`$t`').join(', ');

  static const _requirementText = {
    EditorRequirement.choices:
        'choices (an `enum`, or a `oneOf` of `const` branches)',
    EditorRequirement.itemChoices: 'choices on `items`',
    EditorRequirement.rowChoices: 'properties with choices, one per row',
    EditorRequirement.constChoices: 'a `oneOf` of `const` branches',
    EditorRequirement.svgAsset: 'an `x-svg-asset`',
  };

  static void _entry(StringBuffer out, EditorDescriptor d, String keyword) {
    final aliases = d.aliases.isEmpty
        ? ''
        : ' (also `${d.aliases.join('`, `')}`)';
    out
      ..writeln('### `$keyword: "${d.name}"` — ${d.title}$aliases')
      ..writeln()
      ..writeln('- **Use for:** ${d.useFor}')
      ..writeln(
        '- **Applies to:** ${_types(d)}'
        '${d.requires == null ? '' : ', with ${_requirementText[d.requires]}'}'
        '${d.steps == null ? '' : '; ${d.steps!.min} to ${d.steps!.max} steps, default ${d.steps!.defaultMin}–${d.steps!.defaultMax}'}.',
      );
    if (d.keys.isNotEmpty) {
      out.writeln('- **Keys:**');
      for (final e in d.keys.entries) {
        out.writeln('  - `${e.key}`: ${e.value}');
      }
    }
    out.writeln('- **Stores:** ${d.stores}');
    for (final dont in d.dont) {
      out.writeln('- **Don\'t:** $dont');
    }
    out
      ..writeln()
      ..writeln('```json')
      ..writeln(_pretty(d.example))
      ..writeln('```')
      ..writeln();
  }

  /// Which editor for which question.
  static const List<(String, String)> decisions = [
    ('Short text', '`string`'),
    ('Long text', '`string` + `x-format: textarea`'),
    ('Formatted text, instructions', '`string` + `x-format: markdown`'),
    ('Code, IBAN, licence plate', '`string` + `x-mask`'),
    ('Email, URL', '`string` + `format: email` / `uri`'),
    ('Phone number', '`string` + `x-format: phone`'),
    ('Number, amount, weight', '`number` (+ `x-unit` / `x-currency`)'),
    ('Small count', '`integer` + `x-format: stepper`'),
    ('Rough amount in a range', '`number` + `x-format: slider`'),
    ('Yes / no', '`boolean`'),
    ('Accept terms', '`boolean` + `x-format: consent` + `const: true`'),
    ('One of many', '`enum` or `oneOf` of `const`s (a dropdown)'),
    ('One of two to five', 'the same + `x-format: segmented`'),
    (
      'One of several pictures',
      '`oneOf` with `x-image` + `x-format: image-choice`',
    ),
    ('Several of a list', '`array` of choices + `x-format: chips`'),
    ('Order of preference', '`array` of choices + `x-format: ranking`'),
    ('Rating 1–5 or 1–10', '`integer` + `x-format: linear-scale`'),
    ('Mood, satisfaction', '`integer` + `x-format: emoji-scale`'),
    ('Recommend us? (0–10)', '`integer` + `x-format: nps`'),
    ('Stars', '`integer` + `x-format: star-rating`'),
    ('Same choices for several rows', '`object` + `x-format: matrix`'),
    ('Day / time / moment', '`string` + `format: date` / `time` / `date-time`'),
    ('From … to …', '`object` or `string` + `x-format: date-range`'),
    ('How long', '`string` + `format: duration`'),
    ('Colour', '`string` + `x-format: colour`'),
    ('Photo(s)', '`string` / `array` + `x-format: image-data`'),
    ('Documents', '`string` / `array` + `x-format: file-data`'),
    ('Signature', '`string` + `x-format: signature`'),
    ('Regions of a picture', '`array` + `x-format: svg-part-picker`'),
    ('A computed total', 'any type + `x-calc`'),
    ('A value nobody edits', 'any type + `x-hidden: true`'),
    ('A list of entries', '`array` of `object`s'),
    ('A long form step by step', '`object` + `x-layout: wizard`'),
    ('Groups in any order', '`object` + `x-layout: tabs`'),
    ('Optional details', '`object` + `x-layout: collapsible`'),
  ];

  static const List<(String, String)> lintCodes = [
    ('unknown-format', 'error'),
    ('format-type', 'error'),
    ('format-choices', 'error'),
    ('scale-range', 'error'),
    ('scale-labels', 'warning'),
    ('large-data', 'warning'),
    ('keyword-type', 'error'),
    ('keyword-unused', 'warning'),
    ('unknown-keyword', 'warning'),
    ('layout-value', 'error'),
    ('layout-type', 'error'),
    ('layout-pages', 'warning'),
    ('calc-operator', 'error'),
    ('calc-var', 'warning'),
    ('calc-cycle', 'error'),
    ('pipe-unknown', 'warning'),
  ];

  /// `doc/llm-guide.md`: how to write a form schema, one entry per editor.
  static String guide() {
    final out = StringBuffer()
      ..writeln('# Writing forms for flutter_json_editor')
      ..writeln()
      ..writeln(
        '<!-- Generated from lib/src/catalog/editor_catalog.dart by '
        '`UPDATE_LLM_DOCS=1 flutter test test/llm_docs_test.dart`. '
        'Don\'t edit by hand. -->',
      )
      ..writeln()
      ..writeln(
        'A form is a JSON Schema (draft-07) object. Each property is a '
        'field; its `type` picks a default editor, `x-format` a special '
        'one, and `x-layout` lays out an object. This guide lists every '
        'editor with when to use it, what it needs, what it stores and a '
        'minimal example. The meta-schema '
        '[`schema/flutter_json_editor.schema.json`](../schema/flutter_json_editor.schema.json) '
        'validates keyword types; `SchemaLint.check(schema)` finds what '
        'renders differently than meant.',
      )
      ..writeln()
      ..writeln('## Rules')
      ..writeln()
      ..writeln(
        '1. The root is `{"type": "object", "properties": {…}}`; put '
        'mandatory fields in `required`.',
      )
      ..writeln(
        '2. Give every field a `title` (the label) and, where it helps, a '
        '`description`.',
      )
      ..writeln(
        '3. For choices whose labels differ from the stored values use '
        '`"oneOf": [{"const": "de", "title": "Germany"}, …]`; otherwise an '
        '`enum`.',
      )
      ..writeln(
        '4. Every `x-format` needs the type its entry lists. A mismatch '
        'doesn\'t fail: the field silently falls back to a default editor.',
      )
      ..writeln(
        '5. Photos and files are stored in the data as base64. Limit them '
        '(`x-max-width`, `x-max-file-size`, `maxItems`).',
      )
      ..writeln(
        '6. Run `SchemaLint.check(schema)` (or the meta-schema) and fix '
        'every error before using the form; each message says how.',
      )
      ..writeln()
      ..writeln('## Without `x-format`')
      ..writeln()
      ..writeln('| Schema | Editor |')
      ..writeln('|---|---|')
      ..writeln(
        '| `string` | text field (`minLength`, `maxLength`, `pattern`) |',
      )
      ..writeln('| `string` + `enum` / `oneOf` of `const`s | dropdown |')
      ..writeln(
        '| `number`, `integer` | number field (`minimum`, `maximum`, `x-unit`, `x-currency`) |',
      )
      ..writeln('| `boolean` | switch |')
      ..writeln('| `object` | card with its properties (`x-layout`) |')
      ..writeln(
        '| `array` | list with add, remove, reorder (`minItems`, `maxItems`) |',
      )
      ..writeln('| `readOnly: true` | shown, not editable |')
      ..writeln('| `default` | the value of a new form |')
      ..writeln(
        '| `if`/`then`/`else`, `dependencies` | fields that appear with an answer |',
      )
      ..writeln('| `\$ref` to `#/definitions/…` | reused parts |')
      ..writeln()
      ..writeln('## Which editor?')
      ..writeln()
      ..writeln('| Question | Schema |')
      ..writeln('|---|---|');
    for (final (q, s) in decisions) {
      out.writeln('| $q | $s |');
    }
    out
      ..writeln()
      ..writeln('## Editors')
      ..writeln();
    for (final d in EditorCatalog.formats) {
      _entry(out, d, 'x-format');
    }
    out
      ..writeln('## Layouts')
      ..writeln()
      ..writeln(
        '`x-layout` on an object. `wizard` and `tabs` make each property a '
        'page; give the pages object schemas with titles.',
      )
      ..writeln();
    for (final d in EditorCatalog.layouts) {
      _entry(out, d, 'x-layout');
    }
    out
      ..writeln('## Form logic')
      ..writeln()
      ..writeln(
        '- **Hidden fields:** `"x-hidden": true` keeps a value in the data '
        'but never shows it.',
      )
      ..writeln(
        '- **Calculated fields:** `"x-calc"` is a [JSON Logic](https://jsonlogic.com) '
        'rule; its result is the field\'s value, shown read-only. '
        '`{"var": "order.qty"}` reads from the root, `{"var": ".qty"}` from '
        'the object holding the field (use this inside array items). '
        'Calculations may read other calculations, but not in a circle. '
        'Operators: ${EditorCatalog.calcOperators.map((o) => '`$o`').join(' ')}.',
      )
      ..writeln(
        '- **Piping:** `{{path}}` in a `title` or `description` shows an '
        'answer, `{{.key}}` one of the same object.',
      )
      ..writeln(
        '- **Conditional fields:** `if`/`then`/`else` or `dependencies` add '
        'properties when an answer matches.',
      )
      ..writeln()
      ..writeln('```json')
      ..writeln(
        _pretty({
          'type': 'object',
          'properties': {
            'items': {
              'type': 'array',
              'title': 'Items',
              'items': {
                'type': 'object',
                'properties': {
                  'qty': {'type': 'integer', 'title': 'Qty'},
                  'price': {'type': 'number', 'title': 'Price'},
                  'sum': {
                    'type': 'number',
                    'title': 'Sum',
                    'x-calc': {
                      '*': [
                        {'var': '.qty'},
                        {'var': '.price'},
                      ],
                    },
                  },
                },
              },
            },
            'total': {
              'type': 'number',
              'title': 'Total',
              'x-currency': 'EUR',
              'x-calc': {
                'reduce': [
                  {'var': 'items'},
                  {
                    '+': [
                      {'var': 'accumulator'},
                      {'var': 'current.sum'},
                    ],
                  },
                  0,
                ],
              },
            },
          },
        }),
      )
      ..writeln('```')
      ..writeln()
      ..writeln('## Keywords')
      ..writeln()
      ..writeln('| Keyword | Value | Works on | What it does |')
      ..writeln('|---|---|---|---|');
    for (final k in EditorCatalog.keywords) {
      final on = [
        ...?k.on?.map(
          (e) => switch (e) {
            'text' => 'text fields',
            'number' => 'number fields',
            'object' => 'objects',
            _ => '`$e`',
          },
        ),
        ...?k.layouts?.map((l) => '`x-layout: $l`'),
      ];
      out.writeln(
        '| `${k.name}` | ${k.typeName} | ${on.isEmpty ? 'any field' : on.join(', ')} | ${k.description} |',
      );
    }
    out
      ..writeln()
      ..writeln('## Data size')
      ..writeln()
      ..writeln(
        '`image-data` and `file-data` store the file in the form\'s data as '
        'base64 (a third larger than the file). Scale photos with '
        '`x-max-width`/`x-max-height` (1024 is plenty for documentation, '
        '`x-image-quality` 70–85), cap files with `x-max-file-size` (default '
        '5 MiB) and arrays with `maxItems`. Prefer one or two small files '
        'per field; for many or large files store links instead.',
      )
      ..writeln()
      ..writeln('## Checking a schema')
      ..writeln()
      ..writeln(
        '`SchemaLint.check(schema)` returns issues with a JSON Pointer '
        '`path`, a `code`, a `severity` and a `message` that says how to '
        'fix it. Errors render differently than meant; warnings are likely '
        'mistakes. Fix, check again, repeat until no errors remain.',
      )
      ..writeln()
      ..writeln('| Code | Severity |')
      ..writeln('|---|---|');
    for (final (code, severity) in lintCodes) {
      out.writeln('| `$code` | $severity |');
    }
    out
      ..writeln()
      ..writeln(
        'Complete examples: `example/assets/forms/` (survey, onboarding '
        'wizard, order with calculations, inspection with photos and '
        'signature).',
      );
    return out.toString();
  }

  /// `llms.txt` (see llmstxt.org): what the package is and where to read on.
  static String llmsTxt() {
    final out = StringBuffer()
      ..writeln('# flutter_json_editor')
      ..writeln()
      ..writeln(
        '> A Flutter widget that renders JSON Schema (draft-07) as forms. '
        'The schema\'s `type` picks a default editor per field, `x-format` '
        'a special one (${EditorCatalog.formats.length} editors: scales, '
        'chips, photos, signatures, …), `x-layout` lays out objects '
        '(cards, tabs, wizards), `x-calc` computes values.',
      )
      ..writeln()
      ..writeln(
        'To generate a form: read the guide, write a schema, check it with '
        '`SchemaLint.check(schema)` (or validate it against the '
        'meta-schema) and fix every error.',
      )
      ..writeln()
      ..writeln('## Docs')
      ..writeln()
      ..writeln(
        '- [Guide for writing forms](doc/llm-guide.md): rules, which editor '
        'for which question, every editor with keys, stored value and '
        'example',
      )
      ..writeln(
        '- [Meta-schema](schema/flutter_json_editor.schema.json): validates '
        'form schemas; `x-catalog` holds the lint rules as data',
      )
      ..writeln('- [README](README.md): the widget\'s API for app developers')
      ..writeln()
      ..writeln('## Editors')
      ..writeln();
    for (final d in EditorCatalog.formats) {
      out.writeln(
        '- `x-format: ${d.name}` — ${d.title}: ${d.useFor.split('. ').first.replaceAll(RegExp(r'\.$'), '')}',
      );
    }
    for (final d in EditorCatalog.layouts) {
      out.writeln(
        '- `x-layout: ${d.name}` — ${d.title}: ${d.useFor.split('. ').first.replaceAll(RegExp(r'\.$'), '')}',
      );
    }
    out
      ..writeln()
      ..writeln('## Examples')
      ..writeln()
      ..writeln('- [Survey](example/assets/forms/survey.json)')
      ..writeln('- [Onboarding wizard](example/assets/forms/onboarding.json)')
      ..writeln('- [Order with calculations](example/assets/forms/order.json)')
      ..writeln(
        '- [Inspection with photos and signature](example/assets/forms/inspection.json)',
      );
    return out.toString();
  }
}
