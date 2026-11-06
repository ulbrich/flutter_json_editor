# flutter_json_editor

A Flutter widget that renders JSON Schema (draft-07) as forms: `JsonEditor(schema:, initialData:, onUpdate:)`. The README is the user documentation; `doc/llm-guide.md` documents every editor for LLMs.

## Branches

- `develop`: built on [`material_ui`](https://pub.dev/packages/material_ui) (`import 'package:material_ui/material_ui.dart'`), Dart ^3.13.
- `renderer/material` (worktree `../flutter_json_editor-material`): the same package on Flutter's `package:flutter/material.dart`, Dart >=3.0.

Every feature goes to both. Port by copying files and swapping the import (`sed 's#package:material_ui/material_ui.dart#package:flutter/material.dart#'`). On `renderer/material`: no null-aware collection elements (`[?x]`), tests import `flutter_localizations` for `GlobalMaterialLocalizations`, and `lib/flutter_json_editor.dart` and `pubspec.yaml` are kept by hand. README and CLAUDE.md differ only in the branch notes.

## Layout

- `lib/src/json_editor.dart`: the widget; `schema_resolver.dart` picks an editor per field; `editor_registry.dart` maps `x-format` (else the standard `format`) to builders in `_builtInFormatOverrides`.
- `lib/src/editors/`: one `SchemaFieldEditor` per file. Helpers in `format_support.dart` (`schemaTypeNames`, `choicesOf`, `fieldLabel`). An editor that can't handle its schema renders `editorWithoutFormat(...)` instead of failing.
- `lib/src/editors/object_editor.dart`: objects and `x-layout` (card, collapsible, plain, wizard, tabs).
- `lib/src/form_logic.dart`, `json_logic.dart`, `input_mask.dart`: `x-hidden`, `x-calc` (own JSON Logic evaluator, pure Dart), piping, `x-mask`.
- `lib/src/catalog/editor_catalog.dart`: every editor, layout and `x-` keyword as data. `llm_docs.dart` generates `doc/llm-guide.md`, `llms.txt` and `schema/flutter_json_editor.schema.json` from it. `lib/src/schema_lint.dart` checks schemas against it. All three are pure Dart (no Flutter), used by servers too.
- `lib/src/l10n/`: ARB files (en, de) → `generated/` via `flutter gen-l10n`.
- `example/`: demo app (`assets/schemas/{en,de}.json`, `assets/forms/` complete forms); `example/screenshots/` writes `doc/images/`.

## Commands

```sh
flutter test                                   # package tests
flutter analyze                                # baseline: 14 issues on develop, 8 on renderer/material (pre-existing)
flutter gen-l10n                               # after editing an ARB file
UPDATE_LLM_DOCS=1 flutter test test/llm_docs_test.dart   # regenerate guide, llms.txt, meta-schema, lint fixtures
cd example && flutter test && flutter test screenshots   # example tests; screenshots → doc/images
```

Flutter commands need to run outside the command sandbox.

## Adding or changing an editor

1. The editor in `lib/src/editors/`, registered in `_builtInFormatOverrides`, exported from `lib/flutter_json_editor.dart`.
2. Its entry in `EditorCatalog` (types, requirements, keys, stores, example, mistakes) and its keywords; lint rules come from there.
3. Strings in both ARB files; tests in `test/editors/`; a section and screenshot in the README; the example schemas.
4. `UPDATE_LLM_DOCS=1 flutter test test/llm_docs_test.dart`. It fails until every built-in format has an entry, every example lints clean and renders, and the generated files are current.
5. The same on the other branch.

`test/fixtures/lint_cases.json` (schema → expected issues) is shared with other linters (TEAMnews' backend keeps a copy); after changing a lint message, regenerate it and tell them.

