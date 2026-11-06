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

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
