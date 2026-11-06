# Writing forms for flutter_json_editor

<!-- Generated from lib/src/catalog/editor_catalog.dart by `UPDATE_LLM_DOCS=1 flutter test test/llm_docs_test.dart`. Don't edit by hand. -->

A form is a JSON Schema (draft-07) object. Each property is a field; its `type` picks a default editor, `x-format` a special one, and `x-layout` lays out an object. This guide lists every editor with when to use it, what it needs, what it stores and a minimal example. The meta-schema [`schema/flutter_json_editor.schema.json`](../schema/flutter_json_editor.schema.json) validates keyword types; `SchemaLint.check(schema)` finds what renders differently than meant.

## Rules

1. The root is `{"type": "object", "properties": {…}}`; put mandatory fields in `required`.
2. Give every field a `title` (the label) and, where it helps, a `description`.
3. For choices whose labels differ from the stored values use `"oneOf": [{"const": "de", "title": "Germany"}, …]`; otherwise an `enum`.
4. Every `x-format` needs the type its entry lists. A mismatch doesn't fail: the field silently falls back to a default editor.
5. Photos and files are stored in the data as base64. Limit them (`x-max-width`, `x-max-file-size`, `maxItems`).
6. Run `SchemaLint.check(schema)` (or the meta-schema) and fix every error before using the form; each message says how.

## Without `x-format`

| Schema | Editor |
|---|---|
| `string` | text field (`minLength`, `maxLength`, `pattern`) |
| `string` + `enum` / `oneOf` of `const`s | dropdown |
| `number`, `integer` | number field (`minimum`, `maximum`, `x-unit`, `x-currency`) |
| `boolean` | switch |
| `object` | card with its properties (`x-layout`) |
| `array` | list with add, remove, reorder (`minItems`, `maxItems`) |
| `readOnly: true` | shown, not editable |
| `default` | the value of a new form |
| `if`/`then`/`else`, `dependencies` | fields that appear with an answer |
| `$ref` to `#/definitions/…` | reused parts |

## Which editor?

| Question | Schema |
|---|---|
| Short text | `string` |
| Long text | `string` + `x-format: textarea` |
| Formatted text, instructions | `string` + `x-format: markdown` |
| Code, IBAN, licence plate | `string` + `x-mask` |
| Email, URL | `string` + `format: email` / `uri` |
| Phone number | `string` + `x-format: phone` |
| Number, amount, weight | `number` (+ `x-unit` / `x-currency`) |
| Small count | `integer` + `x-format: stepper` |
| Rough amount in a range | `number` + `x-format: slider` |
| Yes / no | `boolean` |
| Accept terms | `boolean` + `x-format: consent` + `const: true` |
| One of many | `enum` or `oneOf` of `const`s (a dropdown) |
| One of two to five | the same + `x-format: segmented` |
| One of several pictures | `oneOf` with `x-image` + `x-format: image-choice` |
| Several of a list | `array` of choices + `x-format: chips` |
| Order of preference | `array` of choices + `x-format: ranking` |
| Rating 1–5 or 1–10 | `integer` + `x-format: linear-scale` |
| Mood, satisfaction | `integer` + `x-format: emoji-scale` |
| Recommend us? (0–10) | `integer` + `x-format: nps` |
| Stars | `integer` + `x-format: star-rating` |
| Same choices for several rows | `object` + `x-format: matrix` |
| Day / time / moment | `string` + `format: date` / `time` / `date-time` |
| From … to … | `object` or `string` + `x-format: date-range` |
| How long | `string` + `format: duration` |
| Colour | `string` + `x-format: colour` |
| Photo(s) | `string` / `array` + `x-format: image-data` |
| Documents | `string` / `array` + `x-format: file-data` |
| Signature | `string` + `x-format: signature` |
| Regions of a picture | `array` + `x-format: svg-part-picker` |
| A computed total | any type + `x-calc` |
| A value nobody edits | any type + `x-hidden: true` |
| A list of entries | `array` of `object`s |
| A long form step by step | `object` + `x-layout: wizard` |
| Groups in any order | `object` + `x-layout: tabs` |
| Optional details | `object` + `x-layout: collapsible` |

## Editors

### `x-format: "chips"` — Choice chips

- **Use for:** Several answers out of a short list (checkboxes). Choices are an `enum`, or a `oneOf` of `{"const": …, "title": …}` branches for labels that differ from the stored values.
- **Applies to:** `array`, with choices on `items`.
- **Keys:**
  - `items`: The choices: an `enum` or a `oneOf` of `const`s.
  - `minItems`: Fewest choices.
  - `maxItems`: Most choices.
  - `uniqueItems`: Set to true.
- **Stores:** An array of the chosen values, `["wifi", "parking"]`.
- **Don't:** Choices on the array instead of on `items`.
- **Don't:** Chips when the order matters: use `ranking`.

```json
{
  "type": "array",
  "title": "Amenities",
  "x-format": "chips",
  "uniqueItems": true,
  "items": {
    "type": "string",
    "enum": [
      "wifi",
      "parking",
      "breakfast"
    ]
  }
}
```

### `x-format: "colour"` — Colour wheel (also `color`)

- **Use for:** Picking a colour.
- **Applies to:** `string`.
- **Stores:** A hex string, `"#ff0000"`.

```json
{
  "type": "string",
  "title": "Colour",
  "x-format": "colour"
}
```

### `x-format: "consent"` — Consent checkbox

- **Use for:** Accepting terms or a privacy notice: a checkbox with the `description` (Markdown, links work) as its text.
- **Applies to:** `boolean`.
- **Keys:**
  - `description`: The text to agree to; Markdown links open.
  - `const`: Set to true (with `required`) to make agreeing mandatory.
- **Stores:** `true` when ticked.
- **Don't:** Consent for a plain yes/no question: use a `boolean` without `x-format`.

```json
{
  "type": "boolean",
  "title": "Terms",
  "x-format": "consent",
  "description": "I accept the [terms](https://example.com/terms).",
  "const": true
}
```

### `x-format: "date"` — Date picker

- **Use for:** A day. The standard `"format": "date"` on a string picks it too.
- **Applies to:** `string`, `integer`, `number`.
- **Stores:** A `string` stores `"2026-11-06"`; a number stores seconds since 1970 (UTC).

```json
{
  "type": "string",
  "title": "Birthday",
  "format": "date"
}
```

### `x-format: "date-range"` — Date range

- **Use for:** A period from one day to another, picked in one calendar.
- **Applies to:** `object`, `string`.
- **Keys:**
  - `x-min-date`: First selectable day, `yyyy-MM-dd` (default 1900).
  - `x-max-date`: Last selectable day, `yyyy-MM-dd` (default 2100).
  - `properties`: On an object: its first two properties name the keys.
- **Stores:** An `object` stores `{"start": "2026-11-06", "end": "2026-11-10"}`; a `string` stores `"2026-11-06/2026-11-10"`.

```json
{
  "type": "object",
  "title": "Vacation",
  "x-format": "date-range",
  "properties": {
    "start": {
      "type": "string",
      "format": "date"
    },
    "end": {
      "type": "string",
      "format": "date"
    }
  }
}
```

### `x-format: "date-time"` — Date and time

- **Use for:** A moment: a date and a time side by side. The standard `"format": "date-time"` picks it too.
- **Applies to:** `string`, `integer`, `number`.
- **Stores:** A `string` stores `"2026-11-06T14:30:00Z"`; a number stores seconds since 1970 (UTC).

```json
{
  "type": "string",
  "title": "Starts",
  "format": "date-time"
}
```

### `x-format: "duration"` — Duration

- **Use for:** A length of time in hours and minutes. The standard `"format": "duration"` picks it too.
- **Applies to:** `string`, `integer`, `number`.
- **Stores:** A `string` stores ISO 8601, `"PT1H30M"`; a number stores seconds, `5400`.

```json
{
  "type": "string",
  "title": "Effort",
  "format": "duration"
}
```

### `x-format: "emoji-scale"` — Emoji scale

- **Use for:** A mood or satisfaction question: two to five faces.
- **Applies to:** `integer`; 2 to 5 steps, default 1–5.
- **Keys:**
  - `minimum`: The first step.
  - `maximum`: The last step.
  - `x-labels`: A name per step, shown as tooltip and under the chosen one.
  - `x-min-label`: A label under the first step.
  - `x-max-label`: A label under the last step.
- **Stores:** The chosen step as an integer, `4`.
- **Don't:** More than five steps: use `linear-scale`.

```json
{
  "type": "integer",
  "title": "How do you feel?",
  "x-format": "emoji-scale",
  "minimum": 1,
  "maximum": 5
}
```

### `x-format: "file-data"` — File upload

- **Use for:** Attaching documents. The file is stored in the data itself as base64, so keep files small.
- **Applies to:** `string`, `object`, `array`.
- **Keys:**
  - `x-accept`: Allowed file extensions, `["pdf", "docx"]`.
  - `contentMediaType`: Allowed media type, `application/pdf`, `image/*`.
  - `x-max-file-size`: Largest file in bytes (default 5 MiB).
  - `maxItems`: On an array: most files.
- **Stores:** A `string` stores a data URI with the name, `"data:application/pdf;name=cv.pdf;base64,…"`; an `object` stores `{"name", "type", "size", "data"}`; an `array` holds several.
- **Don't:** An array without `maxItems`, or files without `x-max-file-size`: each file lands in the data.
- **Don't:** File uploads for photos: use `image-data`, which scales them down.

```json
{
  "type": "string",
  "title": "CV",
  "x-format": "file-data",
  "x-accept": [
    "pdf"
  ],
  "x-max-file-size": 2000000
}
```

### `x-format: "image-choice"` — Picture choice

- **Use for:** A single choice where each option has a picture (`x-image` URL) and an optional `description`.
- **Applies to:** any type, with a `oneOf` of `const` branches.
- **Keys:**
  - `oneOf`: Branches `{"const": …, "title": …, "x-image": "https://…"}`.
- **Stores:** The `const` of the chosen branch.
- **Don't:** An `enum`: the pictures go on `oneOf` branches.

```json
{
  "type": "string",
  "title": "Dish",
  "x-format": "image-choice",
  "oneOf": [
    {
      "const": "pasta",
      "title": "Pasta",
      "x-image": "https://example.com/pasta.jpg"
    },
    {
      "const": "salad",
      "title": "Salad",
      "x-image": "https://example.com/salad.jpg"
    }
  ]
}
```

### `x-format: "image-data"` — Photo

- **Use for:** Taking or choosing photos, stored in the data itself as base64 (scaled down while picking). An array is a gallery of several.
- **Applies to:** `string`, `array`.
- **Keys:**
  - `x-max-width`: Longest width in pixels after scaling.
  - `x-max-height`: Longest height in pixels after scaling.
  - `x-image-quality`: JPEG quality, 0–100.
  - `contentEncoding`: `base64` stores bare base64 instead of a data URI.
  - `maxItems`: On an array: most photos.
- **Stores:** A data URI, `"data:image/jpeg;base64,…"`; an array of `string`s holds several.
- **Don't:** No `x-max-width`/`x-max-height`: full-size photos are megabytes each.
- **Don't:** A gallery (array) without `maxItems`.

```json
{
  "type": "string",
  "title": "Photo",
  "x-format": "image-data",
  "x-max-width": 1024,
  "x-max-height": 1024,
  "x-image-quality": 80
}
```

### `x-format: "image-url-picker"` — Image URL picker

- **Use for:** Choosing one of several pictures whose URLs are the stored values (`enum` of URLs, or a remote `$ref` resolved by the app).
- **Applies to:** `string`.
- **Stores:** The chosen URL (or the remote item's value).
- **Don't:** Stored values that aren't the URLs: use `image-choice`.

```json
{
  "type": "string",
  "title": "Avatar",
  "x-format": "image-url-picker",
  "enum": [
    "https://example.com/a.png",
    "https://example.com/b.png"
  ]
}
```

### `x-format: "linear-scale"` — Linear scale

- **Use for:** A rating on numbered buttons, `1` to `5` or `0` to `10`, with optional end labels.
- **Applies to:** `integer`; 2 to 11 steps, default 1–5.
- **Keys:**
  - `minimum`: The first step.
  - `maximum`: The last step.
  - `x-labels`: A name per step, shown as tooltip and under the chosen one.
  - `x-min-label`: A label under the first step.
  - `x-max-label`: A label under the last step.
- **Stores:** The chosen number, `4`.
- **Don't:** More than eleven steps: use `slider`.

```json
{
  "type": "integer",
  "title": "How easy was it?",
  "x-format": "linear-scale",
  "minimum": 1,
  "maximum": 5,
  "x-min-label": "Hard",
  "x-max-label": "Easy"
}
```

### `x-format: "markdown"` — Markdown

- **Use for:** Rich text: rendered as Markdown when read-only, a multi-line field when editable. With `readOnly` and a `default`, a block of instructions inside the form.
- **Applies to:** `string`.
- **Stores:** The Markdown text.

```json
{
  "type": "string",
  "title": "Notes",
  "x-format": "markdown"
}
```

### `x-format: "matrix"` — Matrix

- **Use for:** The same choices for several rows (a grid of radio buttons, or checkboxes where a row is an array). Rows are the properties; the columns are the first row's choices.
- **Applies to:** `object`, with properties with choices, one per row.
- **Keys:**
  - `properties`: One per row, each with the same `enum` or `oneOf`.
  - `required`: Rows that need an answer.
- **Stores:** An object of row → chosen value, `{"food": "good"}`.
- **Don't:** Rows with different choices: the columns come from the first.

```json
{
  "type": "object",
  "title": "Rate our service",
  "x-format": "matrix",
  "properties": {
    "food": {
      "type": "string",
      "title": "Food",
      "enum": [
        "bad",
        "ok",
        "good"
      ]
    },
    "staff": {
      "type": "string",
      "title": "Staff",
      "enum": [
        "bad",
        "ok",
        "good"
      ]
    }
  }
}
```

### `x-format: "nps"` — Net Promoter Score

- **Use for:** The "How likely are you to recommend us?" question, 0 to 10 with localized end labels.
- **Applies to:** `integer`; 2 to 11 steps, default 0–10.
- **Keys:**
  - `minimum`: The first step.
  - `maximum`: The last step.
  - `x-labels`: A name per step, shown as tooltip and under the chosen one.
  - `x-min-label`: A label under the first step.
  - `x-max-label`: A label under the last step.
- **Stores:** The score, `9`.

```json
{
  "type": "integer",
  "title": "Would you recommend us?",
  "x-format": "nps"
}
```

### `x-format: "phone"` — Phone number

- **Use for:** A phone number with a country picker, checked as typed.
- **Applies to:** `string`.
- **Keys:**
  - `x-default-country`: ISO country code to start with, `"DE"`.
  - `x-countries`: Countries to offer, `["DE", "AT", "CH"]`.
- **Stores:** E.164, `"+4930123456"`.

```json
{
  "type": "string",
  "title": "Phone",
  "x-format": "phone",
  "x-default-country": "DE"
}
```

### `x-format: "ranking"` — Ranking

- **Use for:** Putting choices in order by dragging.
- **Applies to:** `array`, with choices on `items`.
- **Keys:**
  - `items`: The choices: an `enum` or a `oneOf` of `const`s.
- **Stores:** All choices in the chosen order, `["price", "speed"]`.

```json
{
  "type": "array",
  "title": "What matters most?",
  "x-format": "ranking",
  "items": {
    "type": "string",
    "enum": [
      "price",
      "speed",
      "quality"
    ]
  }
}
```

### `x-format: "segmented"` — Segmented buttons

- **Use for:** A single choice out of two to five short options. Choices are an `enum`, or a `oneOf` of `{"const": …, "title": …}` branches for labels that differ from the stored values.
- **Applies to:** any type, with choices (an `enum`, or a `oneOf` of `const` branches).
- **Stores:** The chosen value.
- **Don't:** More than five options: leave out `x-format` (a dropdown).

```json
{
  "type": "string",
  "title": "Priority",
  "x-format": "segmented",
  "oneOf": [
    {
      "const": "low",
      "title": "Low"
    },
    {
      "const": "normal",
      "title": "Normal"
    },
    {
      "const": "high",
      "title": "High"
    }
  ]
}
```

### `x-format: "signature"` — Signature

- **Use for:** Signing or sketching with a finger, pen or mouse.
- **Applies to:** `string`.
- **Stores:** A small SVG document of the strokes.

```json
{
  "type": "string",
  "title": "Signature",
  "x-format": "signature"
}
```

### `x-format: "slider"` — Slider

- **Use for:** A number in a range where the exact value matters little.
- **Applies to:** `number`, `integer`.
- **Keys:**
  - `minimum`: Start (default 0).
  - `maximum`: End (default minimum + 100).
  - `multipleOf`: Step size (integers default to 1).
- **Stores:** The number.

```json
{
  "type": "integer",
  "title": "Volume",
  "x-format": "slider",
  "minimum": 0,
  "maximum": 10
}
```

### `x-format: "star-rating"` — Star rating

- **Use for:** Zero to five stars.
- **Applies to:** `integer`, `string`.
- **Stores:** The stars, `3` (or `"3"` for a string).

```json
{
  "type": "integer",
  "title": "Rating",
  "x-format": "star-rating"
}
```

### `x-format: "stepper"` — Stepper

- **Use for:** A small count changed with − and + buttons.
- **Applies to:** `number`, `integer`.
- **Keys:**
  - `minimum`: Lowest value.
  - `maximum`: Highest value.
  - `multipleOf`: Step size (default 1).
- **Stores:** The number.

```json
{
  "type": "integer",
  "title": "Guests",
  "x-format": "stepper",
  "minimum": 1,
  "maximum": 10
}
```

### `x-format: "svg-part-picker"` — SVG part picker

- **Use for:** Selecting regions of a picture, e.g. body parts or car damage. The SVG is an asset of the app: regions are elements with `class="region"` and an `id`.
- **Applies to:** `array`, `string`, with an `x-svg-asset`.
- **Keys:**
  - `x-svg-asset`: The SVG asset path of the app.
- **Stores:** The selected region ids, as an array or comma-separated text.
- **Don't:** An asset the app doesn't ship: ask which ones exist.

```json
{
  "type": "array",
  "title": "Where does it hurt?",
  "x-format": "svg-part-picker",
  "x-svg-asset": "assets/images/body-parts.svg",
  "items": {
    "type": "string"
  }
}
```

### `x-format: "textarea"` — Text area

- **Use for:** Longer free text.
- **Applies to:** `string`.
- **Keys:**
  - `x-rows`: Visible lines (default 4).
  - `maxLength`: Most characters, shown as a counter.
- **Stores:** The text.

```json
{
  "type": "string",
  "title": "Comments",
  "x-format": "textarea",
  "x-rows": 5
}
```

### `x-format: "time"` — Time picker

- **Use for:** A time of day. The standard `"format": "time"` picks it too.
- **Applies to:** `string`, `integer`, `number`.
- **Stores:** A `string` stores `"14:30:00"`; a number stores seconds since midnight (UTC).

```json
{
  "type": "string",
  "title": "Arrival",
  "format": "time"
}
```

## Layouts

`x-layout` on an object. `wizard` and `tabs` make each property a page; give the pages object schemas with titles.

### `x-layout: "card"` — Card

- **Use for:** The default: a nested object in a card with its title.
- **Applies to:** `object`.
- **Stores:** The object.

```json
{
  "type": "object",
  "title": "Address",
  "properties": {
    "street": {
      "type": "string",
      "title": "Street"
    },
    "city": {
      "type": "string",
      "title": "City"
    }
  }
}
```

### `x-layout: "collapsible"` — Collapsible section

- **Use for:** An optional or rarely needed group that can be folded away.
- **Applies to:** `object`.
- **Keys:**
  - `x-collapsed`: Start folded.
- **Stores:** The object.

```json
{
  "type": "object",
  "title": "More details",
  "x-layout": "collapsible",
  "x-collapsed": true,
  "properties": {
    "notes": {
      "type": "string",
      "title": "Notes"
    }
  }
}
```

### `x-layout: "plain"` — Plain

- **Use for:** A group without a card, its fields inline with the parent's.
- **Applies to:** `object`.
- **Stores:** The object.

```json
{
  "type": "object",
  "x-layout": "plain",
  "properties": {
    "first": {
      "type": "string",
      "title": "First name"
    },
    "last": {
      "type": "string",
      "title": "Last name"
    }
  }
}
```

### `x-layout: "wizard"` — Wizard

- **Use for:** A long form one step at a time: each property is a step, with Back/Next and a progress bar. A step can't be left with missing or invalid answers; the last step submits (`onSubmit`). Works on the root too.
- **Applies to:** `object`.
- **Stores:** The object.
- **Don't:** Fewer than two steps.
- **Don't:** Steps that aren't objects.

```json
{
  "type": "object",
  "title": "Sign-up",
  "x-layout": "wizard",
  "properties": {
    "you": {
      "type": "object",
      "title": "About you",
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "title": "Name"
        }
      }
    },
    "plan": {
      "type": "object",
      "title": "Plan",
      "properties": {
        "tier": {
          "type": "string",
          "title": "Tier",
          "enum": [
            "free",
            "pro"
          ]
        }
      }
    }
  }
}
```

### `x-layout: "tabs"` — Tabs

- **Use for:** Groups of a form that can be filled in any order: each property is a tab. Tabs left with missing answers get a mark.
- **Applies to:** `object`.
- **Stores:** The object.
- **Don't:** Fewer than two tabs.
- **Don't:** More than five or six tabs.

```json
{
  "type": "object",
  "title": "Workplace",
  "x-layout": "tabs",
  "properties": {
    "office": {
      "type": "object",
      "title": "Office",
      "properties": {
        "floor": {
          "type": "integer",
          "title": "Floor"
        }
      }
    },
    "equipment": {
      "type": "object",
      "title": "Equipment",
      "properties": {
        "laptop": {
          "type": "boolean",
          "title": "Laptop"
        }
      }
    }
  }
}
```

## Form logic

- **Hidden fields:** `"x-hidden": true` keeps a value in the data but never shows it.
- **Calculated fields:** `"x-calc"` is a [JSON Logic](https://jsonlogic.com) rule; its result is the field's value, shown read-only. `{"var": "order.qty"}` reads from the root, `{"var": ".qty"}` from the object holding the field (use this inside array items). Calculations may read other calculations, but not in a circle. Operators: `var` `missing` `missing_some` `if` `?:` `and` `or` `!` `!!` `==` `!=` `===` `!==` `<` `<=` `>` `>=` `+` `-` `*` `/` `%` `min` `max` `round` `map` `filter` `reduce` `all` `none` `some` `merge` `in` `count` `cat` `substr` `log`.
- **Piping:** `{{path}}` in a `title` or `description` shows an answer, `{{.key}}` one of the same object.
- **Conditional fields:** `if`/`then`/`else` or `dependencies` add properties when an answer matches.

```json
{
  "type": "object",
  "properties": {
    "items": {
      "type": "array",
      "title": "Items",
      "items": {
        "type": "object",
        "properties": {
          "qty": {
            "type": "integer",
            "title": "Qty"
          },
          "price": {
            "type": "number",
            "title": "Price"
          },
          "sum": {
            "type": "number",
            "title": "Sum",
            "x-calc": {
              "*": [
                {
                  "var": ".qty"
                },
                {
                  "var": ".price"
                }
              ]
            }
          }
        }
      }
    },
    "total": {
      "type": "number",
      "title": "Total",
      "x-currency": "EUR",
      "x-calc": {
        "reduce": [
          {
            "var": "items"
          },
          {
            "+": [
              {
                "var": "accumulator"
              },
              {
                "var": "current.sum"
              }
            ]
          },
          0
        ]
      }
    }
  }
}
```

## Keywords

| Keyword | Value | Works on | What it does |
|---|---|---|---|
| `x-format` | string | any field | Picks the editor of a field. Unknown values fall back to the default editor of the type. |
| `x-layout` | string | objects | How an object is laid out: card (default), collapsible, plain, wizard, tabs. |
| `x-collapsed` | boolean | `x-layout: collapsible` | A collapsible object starts folded. |
| `x-hidden` | boolean | any field | Kept in the data but never shown: ids, sources, calculated values nobody needs to see. |
| `x-calc` | any | any field | A JSON Logic rule whose result is the field's value, read-only. `{"var": "a.b"}` reads from the form's root, `{"var": ".b"}` from the object holding the field (array items). |
| `x-mask` | string | text fields | An input pattern for a text field: `0` a digit, `A` a letter, `*` either; other characters are literal. `AA00 0000 0000`. |
| `x-mask-raw` | boolean | text fields | Store only the typed characters, without the literals. |
| `x-unit` | string | number fields | A unit after a number field, `kg`, `%`. |
| `x-currency` | string | number fields | An ISO 4217 code; its symbol goes before a number field. |
| `x-rows` | integer | `textarea` | Visible lines of a textarea. |
| `x-labels` | string[] | `linear-scale`, `nps`, `emoji-scale` | A name per step of a scale. |
| `x-min-label` | string | `linear-scale`, `nps`, `emoji-scale` | A label under the first step of a scale. |
| `x-max-label` | string | `linear-scale`, `nps`, `emoji-scale` | A label under the last step of a scale. |
| `x-min-date` | string | `date-range` | First selectable day of a date range, `yyyy-MM-dd`. |
| `x-max-date` | string | `date-range` | Last selectable day of a date range, `yyyy-MM-dd`. |
| `x-accept` | string[] | `file-data` | File extensions a file upload accepts, without dots. |
| `x-max-file-size` | integer | `file-data` | Largest file of a file upload, in bytes. |
| `x-max-width` | number | `image-data` | Photos are scaled down to this width, in pixels. |
| `x-max-height` | number | `image-data` | Photos are scaled down to this height, in pixels. |
| `x-image-quality` | integer | `image-data` | JPEG quality of photos, 0–100. |
| `x-default-country` | string | `phone` | The country a phone field starts with, `DE`. |
| `x-countries` | string[] | `phone` | The countries a phone field offers. |
| `x-svg-asset` | string | `svg-part-picker` | The SVG asset of an svg-part-picker. |
| `x-image` | string | any field | The picture URL of an image-choice option (on a branch). |

## Data size

`image-data` and `file-data` store the file in the form's data as base64 (a third larger than the file). Scale photos with `x-max-width`/`x-max-height` (1024 is plenty for documentation, `x-image-quality` 70–85), cap files with `x-max-file-size` (default 5 MiB) and arrays with `maxItems`. Prefer one or two small files per field; for many or large files store links instead.

## Checking a schema

`SchemaLint.check(schema)` returns issues with a JSON Pointer `path`, a `code`, a `severity` and a `message` that says how to fix it. Errors render differently than meant; warnings are likely mistakes. Fix, check again, repeat until no errors remain.

| Code | Severity |
|---|---|
| `unknown-format` | error |
| `format-type` | error |
| `format-choices` | error |
| `scale-range` | error |
| `scale-labels` | warning |
| `large-data` | warning |
| `keyword-type` | error |
| `keyword-unused` | warning |
| `unknown-keyword` | warning |
| `layout-value` | error |
| `layout-type` | error |
| `layout-pages` | warning |
| `calc-operator` | error |
| `calc-var` | warning |
| `calc-cycle` | error |
| `pipe-unknown` | warning |

Complete examples: `example/assets/forms/` (survey, onboarding wizard, order with calculations, inspection with photos and signature).
