# Flutter JSON Editor

A Flutter widget that dynamically generates interactive forms from [JSON Schema (Draft 7)](https://json-schema.org/draft-07). Drop in a schema, get a fully functional form — with validation, nested objects, arrays, conditional fields, and more.

**Warning:** This sideproject was implemented mainly using AI tools. Use it with a grain
of more salt than any other open source project.

## The Idea

Building forms by hand is tedious. Building forms that mirror a complex, evolving data model is worse. JSON Schema already describes your data structure, constraints, and validation rules — so why not let the schema *be* the form?

Obviously this is nothing new and we took inspiration from the Javascript [JSON Editor](https://github.com/json-editor/json-editor) project we successfully used in web projects back in time. We wanted to have that for a long time in Flutter and the raise of AI tools
gave us the help we needed.

**Flutter JSON Editor** takes a JSON Schema and renders a complete, editable form widget. When the user changes a value, you get the full data object *and* a precise diff of what changed. No form-builder boilerplate, no manual field wiring — just schema in, data out.

## Features

- **Full type coverage** — String, number, integer, boolean, enum, object, array, and map editors out of the box
- **Nested structures** — Objects within objects, arrays of objects, maps with dynamic keys
- **Conditional fields** — `if`/`then`/`else` branches show and hide fields based on data state
- **Property dependencies** — Fields that appear or become required based on other field values
- **Composition** — `oneOf` and `anyOf` with automatic variant detection
- **Inline validation** — Field-level error messages derived from schema constraints
- **Remote `$ref` resolution** — Async lookup for external schema references with caching, dropdown or typeahead based on result count
- **Diff tracking** — `DiffCalculator` reports only the paths that changed between updates
- **Theming** — `JsonEditorTheme` extension integrates with your Material 3 theme
- **Custom editors** — `EditorRegistry` lets you override any field by path, type, or predicate
- **Circular reference protection** — Self-referential schemas are safely capped at a configurable depth

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_json_editor:
    git:
      url: https://github.com/safenow/flutter_json_editor.git
```

## Basic Usage

```dart
import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:json_schema/json_schema.dart';

final schema = JsonSchema.create({
  'type': 'object',
  'properties': {
    'name': {'type': 'string'},
    'age': {'type': 'integer', 'minimum': 0},
    'active': {'type': 'boolean', 'default': true},
  },
  'required': ['name'],
});

JsonEditor(
  schema: schema,
  initialData: {'name': 'Jane', 'age': 30},
  onUpdate: (data, diff) {
    print('Full data: $data');
    print('Changed: $diff');
  },
)
```

## How It Works

### Schema Resolution

When the widget builds, `SchemaResolver` walks the schema and picks the right editor for each field. The resolution order is:

1. **Registry overrides** — your custom editors (by path, predicate, or type)
2. **Remote `$ref`** — URL references resolved via async callback
3. **`$ref` resolution** — local references followed (with circular depth protection)
4. **Composition** — `oneOf`/`anyOf` render a variant selector
5. **Enum** — enumerated values render a dropdown
6. **Type** — matched to the corresponding editor widget
7. **Structural fallback** — properties present → object editor; additionalProperties → map editor
8. **Default** — falls back to a string input

### Data Flow

```
JsonEditor
  ├── Wraps children with EditorRegistry + RefLookupProvider
  └── Calls SchemaResolver.resolve() for the root schema
        └── Returns the appropriate editor widget

Each editor:
  ├── Renders its input controls
  ├── Validates via ValidationHelper
  └── Calls onChanged(updatedValue) on user input

JsonEditor._onRootChanged()
  ├── Stores updated data
  ├── Computes diff via DiffCalculator
  └── Fires onUpdate(fullData, diff)
```

### Reading Current Data

Use a `GlobalKey` to access the editor state at any time:

```dart
final editorKey = GlobalKey<JsonEditorState>();

// Later…
final currentData = editorKey.currentState?.currentData;
```

## Theming

Apply a `JsonEditorTheme` via your app's `ThemeData`:

```dart
ThemeData(
  extensions: [
    JsonEditorTheme(
      fieldSpacing: 4.0,
      sectionSpacing: 8.0,
      fieldPadding: const EdgeInsets.symmetric(vertical: 2.0),
      requiredIndicatorColor: Colors.red,
    ),
  ],
)
```

If no theme extension is provided, sensible defaults are derived from your Material theme.

## Custom Editors

Override how specific fields are rendered using `EditorRegistry`:

```dart
JsonEditor(
  schema: schema,
  registry: EditorRegistryData(
    // Override by exact field path
    pathOverrides: {
      '/address/zip': (context, schema, value, onChanged, fieldName) =>
          MyCustomZipEditor(value: value, onChanged: onChanged),
    },
    // Override by schema type
    typeOverrides: {
      SchemaType.string: (context, schema, value, onChanged, fieldName) =>
          MyFancyStringEditor(schema: schema, value: value, onChanged: onChanged),
    },
  ),
)
```

## Remote References

Resolve external `$ref` URLs (e.g. for enum lookups from an API) by providing an `onRefLookup` callback:

```dart
JsonEditor(
  schema: schema,
  onRefLookup: (url) async {
    final response = await http.get(Uri.parse(url));
    return json.decode(response.body) as List<Map<String, dynamic>>;
  },
  minTypeAhead: 10, // switch from dropdown to typeahead above this count
)
```

Results are cached per URL for the lifetime of the widget.

## Supported Schema Features

| Feature | Support |
|---|---|
| Basic types (string, number, integer, boolean) | Full |
| Enum | Full |
| Objects with properties | Full |
| Nested objects | Full |
| Arrays (homogeneous + tuple) | Full |
| Maps (additionalProperties) | Full |
| `oneOf` / `anyOf` composition | Full |
| `if` / `then` / `else` conditionals | Full |
| Property & schema dependencies | Full |
| `$ref` (local) | Full, with circular depth protection |
| `$ref` (remote URL) | Via async callback |
| `readOnly` / `writeOnly` | Full |
| `const` values | Full (rendered read-only) |
| Nullable types | Full (clear button) |
| `minItems` / `maxItems` | Full |
| `minimum` / `maximum` | Validation |
| `format` (email, uri) | Validation |
| `default` values | Applied on field creation |
| Reorderable arrays | Full (drag handles) |

## Example

Check out the [example project](./example) to see the editor in action with an employee record schema that exercises most of these features — nested objects, arrays, maps, conditionals, remote refs, and more.

## Requirements

- Flutter >= 3.10.0
- Dart SDK >= 3.0.0

## License

See [LICENSE](LICENSE) for details.
