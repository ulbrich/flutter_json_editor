import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

import '../editor_registry.dart';
import '../l10n/json_editor_l10n.dart';
import '../schema_resolver.dart';
import '../schema_utils.dart';
import 'const_choice_editor.dart';

/// Builds the picture of an `image-choice` option. Pass one to
/// [ImageChoiceEditor.builderWith] to load pictures your own way (e.g. with a
/// disk cache or auth headers); the default is [Image.network].
typedef ImageChoiceImageBuilder = Widget Function(
    BuildContext context, String url, Widget placeholder);

/// A labeled single choice with pictures, activated by
/// `"x-format": "image-choice"` on a `oneOf`/`anyOf` whose branches are all
/// scalar `const`s. Each branch may name a picture URL in `x-image` and a
/// `description`:
///
/// ```json
/// {
///   "type": "string",
///   "title": "Dish",
///   "x-format": "image-choice",
///   "oneOf": [
///     {"const": "margherita", "title": "Margherita",
///      "description": "Tomato and mozzarella",
///      "x-image": "https://example.com/margherita.jpg"},
///     {"const": "diavola", "title": "Diavola",
///      "x-image": "https://example.com/diavola.jpg"}
///   ]
/// }
/// ```
///
/// The field shows the chosen option with its picture and description; a tap
/// opens a grid of pictures to choose from. The branch's `const` is stored,
/// as with the plain [ConstChoiceEditor] dropdown. Options without a picture
/// (or whose picture fails to load) show a neutral placeholder. A schema that
/// isn't such a `const` list renders with the editor it would get without
/// the `x-format`.
class ImageChoiceEditor extends StatelessWidget {
  final JsonSchema schema;
  final String path;
  final dynamic value;
  final void Function(dynamic) onChanged;
  final bool isRequired;
  final bool isNullable;
  final ImageChoiceImageBuilder? imageBuilder;

  const ImageChoiceEditor({
    super.key,
    required this.schema,
    required this.path,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    this.isNullable = false,
    this.imageBuilder,
  });

  /// A registry builder that loads pictures with [imageBuilder], for
  /// `EditorRegistryData(formatOverrides: {'image-choice': ...})`.
  static Widget Function({
    required JsonSchema schema,
    required String path,
    required dynamic value,
    required void Function(dynamic value) onChanged,
    required bool isRequired,
    bool isNullable,
  }) builderWith(ImageChoiceImageBuilder? imageBuilder) => ({
        required JsonSchema schema,
        required String path,
        required dynamic value,
        required void Function(dynamic value) onChanged,
        required bool isRequired,
        bool isNullable = false,
      }) =>
          ImageChoiceEditor(
            schema: schema,
            path: path,
            value: value,
            onChanged: onChanged,
            isRequired: isRequired,
            isNullable: isNullable,
            imageBuilder: imageBuilder,
          );

  String get _label {
    final base = schema.title ?? path.split('.').last;
    return isRequired ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    final choices = ConstChoiceEditor.tryExtract(schema);
    if (choices == null) {
      // Not a `const` list: render the field as if it had no `x-format`.
      return SchemaResolver.resolve(
        schema: SchemaUtils.createSchema(
          Map<String, dynamic>.from(schema.schemaMap ?? const {})
            ..remove('x-format'),
        ),
        path: path,
        value: value,
        onChanged: onChanged,
        registry: EditorRegistry.of(context),
        isRequired: isRequired,
        isNullable: isNullable,
      );
    }

    // A value from an earlier option set (a conditional parent field
    // changed) is cleared, like the dropdown does.
    if (value != null && !choices.any((c) => c.value == value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
    }
    final selected = choices.where((c) => c.value == value).firstOrNull;
    final readOnly = schema.readOnly == true;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: readOnly ? null : () => _pick(context, choices),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: _label,
            helperText: schema.description,
            suffixIcon: readOnly
                ? null
                : (selected != null && (!isRequired || isNullable))
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: JsonEditorL10n.of(context).clearSelectionLabel,
                        onPressed: () => onChanged(null),
                      )
                    : const Icon(Icons.grid_view),
          ),
          isEmpty: selected == null,
          child: selected == null
              ? Text(
                  readOnly ? '' : JsonEditorL10n.of(context).selectOptionLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox.square(
                        dimension: 72,
                        child: _ChoiceImage(selected.imageUrl, imageBuilder),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.title,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (selected.description != null)
                            Text(
                              selected.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, List<ConstChoice> choices) async {
    final picked = await showModalBottomSheet<ConstChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                schema.title ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: choices.length,
                itemBuilder: (context, index) => _ChoiceTile(
                  choice: choices[index],
                  selected: choices[index].value == value,
                  imageBuilder: imageBuilder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      onChanged(picked.value);
    }
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.imageBuilder,
  });

  final ConstChoice choice;
  final bool selected;
  final ImageChoiceImageBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: choice.description ?? choice.title,
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 3 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(choice),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _ChoiceImage(choice.imageUrl, imageBuilder)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  choice.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An option's picture, or a neutral placeholder when it has none or it
/// can't be loaded.
class _ChoiceImage extends StatelessWidget {
  const _ChoiceImage(this.url, this.imageBuilder);

  final String? url;
  final ImageChoiceImageBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
    );
    final url = this.url;
    if (url == null) {
      return placeholder;
    }
    final builder = imageBuilder;
    if (builder != null) {
      return builder(context, url, placeholder);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
