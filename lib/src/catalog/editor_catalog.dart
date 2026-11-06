/// What every editor, layout and `x-` keyword of this package does, as
/// data: the single source for the LLM guide (`doc/llm-guide.md`,
/// `llms.txt`), the meta-schema (`schema/flutter_json_editor.schema.json`)
/// and [SchemaLint]. Pure Dart, so servers and tools can use it too.
library;

/// What an editor needs besides a matching type.
enum EditorRequirement {
  /// An `enum` or a `oneOf`/`anyOf` whose branches are all `const`s.
  choices,

  /// `items` with such choices.
  itemChoices,

  /// At least one property with such choices (or an array of them).
  rowChoices,

  /// A `oneOf`/`anyOf` whose branches are all `const`s.
  constChoices,

  /// An `x-svg-asset`.
  svgAsset,
}

/// The number of steps a scale can show: `minimum` to `maximum`, else
/// [defaultMin] to [defaultMax].
class StepRange {
  const StepRange({
    required this.min,
    required this.max,
    required this.defaultMin,
    required this.defaultMax,
  });

  final int min;
  final int max;
  final int defaultMin;
  final int defaultMax;

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'default': [defaultMin, defaultMax],
  };
}

/// One `x-format` editor or `x-layout`.
class EditorDescriptor {
  const EditorDescriptor({
    required this.name,
    required this.title,
    required this.useFor,
    required this.stores,
    required this.example,
    this.types,
    this.requires,
    this.keys = const {},
    this.dont = const [],
    this.steps,
    this.aliases = const [],
    this.largeData = false,
  });

  /// The `x-format` (or `x-layout`) value.
  final String name;

  /// A short human name.
  final String title;

  /// When to pick it, in a sentence or two.
  final String useFor;

  /// The JSON types it renders (`string`, `integer`, …); null for any.
  final List<String>? types;

  /// What else it needs to render.
  final EditorRequirement? requires;

  /// The keywords that tune it, with what they do.
  final Map<String, String> keys;

  /// What ends up in the data.
  final String stores;

  /// A minimal, complete field schema.
  final Map<String, dynamic> example;

  /// Common mistakes.
  final List<String> dont;

  /// Step limits of a scale.
  final StepRange? steps;

  /// Other `x-format` values for the same editor.
  final List<String> aliases;

  /// Whether the value is base64 data that can grow large.
  final bool largeData;
}

/// The JSON type of an `x-` keyword's value.
enum KeywordType { string, boolean, integer, number, stringList, any }

/// One `x-` keyword.
class KeywordDescriptor {
  const KeywordDescriptor({
    required this.name,
    required this.type,
    required this.description,
    this.on,
    this.layouts,
    this.needs,
  });

  final String name;
  final KeywordType type;
  final String description;

  /// The editors it works with: `x-format` names, or `text` (a plain
  /// string field), `number` (a plain number field) and `object`. Null for
  /// every field.
  final List<String>? on;

  /// The `x-layout`s it works with.
  final List<String>? layouts;

  /// Another keyword it works with only.
  final String? needs;

  String get typeName => switch (type) {
    KeywordType.string => 'string',
    KeywordType.boolean => 'boolean',
    KeywordType.integer => 'integer',
    KeywordType.number => 'number',
    KeywordType.stringList => 'string[]',
    KeywordType.any => 'any',
  };
}

/// Every editor, layout and keyword.
class EditorCatalog {
  EditorCatalog._();

  /// Bumped when the catalog's JSON form (`x-catalog`) changes shape.
  static const int version = 1;

  static const _scaleKeys = {
    'minimum': 'The first step.',
    'maximum': 'The last step.',
    'x-labels': 'A name per step, shown as tooltip and under the chosen one.',
    'x-min-label': 'A label under the first step.',
    'x-max-label': 'A label under the last step.',
  };

  static const _choicesNote =
      'Choices are an `enum`, or a `oneOf` of `{"const": …, "title": …}` '
      'branches for labels that differ from the stored values.';

  /// The `x-format` editors.
  static const List<EditorDescriptor> formats = [
    EditorDescriptor(
      name: 'chips',
      title: 'Choice chips',
      useFor: 'Several answers out of a short list (checkboxes). $_choicesNote',
      types: ['array'],
      requires: EditorRequirement.itemChoices,
      keys: {
        'items': 'The choices: an `enum` or a `oneOf` of `const`s.',
        'minItems': 'Fewest choices.',
        'maxItems': 'Most choices.',
        'uniqueItems': 'Set to true.',
      },
      stores: 'An array of the chosen values, `["wifi", "parking"]`.',
      example: {
        'type': 'array',
        'title': 'Amenities',
        'x-format': 'chips',
        'uniqueItems': true,
        'items': {
          'type': 'string',
          'enum': ['wifi', 'parking', 'breakfast'],
        },
      },
      dont: [
        'Choices on the array instead of on `items`.',
        'Chips when the order matters: use `ranking`.',
      ],
    ),
    EditorDescriptor(
      name: 'colour',
      aliases: ['color'],
      title: 'Colour wheel',
      useFor: 'Picking a colour.',
      types: ['string'],
      stores: 'A hex string, `"#ff0000"`.',
      example: {'type': 'string', 'title': 'Colour', 'x-format': 'colour'},
    ),
    EditorDescriptor(
      name: 'consent',
      title: 'Consent checkbox',
      useFor:
          'Accepting terms or a privacy notice: a checkbox with the '
          '`description` (Markdown, links work) as its text.',
      types: ['boolean'],
      keys: {
        'description': 'The text to agree to; Markdown links open.',
        'const': 'Set to true (with `required`) to make agreeing mandatory.',
      },
      stores: '`true` when ticked.',
      example: {
        'type': 'boolean',
        'title': 'Terms',
        'x-format': 'consent',
        'description': 'I accept the [terms](https://example.com/terms).',
        'const': true,
      },
      dont: [
        'Consent for a plain yes/no question: use a `boolean` without '
            '`x-format`.',
      ],
    ),
    EditorDescriptor(
      name: 'date',
      title: 'Date picker',
      useFor:
          'A day. The standard `"format": "date"` on a string picks it too.',
      types: ['string', 'integer', 'number'],
      stores:
          'A `string` stores `"2026-11-06"`; a number stores seconds since '
          '1970 (UTC).',
      example: {'type': 'string', 'title': 'Birthday', 'format': 'date'},
    ),
    EditorDescriptor(
      name: 'date-range',
      title: 'Date range',
      useFor: 'A period from one day to another, picked in one calendar.',
      types: ['object', 'string'],
      keys: {
        'x-min-date': 'First selectable day, `yyyy-MM-dd` (default 1900).',
        'x-max-date': 'Last selectable day, `yyyy-MM-dd` (default 2100).',
        'properties': 'On an object: its first two properties name the keys.',
      },
      stores:
          'An `object` stores `{"start": "2026-11-06", "end": "2026-11-10"}`; '
          'a `string` stores `"2026-11-06/2026-11-10"`.',
      example: {
        'type': 'object',
        'title': 'Vacation',
        'x-format': 'date-range',
        'properties': {
          'start': {'type': 'string', 'format': 'date'},
          'end': {'type': 'string', 'format': 'date'},
        },
      },
    ),
    EditorDescriptor(
      name: 'date-time',
      title: 'Date and time',
      useFor:
          'A moment: a date and a time side by side. The standard '
          '`"format": "date-time"` picks it too.',
      types: ['string', 'integer', 'number'],
      stores:
          'A `string` stores `"2026-11-06T14:30:00Z"`; a number stores '
          'seconds since 1970 (UTC).',
      example: {'type': 'string', 'title': 'Starts', 'format': 'date-time'},
    ),
    EditorDescriptor(
      name: 'duration',
      title: 'Duration',
      useFor:
          'A length of time in hours and minutes. The standard '
          '`"format": "duration"` picks it too.',
      types: ['string', 'integer', 'number'],
      stores:
          'A `string` stores ISO 8601, `"PT1H30M"`; a number stores seconds, '
          '`5400`.',
      example: {'type': 'string', 'title': 'Effort', 'format': 'duration'},
    ),
    EditorDescriptor(
      name: 'emoji-scale',
      title: 'Emoji scale',
      useFor: 'A mood or satisfaction question: two to five faces.',
      types: ['integer'],
      steps: StepRange(min: 2, max: 5, defaultMin: 1, defaultMax: 5),
      keys: _scaleKeys,
      stores: 'The chosen step as an integer, `4`.',
      example: {
        'type': 'integer',
        'title': 'How do you feel?',
        'x-format': 'emoji-scale',
        'minimum': 1,
        'maximum': 5,
      },
      dont: ['More than five steps: use `linear-scale`.'],
    ),
    EditorDescriptor(
      name: 'file-data',
      title: 'File upload',
      useFor:
          'Attaching documents. The file is stored in the data itself as '
          'base64, so keep files small.',
      types: ['string', 'object', 'array'],
      largeData: true,
      keys: {
        'x-accept': 'Allowed file extensions, `["pdf", "docx"]`.',
        'contentMediaType':
            'Allowed media type, `application/pdf`, '
            '`image/*`.',
        'x-max-file-size': 'Largest file in bytes (default 5 MiB).',
        'maxItems': 'On an array: most files.',
      },
      stores:
          'A `string` stores a data URI with the name, '
          '`"data:application/pdf;name=cv.pdf;base64,…"`; an `object` stores '
          '`{"name", "type", "size", "data"}`; an `array` holds several.',
      example: {
        'type': 'string',
        'title': 'CV',
        'x-format': 'file-data',
        'x-accept': ['pdf'],
        'x-max-file-size': 2000000,
      },
      dont: [
        'An array without `maxItems`, or files without `x-max-file-size`: '
            'each file lands in the data.',
        'File uploads for photos: use `image-data`, which scales them down.',
      ],
    ),
    EditorDescriptor(
      name: 'image-choice',
      title: 'Picture choice',
      useFor:
          'A single choice where each option has a picture (`x-image` URL) '
          'and an optional `description`.',
      requires: EditorRequirement.constChoices,
      keys: {
        'oneOf': 'Branches `{"const": …, "title": …, "x-image": "https://…"}`.',
      },
      stores: 'The `const` of the chosen branch.',
      example: {
        'type': 'string',
        'title': 'Dish',
        'x-format': 'image-choice',
        'oneOf': [
          {
            'const': 'pasta',
            'title': 'Pasta',
            'x-image': 'https://example.com/pasta.jpg',
          },
          {
            'const': 'salad',
            'title': 'Salad',
            'x-image': 'https://example.com/salad.jpg',
          },
        ],
      },
      dont: ['An `enum`: the pictures go on `oneOf` branches.'],
    ),
    EditorDescriptor(
      name: 'image-data',
      title: 'Photo',
      useFor:
          'Taking or choosing photos, stored in the data itself as base64 '
          '(scaled down while picking). An array is a gallery of several.',
      types: ['string', 'array'],
      largeData: true,
      keys: {
        'x-max-width': 'Longest width in pixels after scaling.',
        'x-max-height': 'Longest height in pixels after scaling.',
        'x-image-quality': 'JPEG quality, 0–100.',
        'contentEncoding': '`base64` stores bare base64 instead of a data URI.',
        'maxItems': 'On an array: most photos.',
      },
      stores:
          'A data URI, `"data:image/jpeg;base64,…"`; an array of `string`s '
          'holds several.',
      example: {
        'type': 'string',
        'title': 'Photo',
        'x-format': 'image-data',
        'x-max-width': 1024,
        'x-max-height': 1024,
        'x-image-quality': 80,
      },
      dont: [
        'No `x-max-width`/`x-max-height`: full-size photos are megabytes '
            'each.',
        'A gallery (array) without `maxItems`.',
      ],
    ),
    EditorDescriptor(
      name: 'image-url-picker',
      title: 'Image URL picker',
      useFor:
          'Choosing one of several pictures whose URLs are the stored '
          'values (`enum` of URLs, or a remote `\$ref` resolved by the app).',
      types: ['string'],
      stores: 'The chosen URL (or the remote item\'s value).',
      example: {
        'type': 'string',
        'title': 'Avatar',
        'x-format': 'image-url-picker',
        'enum': ['https://example.com/a.png', 'https://example.com/b.png'],
      },
      dont: ['Stored values that aren\'t the URLs: use `image-choice`.'],
    ),
    EditorDescriptor(
      name: 'linear-scale',
      title: 'Linear scale',
      useFor:
          'A rating on numbered buttons, `1` to `5` or `0` to `10`, with '
          'optional end labels.',
      types: ['integer'],
      steps: StepRange(min: 2, max: 11, defaultMin: 1, defaultMax: 5),
      keys: _scaleKeys,
      stores: 'The chosen number, `4`.',
      example: {
        'type': 'integer',
        'title': 'How easy was it?',
        'x-format': 'linear-scale',
        'minimum': 1,
        'maximum': 5,
        'x-min-label': 'Hard',
        'x-max-label': 'Easy',
      },
      dont: ['More than eleven steps: use `slider`.'],
    ),
    EditorDescriptor(
      name: 'markdown',
      title: 'Markdown',
      useFor:
          'Rich text: rendered as Markdown when read-only, a multi-line '
          'field when editable. With `readOnly` and a `default`, a block of '
          'instructions inside the form.',
      types: ['string'],
      stores: 'The Markdown text.',
      example: {'type': 'string', 'title': 'Notes', 'x-format': 'markdown'},
    ),
    EditorDescriptor(
      name: 'matrix',
      title: 'Matrix',
      useFor:
          'The same choices for several rows (a grid of radio buttons, or '
          'checkboxes where a row is an array). Rows are the properties; '
          'the columns are the first row\'s choices.',
      types: ['object'],
      requires: EditorRequirement.rowChoices,
      keys: {
        'properties': 'One per row, each with the same `enum` or `oneOf`.',
        'required': 'Rows that need an answer.',
      },
      stores: 'An object of row → chosen value, `{"food": "good"}`.',
      example: {
        'type': 'object',
        'title': 'Rate our service',
        'x-format': 'matrix',
        'properties': {
          'food': {
            'type': 'string',
            'title': 'Food',
            'enum': ['bad', 'ok', 'good'],
          },
          'staff': {
            'type': 'string',
            'title': 'Staff',
            'enum': ['bad', 'ok', 'good'],
          },
        },
      },
      dont: ['Rows with different choices: the columns come from the first.'],
    ),
    EditorDescriptor(
      name: 'nps',
      title: 'Net Promoter Score',
      useFor:
          'The "How likely are you to recommend us?" question, 0 to 10 with '
          'localized end labels.',
      types: ['integer'],
      steps: StepRange(min: 2, max: 11, defaultMin: 0, defaultMax: 10),
      keys: _scaleKeys,
      stores: 'The score, `9`.',
      example: {
        'type': 'integer',
        'title': 'Would you recommend us?',
        'x-format': 'nps',
      },
    ),
    EditorDescriptor(
      name: 'phone',
      title: 'Phone number',
      useFor: 'A phone number with a country picker, checked as typed.',
      types: ['string'],
      keys: {
        'x-default-country': 'ISO country code to start with, `"DE"`.',
        'x-countries': 'Countries to offer, `["DE", "AT", "CH"]`.',
      },
      stores: 'E.164, `"+4930123456"`.',
      example: {
        'type': 'string',
        'title': 'Phone',
        'x-format': 'phone',
        'x-default-country': 'DE',
      },
    ),
    EditorDescriptor(
      name: 'ranking',
      title: 'Ranking',
      useFor: 'Putting choices in order by dragging.',
      types: ['array'],
      requires: EditorRequirement.itemChoices,
      keys: {'items': 'The choices: an `enum` or a `oneOf` of `const`s.'},
      stores: 'All choices in the chosen order, `["price", "speed"]`.',
      example: {
        'type': 'array',
        'title': 'What matters most?',
        'x-format': 'ranking',
        'items': {
          'type': 'string',
          'enum': ['price', 'speed', 'quality'],
        },
      },
    ),
    EditorDescriptor(
      name: 'segmented',
      title: 'Segmented buttons',
      useFor:
          'A single choice out of two to five short options. '
          '$_choicesNote',
      requires: EditorRequirement.choices,
      stores: 'The chosen value.',
      example: {
        'type': 'string',
        'title': 'Priority',
        'x-format': 'segmented',
        'oneOf': [
          {'const': 'low', 'title': 'Low'},
          {'const': 'normal', 'title': 'Normal'},
          {'const': 'high', 'title': 'High'},
        ],
      },
      dont: ['More than five options: leave out `x-format` (a dropdown).'],
    ),
    EditorDescriptor(
      name: 'signature',
      title: 'Signature',
      useFor: 'Signing or sketching with a finger, pen or mouse.',
      types: ['string'],
      stores: 'A small SVG document of the strokes.',
      example: {
        'type': 'string',
        'title': 'Signature',
        'x-format': 'signature',
      },
    ),
    EditorDescriptor(
      name: 'slider',
      title: 'Slider',
      useFor: 'A number in a range where the exact value matters little.',
      types: ['number', 'integer'],
      keys: {
        'minimum': 'Start (default 0).',
        'maximum': 'End (default minimum + 100).',
        'multipleOf': 'Step size (integers default to 1).',
      },
      stores: 'The number.',
      example: {
        'type': 'integer',
        'title': 'Volume',
        'x-format': 'slider',
        'minimum': 0,
        'maximum': 10,
      },
    ),
    EditorDescriptor(
      name: 'star-rating',
      title: 'Star rating',
      useFor: 'Zero to five stars.',
      types: ['integer', 'string'],
      stores: 'The stars, `3` (or `"3"` for a string).',
      example: {
        'type': 'integer',
        'title': 'Rating',
        'x-format': 'star-rating',
      },
    ),
    EditorDescriptor(
      name: 'stepper',
      title: 'Stepper',
      useFor: 'A small count changed with − and + buttons.',
      types: ['number', 'integer'],
      keys: {
        'minimum': 'Lowest value.',
        'maximum': 'Highest value.',
        'multipleOf': 'Step size (default 1).',
      },
      stores: 'The number.',
      example: {
        'type': 'integer',
        'title': 'Guests',
        'x-format': 'stepper',
        'minimum': 1,
        'maximum': 10,
      },
    ),
    EditorDescriptor(
      name: 'svg-part-picker',
      title: 'SVG part picker',
      useFor:
          'Selecting regions of a picture, e.g. body parts or car damage. '
          'The SVG is an asset of the app: regions are elements with '
          '`class="region"` and an `id`.',
      types: ['array', 'string'],
      requires: EditorRequirement.svgAsset,
      keys: {'x-svg-asset': 'The SVG asset path of the app.'},
      stores: 'The selected region ids, as an array or comma-separated text.',
      example: {
        'type': 'array',
        'title': 'Where does it hurt?',
        'x-format': 'svg-part-picker',
        'x-svg-asset': 'assets/images/body-parts.svg',
        'items': {'type': 'string'},
      },
      dont: ['An asset the app doesn\'t ship: ask which ones exist.'],
    ),
    EditorDescriptor(
      name: 'textarea',
      title: 'Text area',
      useFor: 'Longer free text.',
      types: ['string'],
      keys: {
        'x-rows': 'Visible lines (default 4).',
        'maxLength': 'Most characters, shown as a counter.',
      },
      stores: 'The text.',
      example: {
        'type': 'string',
        'title': 'Comments',
        'x-format': 'textarea',
        'x-rows': 5,
      },
    ),
    EditorDescriptor(
      name: 'time',
      title: 'Time picker',
      useFor: 'A time of day. The standard `"format": "time"` picks it too.',
      types: ['string', 'integer', 'number'],
      stores:
          'A `string` stores `"14:30:00"`; a number stores seconds since '
          'midnight (UTC).',
      example: {'type': 'string', 'title': 'Arrival', 'format': 'time'},
    ),
  ];

  /// The `x-layout`s of objects.
  static const List<EditorDescriptor> layouts = [
    EditorDescriptor(
      name: 'card',
      title: 'Card',
      useFor: 'The default: a nested object in a card with its title.',
      types: ['object'],
      stores: 'The object.',
      example: {
        'type': 'object',
        'title': 'Address',
        'properties': {
          'street': {'type': 'string', 'title': 'Street'},
          'city': {'type': 'string', 'title': 'City'},
        },
      },
    ),
    EditorDescriptor(
      name: 'collapsible',
      title: 'Collapsible section',
      useFor: 'An optional or rarely needed group that can be folded away.',
      types: ['object'],
      keys: {'x-collapsed': 'Start folded.'},
      stores: 'The object.',
      example: {
        'type': 'object',
        'title': 'More details',
        'x-layout': 'collapsible',
        'x-collapsed': true,
        'properties': {
          'notes': {'type': 'string', 'title': 'Notes'},
        },
      },
    ),
    EditorDescriptor(
      name: 'plain',
      title: 'Plain',
      useFor: 'A group without a card, its fields inline with the parent\'s.',
      types: ['object'],
      stores: 'The object.',
      example: {
        'type': 'object',
        'x-layout': 'plain',
        'properties': {
          'first': {'type': 'string', 'title': 'First name'},
          'last': {'type': 'string', 'title': 'Last name'},
        },
      },
    ),
    EditorDescriptor(
      name: 'wizard',
      title: 'Wizard',
      useFor:
          'A long form one step at a time: each property is a step, with '
          'Back/Next and a progress bar. A step can\'t be left with missing '
          'or invalid answers; the last step submits (`onSubmit`). Works on '
          'the root too.',
      types: ['object'],
      stores: 'The object.',
      example: {
        'type': 'object',
        'title': 'Sign-up',
        'x-layout': 'wizard',
        'properties': {
          'you': {
            'type': 'object',
            'title': 'About you',
            'required': ['name'],
            'properties': {
              'name': {'type': 'string', 'title': 'Name'},
            },
          },
          'plan': {
            'type': 'object',
            'title': 'Plan',
            'properties': {
              'tier': {
                'type': 'string',
                'title': 'Tier',
                'enum': ['free', 'pro'],
              },
            },
          },
        },
      },
      dont: ['Fewer than two steps.', 'Steps that aren\'t objects.'],
    ),
    EditorDescriptor(
      name: 'tabs',
      title: 'Tabs',
      useFor:
          'Groups of a form that can be filled in any order: each property '
          'is a tab. Tabs left with missing answers get a mark.',
      types: ['object'],
      stores: 'The object.',
      example: {
        'type': 'object',
        'title': 'Workplace',
        'x-layout': 'tabs',
        'properties': {
          'office': {
            'type': 'object',
            'title': 'Office',
            'properties': {
              'floor': {'type': 'integer', 'title': 'Floor'},
            },
          },
          'equipment': {
            'type': 'object',
            'title': 'Equipment',
            'properties': {
              'laptop': {'type': 'boolean', 'title': 'Laptop'},
            },
          },
        },
      },
      dont: ['Fewer than two tabs.', 'More than five or six tabs.'],
    ),
  ];

  /// The keywords these editors read.
  static const List<KeywordDescriptor> keywords = [
    KeywordDescriptor(
      name: 'x-format',
      type: KeywordType.string,
      description:
          'Picks the editor of a field. Unknown values fall back to the '
          'default editor of the type.',
    ),
    KeywordDescriptor(
      name: 'x-layout',
      type: KeywordType.string,
      description:
          'How an object is laid out: card (default), collapsible, plain, '
          'wizard, tabs.',
      on: ['object'],
    ),
    KeywordDescriptor(
      name: 'x-collapsed',
      type: KeywordType.boolean,
      description: 'A collapsible object starts folded.',
      layouts: ['collapsible'],
    ),
    KeywordDescriptor(
      name: 'x-hidden',
      type: KeywordType.boolean,
      description:
          'Kept in the data but never shown: ids, sources, calculated '
          'values nobody needs to see.',
    ),
    KeywordDescriptor(
      name: 'x-calc',
      type: KeywordType.any,
      description:
          'A JSON Logic rule whose result is the field\'s value, read-only. '
          '`{"var": "a.b"}` reads from the form\'s root, `{"var": ".b"}` '
          'from the object holding the field (array items).',
    ),
    KeywordDescriptor(
      name: 'x-mask',
      type: KeywordType.string,
      description:
          'An input pattern for a text field: `0` a digit, `A` a letter, `*` '
          'either; other characters are literal. `AA00 0000 0000`.',
      on: ['text'],
    ),
    KeywordDescriptor(
      name: 'x-mask-raw',
      type: KeywordType.boolean,
      description: 'Store only the typed characters, without the literals.',
      on: ['text'],
      needs: 'x-mask',
    ),
    KeywordDescriptor(
      name: 'x-unit',
      type: KeywordType.string,
      description: 'A unit after a number field, `kg`, `%`.',
      on: ['number'],
    ),
    KeywordDescriptor(
      name: 'x-currency',
      type: KeywordType.string,
      description: 'An ISO 4217 code; its symbol goes before a number field.',
      on: ['number'],
    ),
    KeywordDescriptor(
      name: 'x-rows',
      type: KeywordType.integer,
      description: 'Visible lines of a textarea.',
      on: ['textarea'],
    ),
    KeywordDescriptor(
      name: 'x-labels',
      type: KeywordType.stringList,
      description: 'A name per step of a scale.',
      on: ['linear-scale', 'nps', 'emoji-scale'],
    ),
    KeywordDescriptor(
      name: 'x-min-label',
      type: KeywordType.string,
      description: 'A label under the first step of a scale.',
      on: ['linear-scale', 'nps', 'emoji-scale'],
    ),
    KeywordDescriptor(
      name: 'x-max-label',
      type: KeywordType.string,
      description: 'A label under the last step of a scale.',
      on: ['linear-scale', 'nps', 'emoji-scale'],
    ),
    KeywordDescriptor(
      name: 'x-min-date',
      type: KeywordType.string,
      description: 'First selectable day of a date range, `yyyy-MM-dd`.',
      on: ['date-range'],
    ),
    KeywordDescriptor(
      name: 'x-max-date',
      type: KeywordType.string,
      description: 'Last selectable day of a date range, `yyyy-MM-dd`.',
      on: ['date-range'],
    ),
    KeywordDescriptor(
      name: 'x-accept',
      type: KeywordType.stringList,
      description: 'File extensions a file upload accepts, without dots.',
      on: ['file-data'],
    ),
    KeywordDescriptor(
      name: 'x-max-file-size',
      type: KeywordType.integer,
      description: 'Largest file of a file upload, in bytes.',
      on: ['file-data'],
    ),
    KeywordDescriptor(
      name: 'x-max-width',
      type: KeywordType.number,
      description: 'Photos are scaled down to this width, in pixels.',
      on: ['image-data'],
    ),
    KeywordDescriptor(
      name: 'x-max-height',
      type: KeywordType.number,
      description: 'Photos are scaled down to this height, in pixels.',
      on: ['image-data'],
    ),
    KeywordDescriptor(
      name: 'x-image-quality',
      type: KeywordType.integer,
      description: 'JPEG quality of photos, 0–100.',
      on: ['image-data'],
    ),
    KeywordDescriptor(
      name: 'x-default-country',
      type: KeywordType.string,
      description: 'The country a phone field starts with, `DE`.',
      on: ['phone'],
    ),
    KeywordDescriptor(
      name: 'x-countries',
      type: KeywordType.stringList,
      description: 'The countries a phone field offers.',
      on: ['phone'],
    ),
    KeywordDescriptor(
      name: 'x-svg-asset',
      type: KeywordType.string,
      description: 'The SVG asset of an svg-part-picker.',
      on: ['svg-part-picker'],
    ),
    KeywordDescriptor(
      name: 'x-image',
      type: KeywordType.string,
      description: 'The picture URL of an image-choice option (on a branch).',
    ),
  ];

  /// The JSON Logic operators `x-calc` understands.
  static const List<String> calcOperators = [
    'var', 'missing', 'missing_some', //
    'if', '?:', 'and', 'or', '!', '!!',
    '==', '!=', '===', '!==', '<', '<=', '>', '>=',
    '+', '-', '*', '/', '%', 'min', 'max', 'round',
    'map', 'filter', 'reduce', 'all', 'none', 'some', 'merge', 'in', 'count',
    'cat', 'substr', 'log',
  ];

  /// The editor named [name] (a format, an alias or a layout).
  static EditorDescriptor? byName(String name) {
    for (final d in [...formats, ...layouts]) {
      if (d.name == name || d.aliases.contains(name)) return d;
    }
    return null;
  }

  /// Every `x-format` value, aliases included.
  static List<String> get formatNames => [
    for (final d in formats) ...[d.name, ...d.aliases],
  ]..sort();

  /// The keyword named [name].
  static KeywordDescriptor? keyword(String name) {
    for (final k in keywords) {
      if (k.name == name) return k;
    }
    return null;
  }

  /// The catalog as JSON, embedded in the meta-schema as `x-catalog` so
  /// other languages can lint the same way.
  static Map<String, dynamic> toJson() => {
    'version': version,
    'formats': {
      for (final d in formats)
        for (final name in [d.name, ...d.aliases])
          name: {
            if (d.types != null) 'types': d.types,
            if (d.requires != null) 'requires': d.requires!.name,
            if (d.steps != null) 'steps': d.steps!.toJson(),
            if (d.largeData) 'largeData': true,
          },
    },
    'layouts': [for (final d in layouts) d.name],
    'multiPageLayouts': const ['wizard', 'tabs'],
    'keywords': {
      for (final k in keywords)
        k.name: {
          'value': k.typeName,
          if (k.on != null) 'on': k.on,
          if (k.layouts != null) 'layouts': k.layouts,
          if (k.needs != null) 'needs': k.needs,
        },
    },
    'calcOperators': calcOperators,
  };
}
