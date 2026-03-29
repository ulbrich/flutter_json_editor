import 'package:flutter/material.dart';

import '../ref_lookup_provider.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

/// An image-based picker that displays selectable image thumbnails instead of
/// a text dropdown.
///
/// Supports two modes:
///
/// **Simple enum** — each enum value is an image URL. The selected URL is
/// stored as the field value.
///
/// ```json
/// {
///   "type": "string",
///   "x-format": "image-picker",
///   "enum": [
///     "https://example.com/a.png",
///     "https://example.com/b.png"
///   ]
/// }
/// ```
///
/// **Remote `$ref`** — resolves a remote reference via `onRefLookup`. The
/// response's `enumSource` is parsed: `title` is treated as the image URL
/// displayed to the user, `value` (e.g. an ID) is stored as the field value.
///
/// ```json
/// {
///   "type": "string",
///   "x-format": "image-picker",
///   "$ref": "https://example.com/api/avatars"
/// }
/// ```
class ImagePickerEditor extends SchemaFieldEditor {
  const ImagePickerEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<ImagePickerEditor> createState() => _ImagePickerEditorState();
}

class _ImageItem {
  final String value;
  final String imageUrl;
  const _ImageItem({required this.value, required this.imageUrl});
}

class _ImagePickerEditorState extends State<ImagePickerEditor> {
  List<_ImageItem> _items = [];
  bool _loading = false;
  String? _error;
  bool _remoteInitialized = false;

  @override
  void initState() {
    super.initState();
    _items = _buildStaticItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_remoteInitialized) {
      _remoteInitialized = true;
      final remoteRef = widget.schema.schemaMap?['x-remote-ref'];
      if (remoteRef is String && _items.isEmpty) {
        _loadRemoteData(remoteRef);
      }
    }
  }

  @override
  void didUpdateWidget(ImagePickerEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schema != widget.schema) {
      _items = _buildStaticItems();
    }
  }

  List<_ImageItem> _buildStaticItems() {
    // Plain enum values — each value is an image URL
    final enumValues = widget.schema.enumValues;
    if (enumValues != null) {
      return enumValues
          .where((v) => v != null)
          .map((v) {
            final url = v.toString();
            return _ImageItem(value: url, imageUrl: url);
          })
          .toList();
    }
    return [];
  }

  Future<void> _loadRemoteData(String refUrl) async {
    setState(() => _loading = true);

    final provider = RefLookupProvider.of(context);
    if (provider?.onRefLookup == null) {
      setState(() {
        _loading = false;
        _error = 'No onRefLookup callback provided';
      });
      return;
    }

    try {
      final result = await provider!.lookup(refUrl, widget.path, widget.value);
      if (result == null) {
        setState(() {
          _loading = false;
          _error = 'Remote data unavailable';
        });
        return;
      }
      _parseEnumSource(result);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  void _parseEnumSource(Map<String, dynamic> data) {
    final enumSources = data['enumSource'] as List?;
    if (enumSources == null || enumSources.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No enumSource in response';
      });
      return;
    }

    final items = <_ImageItem>[];
    for (final source in enumSources) {
      if (source is! Map) continue;
      final valueTemplate = source['value'] as String? ?? '{{item.value}}';
      final titleTemplate = source['title'] as String? ?? '{{item.title}}';
      final sourceList = source['source'] as List? ?? [];

      for (final item in sourceList) {
        if (item is Map) {
          final resolvedValue = _resolveTemplate(valueTemplate, item);
          final resolvedTitle = _resolveTemplate(titleTemplate, item);
          items.add(_ImageItem(value: resolvedValue, imageUrl: resolvedTitle));
        }
      }
    }

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _resolveTemplate(String template, Map item) {
    return template.replaceAllMapped(
      RegExp(r'\{\{item\.([^}]+)\}\}'),
      (match) {
        final path = match.group(1)!;
        dynamic current = item;
        for (final segment in path.split('.')) {
          if (current is Map) {
            current = current[segment];
          } else {
            return match.group(0)!;
          }
        }
        return current?.toString() ?? '';
      },
    );
  }

  void _onItemTapped(String itemValue) {
    if (widget.value == itemValue) {
      if (!widget.isRequired || widget.isNullable) {
        widget.onChanged(null);
      }
    } else {
      widget.onChanged(itemValue);
    }
  }

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final colorScheme = Theme.of(context).colorScheme;
    final labelText = _buildLabel();

    if (_loading) {
      return Padding(
        padding: editorTheme.fieldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labelText, style: editorTheme.labelStyle ?? Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: editorTheme.fieldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labelText, style: editorTheme.labelStyle ?? Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(_error!, style: editorTheme.errorStyle ?? TextStyle(color: colorScheme.error, fontSize: 12)),
          ],
        ),
      );
    }

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: editorTheme.labelStyle ??
                Theme.of(context).textTheme.bodyMedium,
          ),
          if (widget.schema.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.schema.description!,
                style: editorTheme.helperStyle ??
                    Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Text(
              'No images available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _items.map((item) {
                final isSelected = widget.value == item.value;
                return GestureDetector(
                  onTap: () => _onItemTapped(item.value),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSelected ? 5 : 7),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          if (widget.isNullable && widget.value != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => widget.onChanged(null),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear selection'),
            ),
          ],
        ],
      ),
    );
  }
}
