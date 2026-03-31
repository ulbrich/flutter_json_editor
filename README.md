# Flutter JSON Editor

A Flutter widget that dynamically generates interactive forms from [JSON Schema (Draft 7)](https://json-schema.org/draft-07). Drop in a schema, get a fully functional form — with validation, nested objects, arrays, conditional fields, and more.

**Warning:** This sideproject was implemented mainly using AI tools. Use it with a grain
of more salt than with any other open source project you're using.

## The Idea

Building forms by hand is tedious. Building forms that mirror a complex, evolving data model is worse. JSON Schema already describes your data structure, constraints, and validation rules — so why not let the schema *be* the form?

Obviously this is nothing new and we took inspiration from the Javascript [JSON Editor](https://github.com/json-editor/json-editor) project we successfully used in web projects back in time. We wanted to have that for a long time in Flutter and the raise of AI tools
gave us the help we needed.

The Flutter JSON Editor takes a JSON Schema and renders a complete, editable form widget. When the user changes a value, you get the full data object *and* a precise diff of what changed. No form-builder boilerplate, no manual field wiring — just schema in, data out.

Take the example project for s spin and judge for yourself. Feel free to suggest extensions, but make sure they always support i18n and don't introduce new dependencies. We want to keep this package small and rather provide a companion project with additional niche editors.

## Features

- **Full type coverage** — String, number, integer, boolean, enum, object, array, map, colour picker, date/time, and SVG part picker editors out of the box
- **Nested structures** — Objects within objects, arrays of objects, maps with dynamic keys
- **Conditional fields** — `if`/`then`/`else` branches show and hide fields based on data state
- **Property dependencies** — Fields that appear or become required based on other field values
- **Composition** — `oneOf` and `anyOf` with automatic variant detection
- **Inline validation** — Field-level error messages derived from schema constraints
- **Remote `$ref` resolution** — Async lookup for external schema references with caching, dropdown or typeahead based on result count
- **Diff tracking** — `DiffCalculator` reports only the paths that changed between updates
- **Theming** — `JsonEditorTheme` extension integrates with your Material 3 theme
- **Custom editors** — `EditorRegistry` lets you override any field by path, `x-format`, type, or predicate
- **Built-in format editors** — `x-format` or standard `format` activates colour wheel, star rating, image picker, date/time pickers, SVG part picker, and Markdown renderer
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

1. **Registry overrides** — your custom editors (by path, `x-format`, predicate, or type)
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
      'address.zip': ({required schema, required path, required value,
          required onChanged, required isRequired, isNullable = false}) =>
          MyCustomZipEditor(value: value, onChanged: onChanged),
    },
    // Override by x-format value
    formatOverrides: {
      'star-rating': ({required schema, required path, required value,
          required onChanged, required isRequired, isNullable = false}) =>
          MyStarRatingEditor(value: value, onChanged: onChanged),
    },
    // Override by schema type
    typeOverrides: {
      SchemaType.string: ({required schema, required path, required value,
          required onChanged, required isRequired, isNullable = false}) =>
          MyFancyStringEditor(schema: schema, value: value, onChanged: onChanged),
    },
  ),
)
```

### Built-in Format Editors

The library ships with built-in editors activated via the `x-format` schema extension. These work automatically without any registry configuration:

| `x-format` / `format` value | Editor | Stored format |
|---|---|---|
| `"colour"` or `"color"` | Interactive HSV colour wheel with brightness slider | `#rrggbb` hex string (e.g. `"#ff0000"`) |
| `"star-rating"` | Clickable 0–5 star rating | `int` or `String` depending on schema type |
| `"image-url-picker"` | Selectable image thumbnail grid | Selected value (URL or ID) |
| `"date"` | Date picker dialog | `"yyyy-MM-dd"` string or seconds-since-epoch `int` |
| `"time"` | Hour/minute dropdown selectors | `"HH:mm:ss"` string or seconds-since-midnight `int` |
| `"date-time"` | Combined date picker + time dropdowns | ISO 8601 string or seconds-since-epoch `int` |
| `"markdown"` | Markdown renderer (read-only) or multiline text editor | `String` |
| `"svg-part-picker"` | Interactive SVG region selector | Comma-separated `String` or `List<String>` |

These editors activate via `x-format` or the standard JSON Schema `format` field (e.g. `"format": "date"` works the same as `"x-format": "date"`).

```json
{
  "favouriteColour": {
    "type": "string",
    "x-format": "colour",
    "title": "Favourite Colour",
    "default": "#ff0000"
  },
  "performance": {
    "type": "integer",
    "x-format": "star-rating",
    "title": "Performance Rating",
    "minimum": 0,
    "maximum": 5,
    "default": 0
  },
  "startDate": {
    "type": "string",
    "format": "date",
    "title": "Start Date"
  },
  "lastCheckIn": {
    "type": "string",
    "x-format": "date-time",
    "title": "Last Check-In"
  },
  "seating": {
    "type": "string",
    "x-format": "svg-part-picker",
    "x-svg-asset": "assets/images/office-plan.svg",
    "title": "Allocated Desk"
  }
}
```

**Date/time editors** accept both string and numeric schema types. String values use ISO 8601 format; numeric values use seconds since epoch (UTC). Values are always stored as UTC but displayed in the user's local timezone with a timezone indicator.

**Star rating editor** works with both `"type": "integer"` (stores `int`) and `"type": "string"` (stores `String`). Clicking a star sets the rating; clicking the same star again resets to 0.

**Image picker** supports two modes:
- **Simple enum** — each `enum` value is an image URL; the selected URL is stored as the value.
- **Remote `$ref`** — resolves a remote reference via `onRefLookup`. The response's `enumSource` is parsed: `title` is treated as the image URL, `value` (e.g. an ID) is stored as the result.

**SVG part picker** renders any SVG asset and lets users toggle selection of regions. Selectable elements are identified by having both an `id` and a `data-state` attribute. The `x-svg-asset` schema property specifies the asset path. IDs present in the data but not found in the SVG are preserved, allowing multiple SVGs to edit different aspects of the same dataset without data loss.

You can override a built-in format editor by providing your own builder for the same key in `formatOverrides`.

### Resolution Priority

Registry overrides are checked in this order (first match wins):

1. **Path overrides** — exact field path match
2. **Format overrides** — `x-format` value match, then standard `format` fallback (includes built-in defaults)
3. **Predicate overrides** — first matching predicate
4. **Type overrides** — schema type match

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
| `format` / `x-format` (colour/color) | Built-in colour wheel editor |
| `format` / `x-format` (star-rating) | Built-in star rating editor |
| `format` / `x-format` (image-url-picker) | Built-in image picker editor |
| `format` / `x-format` (date) | Built-in date picker |
| `format` / `x-format` (time) | Built-in time picker (dropdowns) |
| `format` / `x-format` (date-time) | Built-in combined date-time picker |
| `format` / `x-format` (markdown) | Built-in Markdown renderer/editor |
| `x-format` (svg-part-picker) | Built-in interactive SVG region picker |
| `default` values | Applied on field creation |
| Reorderable arrays | Full (drag handles) |

## Localization

The editor is fully localized using Flutter's `gen-l10n` tooling. Out of the box it ships with English (`en`) and German (`de`).

### Changing Strings

Edit the `.arb` files in `lib/src/l10n/`:

- `json_editor_en.arb` — English (template)
- `json_editor_de.arb` — German

Then regenerate the Dart localization classes:

```bash
$ flutter gen-l10n
$ cd example; flutter gen-l10n
```

The generated files are written to `lib/src/l10n/generated/` as configured in `l10n.yaml`.

### Adding a New Locale

1. Copy the template file to a new `.arb` file with the target locale suffix, e.g. for French:
   ```bash
   cp lib/src/l10n/json_editor_en.arb lib/src/l10n/json_editor_fr.arb
   ```
2. Update `"@@locale": "fr"` at the top of the new file.
3. Translate all the string values.
4. Run `flutter gen-l10n` to regenerate.

The new locale is automatically picked up — no additional registration is needed.

### Using Localizations in Your App

Make sure your `MaterialApp` includes the editor's localization delegate and supported locales:

```dart
import 'package:flutter_json_editor/flutter_json_editor.dart';

MaterialApp(
  localizationsDelegates: const [
    JsonEditorLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: JsonEditorLocalizations.supportedLocales,
  // ...
)
```

## Example

Check out the [example project](./example) to see the editor in action with an employee record schema that exercises most of these features — nested objects, arrays, maps, conditionals, remote refs, and more.

## Requirements

- Flutter >= 3.10.0
- Dart SDK >= 3.0.0

## License

See [LICENSE](LICENSE) for details.
