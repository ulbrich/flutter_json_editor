# Flutter JSON Editor — Example

A demo app showcasing the `flutter_json_editor` package with an **employee record** form generated entirely from a JSON Schema. Be sure to read the source code of `lib`main.dart`
for a couple of hints on how to extend the example to e.g. read references from temote.

## What's Demonstrated

- **Nested objects** — an `address` block with its own required fields
- **Arrays** — a `skills` list with add, remove, and drag-to-reorder
- **Maps** — free-form `tags` with dynamic key/value pairs
- **Enums** — an `employeeType` dropdown
- **Conditionals** — `if`/`then`/`else` shows different fields for contractors vs. full-time employees
- **Remote `$ref`** — a `hobby` field resolved via async callback (simulated API)
- **Nullable fields** — `department` can be cleared
- **Colour picker** — `favouriteColour` uses the built-in colour wheel editor via `x-format: "colour"`
- **Read-only fields** — `notes` rendered as non-editable
- **Live diff preview** — expandable panels show the full data and the most recent diff

## Running

```bash
$ cd example
$ flutter run
```

## Further Reading

For full documentation on the widget API, theming, custom editors, and all supported schema features, see the [package README](../README.md).
