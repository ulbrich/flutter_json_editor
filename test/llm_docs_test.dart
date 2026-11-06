import 'dart:convert';
import 'dart:io';

import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import 'llm_docs_harness.dart';

/// The generated documents and the lint fixtures are checked in; set
/// `UPDATE_LLM_DOCS=1` to rewrite them after changing the catalog or lint.
final bool _update = Platform.environment['UPDATE_LLM_DOCS'] == '1';

void _generated(String path, String content) {
  final file = File(path);
  if (_update) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
  expect(
    file.existsSync() && file.readAsStringSync() == content,
    isTrue,
    reason:
        '$path is stale: run UPDATE_LLM_DOCS=1 flutter test '
        'test/llm_docs_test.dart',
  );
}

const _forms = ['survey', 'onboarding', 'order', 'inspection'];

Map<String, dynamic> _form(String name) =>
    jsonDecode(File('example/assets/forms/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('generated documents', () {
    test('meta-schema', () {
      _generated(
        'schema/flutter_json_editor.schema.json',
        LlmDocs.metaSchemaText(),
      );
    });
    test('guide', () => _generated('doc/llm-guide.md', LlmDocs.guide()));
    test('llms.txt', () => _generated('llms.txt', LlmDocs.llmsTxt()));
  });

  group('catalog', () {
    test('every built-in format has a descriptor and the other way round', () {
      final described = EditorCatalog.formatNames.toSet();
      expect(EditorRegistryData.builtInFormats.toSet(), described);
    });

    test('every x- keyword the editors read is described', () {
      final read = <String>{};
      for (final file in Directory('lib/src').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.contains('/catalog/') || file.path.contains('/l10n/')) {
          continue;
        }
        for (final m in RegExp(
          r"'(x-[a-z-]+)'",
        ).allMatches(file.readAsStringSync())) {
          read.add(m.group(1)!);
        }
      }
      read.removeAll(['x-enum-source', 'x-remote-ref']);
      expect(
        read.difference({for (final k in EditorCatalog.keywords) k.name}),
        isEmpty,
      );
    });

    for (final d in [...EditorCatalog.formats, ...EditorCatalog.layouts]) {
      test('the example of ${d.name} lints clean', () {
        expect(SchemaLint.check(wrapField(d.example)), isEmpty);
      });
      testWidgets('the example of ${d.name} renders', (tester) async {
        await pumpForm(tester, wrapField(d.example));
        expect(tester.takeException(), isNull);
      });
    }

    test('every lint code is documented', () {
      final codes = {for (final (c, _) in LlmDocs.lintCodes) c};
      final source = File('lib/src/schema_lint.dart').readAsStringSync();
      final used = {
        for (final m in RegExp(
          r"(?:error|warning)\(\s*[\w.]+,\s*'([a-z-]+)'",
        ).allMatches(source))
          m.group(1)!,
      }..removeWhere((c) => c.startsWith('x-'));
      expect(used, codes);
    });
  });

  group('lint fixtures', () {
    const path = 'test/fixtures/lint_cases.json';
    final cases = (jsonDecode(File(path).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> run(Map<String, dynamic> c) {
      final options = (c['options'] as Map?) ?? const {};
      return [
        for (final issue in SchemaLint.check(
          c['schema'] as Map<String, dynamic>,
          formats: {...?(options['formats'] as List?)?.cast<String>()},
          keywords: {...?(options['keywords'] as List?)?.cast<String>()},
        ))
          issue.toJson(),
      ];
    }

    if (_update) {
      test('write expectations', () {
        final out = [
          for (final c in cases) {...c, 'issues': run(c)},
        ];
        File(path).writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(out)}\n',
        );
      });
    }

    for (final c in cases) {
      test(c['name'], () {
        expect(run(c), c['issues'] ?? const []);
      });
    }
  });

  group('example forms', () {
    final meta = JsonSchema.create(LlmDocs.metaSchema());

    for (final name in _forms) {
      test('$name lints clean', () {
        expect(SchemaLint.check(_form(name)), isEmpty);
      });
      test('$name validates against the meta-schema', () {
        final result = meta.validate(_form(name));
        expect(result.errors, isEmpty);
      });
      testWidgets('$name renders', (tester) async {
        await pumpForm(tester, _form(name));
        expect(tester.takeException(), isNull);
      });
    }

    test('the meta-schema rejects wrong keyword types', () {
      for (final field in [
        {'type': 'string', 'x-hidden': 'yes'},
        {'type': 'string', 'x-format': 'rating'},
        {'type': 'object', 'x-layout': 'grid'},
        {'type': 'string', 'x-format': 'file-data', 'x-accept': 'pdf'},
      ]) {
        expect(
          meta.validate(wrapField(field)).isValid,
          isFalse,
          reason: '$field',
        );
      }
    });
  });

  test('the order form computes its totals', () {
    final schema = SchemaUtils.createSchema(_form('order'));
    final result = FormCalculator.apply(schema, {
      'customer': 'Ada',
      'discount': 10,
      'items': [
        {'product': 'A', 'qty': 2, 'price': 5},
        {'product': 'B', 'qty': 1, 'price': 10},
      ],
    });
    final data = result.data as Map;
    expect((data['items'] as List).first['sum'], 10);
    expect([data['net'], data['vat'], data['gross']], [18, 3.42, 21.42]);
    expect(data['summary'], '2 items for Ada');
  });
}
